---
title: "Setting up recurring CloudWatch alarms"
date: 2020-12-08
excerpt: Let's turn your single-fired CloudWatch alarm into a recurring reminder
categories:
  - AWS
---

In this post we will see how to turn a single-fired CloudWatch alarm into a recurring reminder. We will explore two different solutions using native AWS services, with detailed implementation and when you should use one or the other.

> **[You can find the implementation of both strategies using the Serverless Framework here](https://github.com/mkleinio/recurrent-cloud-watch-alarm)**

# Motivation

CloudWatch alarms are extremely useful to alert your team about anomalies in your infrastructure. However, recurrence isn't natively supported by CloudWatch. It means that, once a threshold is crossed and the alarm is fired, you won't get another notification until the alarm is off. Having a recurring alarm can be useful and helps you to keep track of pending actions that aren't urgent, but still worth being checked.

# Requirements of the system

Before we start, let's specify what we want to achieve, defining the constraints for the system.

Our system:
1. Should be triggered whenever a specific CloudWatch alarm goes to the `ALARM` state
2. Should send the event to a target SNS topic provided by us
3. Should resend the original event periodically to the SNS topic until:
    1. The alarm goes off (i.e. transition to `OK` or `INSUFFICIENT DATA` states)
    2. A maximum number of retries is reached
4. Should be fully scalable and low maintenance

# Preparing the stage

The system can be imagined as a state machine performing the following steps:

1. When an event is received, publish it to the target SNS topic
2. Wait for a specific amount of time (i.e. our periodicity)
3. Check the current status of the alarm:
    1. If the alarm is off, stop the execution
    2. If the alarm is still on and the maximum number of retries isn't reached, go back to step 1
    3. If the alarm is still on and the maximum number of retries is reached, stop the execution

![][diagram-foundation]

Foundation established, let's move to our first solution.

# Solution #1: SQS + visibility timeout

In our first solution, the recurring system is implemented using a SQS queue consumed by a lambda function. CloudWatch alarm, whenever fired, will send the event directly to the SQS queue:

![][diagram-sqs]

The recurrence magic is done using [SQS visibility timeout](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html). When the message is processed and the event is sent to SNS, lambda will set the visibility timeout of the message to our defined periodicity. This will guarantee that no other lambda will consume this message before our recurrence period is over. 

To keep the message in the queue, the lambda consumer will throw an exception at the end of the execution, since the default behavior of a lambda consuming a SQS queue is to delete the message after a successful execution.

![][sm-sqs]

The maximum number of retries is controlled by the attribute `ApproximateReceiveCount`, included on all messages dispatched by SQS. Whenever a message is consumed by a lambda but not removed from the queue, this counter is incremented automatically by SQS.

Additionally, some adjustments are necessary for the SQS queue setup:

- **Retention period**: default is 4 days. If you're planning to have your recurring alarms to run longer than that, you need to increase this value, otherwise, messages are dropped from the queue. The maximum supported retention period is 14 days.

Finally, our lambda consumer implementation:

```typescript
const AWS = require('aws-sdk');
const sns = new AWS.SNS({ apiVersion: '2010-03-31' });
const sqs = new AWS.SQS({ apiVersion: '2012-11-15' });
const cloudwatch = new AWS.CloudWatch({ apiVersion: '2010-08-01' });

exports.handler = async function(event) {
    // Lambda setup is provided via environment variables
    const { SNS_TOPIC_ARN, QUEUE_URL, INTERVAL, MAX_RETRIES } = process.env;
    const maxRetries = parseInt(MAX_RETRIES, 10);

    let haveRetries = false;

    for(const record of event.Records) {
        const body = JSON.parse(record.body);
        const alarmName = body.detail.alarmName;

        // Check alarm status
        const status = await getAlarmState(alarmName);
        const approxReceiveCount = record.attributes.ApproximateReceiveCount;
        
        if (status === "ALARM" && approxReceiveCount <= maxRetries) {
            // Send cloudwatch event to the SNS topic
            await sns.publish({
                TopicArn: SNS_TOPIC_ARN,
                Message: record.body,
            }).promise();

            // Hide the message in the queue until the next recurrence
            await sqs.changeMessageVisibility({
                QueueUrl: QUEUE_URL,
                ReceiptHandle: record.receiptHandle,
                VisibilityTimeout: INTERVAL,
            }).promise();

            haveRetries = true;
        } else {
            // Alarm is gone or max retries reached:
            // remove the message from the queue
            await sqs.deleteMessage({
                QueueUrl: QUEUE_URL,
                ReceiptHandle: record.receiptHandle
            }).promise();
        }
    }

    if (haveRetries) {
        // Throwing an error makes the lambda skip the deletion of the messages from the queue.
        throw new Error(`At least one alarm is still scheduled for retry`);
    }
}

async function getAlarmState(alarmName) {
    const { MetricAlarms, CompositeAlarms } = await cloudwatch.describeAlarms({
        AlarmNames: [alarmName],
        AlarmTypes: ['MetricAlarm', 'CompositeAlarm']
    }).promise();
    
    if (MetricAlarms.length) {
        // It's a metric alarm
        return MetricAlarms[0].StateValue;
    } else if (CompositeAlarms.length) {
        // It's a composite alarm
        return CompositeAlarms[0].StateValue;
    } else {
        throw new Error(`No alarm found with name ${alarmName}`);
    }
}
```

----

# Solution #2: Step Functions

Our second solution uses a Step Functions State Machine to orchestrate the entire recurring workflow. EventBridge event (former _CloudWatch event_), in this case, has a target to the state machine, which starts a new execution whenever the alarm is fired.

![][diagram-sf]

Differently from solution #1, in Step Functions the recurrence is set up directly on the state machine, by creating a cyclic graph with their states. The interval is implemented using the native `wait` state from Step Functions. Finally, the retry control isn't natively supported by Step Functions. In this case, we implement this control using lambda. This setup will be explained in the next section. 

![][sm-sf]

Let's dive into the machine:

### Prepare Data

Since EventBridge is the dispatcher of the state machine, the input of the machine is the event itself. However, lambdas need to exchange data among them to orchestrate the entire logic. To avoid tempering the original event with lambda results, the `Prepare Data` state will move the event payload to a dedicated key (`cloudWatchAlarm`). This allows us to store auxiliary data while keeping the original event intact.

### Send event to SNS

Self-explanatory. This step will trigger a lambda responsible to send the event to our target SNS topic.

However, this lambda has an extra responsibility: keep the counter of the retries. 

Step Functions doesn't support counting cyclic graphs execution, so this lambda will initialize and increment the retries counter on each execution. This counter will be stored under the `sendEventResult` key and will be later on used to decide if the machine continues executing or stops due to exhaustion of retries.

```typescript
const AWS = require('aws-sdk');
const sns = new AWS.SNS({ apiVersion: '2010-08-01' });

exports.handler = async function(event) {
  const { cloudWatchAlarm, sendEventResult } = event;
  const { SNS_TOPIC_ARN } = process.env;
  const retries = sendEventResult ? sendEventResult.retries : 0;

  await sns.publish({
    TopicArn: SNS_TOPIC_ARN,
    Message: JSON.stringify(cloudWatchAlarm),
  }).promise();

  return {
    retries: retries + 1
  }
}
```

### Check alarm status

This state will trigger a lambda that will connect to CloudWatch and check the up-to-date status of the alarm. This status is then returned by the lambda and stored in the `checkAlarmResult` key.

```typescript
const AWS = require('aws-sdk');
const cloudwatch = new AWS.CloudWatch({ apiVersion: '2010-08-01' });

exports.handler = async function(event) {
  const { alarmName } = event.cloudWatchAlarm.detail
  const status = await getAlarmState(alarmName)
    
  return {
    alarmName: alarmName,
    alarmStatus: status,
  }
}

async function getAlarmState(alarmName) {
  const { MetricAlarms, CompositeAlarms } = await cloudwatch.describeAlarms({
      AlarmNames: [alarmName],
      AlarmTypes: ['MetricAlarm', 'CompositeAlarm']
  }).promise()
  
  if (MetricAlarms.length) {
      // It's a metric alarm
      return MetricAlarms[0].StateValue;
  } else if (CompositeAlarms.length) {
      // It's a composite alarm
      return CompositeAlarms[0].StateValue;
  } else {
      throw new Error(`No alarm found with name ${alarmName}`);
  }
}
```

### Alarm still on

This is the heart of the recurrence. Based on the current alarm status collected in the previous step, this is a `choice` state that will check if the returned status is still `ALARM`.
If this is not the case, the state machine stops here. Otherwise, the execution proceeds to the `Max retries reached?` state, which checks if the retries counter has reached the maximum retries. If so, the execution stops here as well. Otherwise, we go back to the `Send event to SNS` state, which is our cyclic graph.

----

# What should I use?

Both solutions achieve the same purpose, but with different strategies. So, which one should you choose?

You might be tempted to choose SQS straight ahead since this is a much cheaper solution (check the table below for details). However, considering the nature of the system, high volume isn't expected here (otherwise, you have a bigger fish to fry 😉). So, even if you go with Step Functions, the impact on your bill should be minimum.

A more conscious decision takes into consideration how easy is to set up and maintain the system and how expensive is to expand this to more complex scenarios.

With SQS, setup is very simple and the logic is constrained to a single lambda function. In this case, maintaining this solution turns out to be easier than managing an entire state machine, where the logic is spread among states setup and lambdas logic. However, expanding the SQS solution to more complex cases can be trickier. The single lambda of the SQS solution can become hard to evolve. In contrast, expanding a Step Function is easy and well organized.

So, in resume, SQS can be a good choice if you're happy with the basic recurrence or at least isn't going to evolve the model a lot. Otherwise, Step Functions gives you more freedom to expand and create more complex scenarios.

Below is a comparison table to help you with the decision making:

|                 	| SQS + visibility timeout                                | Step Functions                                                                                          	|
|-----------------	|-------------------------------------------------------	|---------------------------------------------------------------------------------------------------------	|
| Cost (_using `us-east-1` as reference_)  | $0.40 per million request + lambda costs                | $0.025 per thousand state transitions + lambda costs                                                    	|
| Maintainability 	| Logic is constrained to a single lambda                 | Logic is spread across state machine definition and lambdas logic                                      	|
| Extensibility   	| More complex scenarios can lead to convoluted lambda    | More complex scenarios can be easily added with the addition of new states, keeping the logic organized 	|
| Retention       	| Maximum 14 days                                         | Maximum one year                                                                                        	|
| Recurrence       	| Maximum 12 hours                                        | Limited by the remaining time left for the state machine execution                                      	|
| Isolation       	| Queue is shared among all alarms                        | Each step function execution is isolated                                                                	|

# Conclusion

In this post, you've seen two different approaches on how to turn a single-fired CloudWatch alarm into a recurring system. While both solutions are cheap and relatively easy to implement, they lack some important concepts, such as tracking alarms, reports, automatic remediation, etc. For such cases, more robust solutions are advised. AWS System Manager OpsCenter is a great candidate for such cases. 

Although, for a very first layer of notification, the two solutions presented here can be cheap and low-maintenance alternatives.

# Resources

- [Implementation of both solutions using the Serverless Framework](https://github.com/mkleinio/recurrent-cloud-watch-alarm)
- [SQS Visibility Timeout](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html)
- [Step Functions Iterate Pattern](https://docs.aws.amazon.com/step-functions/latest/dg/tutorial-create-iterate-pattern-section.html)
- [Improved management of Amazon CloudWatch Alarms using AWS Systems Manager OpsCenter](https://aws.amazon.com/blogs/mt/improved-management-amazon-cloudwatch-alarms-using-aws-systems-manager-opscenter/)

[diagram-foundation]: https://user-images.githubusercontent.com/11538662/101629226-52a7ea00-3a21-11eb-9842-8735908d344b.png
[diagram-sqs]:        https://user-images.githubusercontent.com/11538662/101629235-550a4400-3a21-11eb-86d1-31fc47a8c1c3.png
[diagram-sf]:         https://user-images.githubusercontent.com/11538662/101629233-53d91700-3a21-11eb-860e-741dd14bb3f9.png
[sm-sqs]:             https://user-images.githubusercontent.com/11538662/101629244-576c9e00-3a21-11eb-937b-e505f0e06fcf.png
[sm-sf]:              https://user-images.githubusercontent.com/11538662/101629240-55a2da80-3a21-11eb-868b-67ee62b2af3d.png
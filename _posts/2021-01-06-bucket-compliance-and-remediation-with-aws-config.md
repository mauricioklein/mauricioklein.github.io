---
title: "Automating S3 bucket compliance check & remediation with AWS Config"
excerpt: Let's continue with our S3 breaches series and automate our buckets remediation with AWS Config
date: 2021-01-06
categories:
  - AWS
  - S3
  - Security
---

In the last post, we explored the most common S3 security breaches and how to remediate them ([if you missed it,
you can read it here][last-post]).

Better than knowing how to protect your data is to automate the entire process, so whenever 
a similar situation arises, you can rest assured that the problem will be automatically fixed.

Today, I'll present how to automate the monitoring and remediation for the four 
recommended bucket configurations mentioned in the last post:

- Bucket versioning
- Block public read/write access
- Bucket logging
- Server-side encryption

By the end of this post, you will know how to automate the compliance check of your S3 buckets and automatically 
remediate them back to safety.

> _**Short on time?**_ 
> _**[Here's the gist with the full CloudFormation implementation of the solution][gist-link]**_

## AWS Config

The first step to automate your S3 bucket configuration is monitoring. We need to have a 
way to continuously monitor the state of our buckets and compare them 
against our defined rules.

AWS provides a service exactly for this purpose: [AWS Config](https://aws.amazon.com/config/).

AWS Config allows us to monitor and audit not only S3 buckets, but many other resource types. Resources
are monitored by a recorder, that checks their states periodically and compares them against our 
defined rules. These rules inform AWS Config about the desired state of the resource and, in case it diverges, 
the resource is reported as `non-compliant`.

AWS Config provides a set of managed rules that can be used to monitor common scenarios. For example, the managed rule 
`s3-bucket-server-side-encryption-enabled` can be used to verify if SSE (_server-side encryption_) is enabled in a S3 
bucket. [Here's the full list of managed rules provided by AWS Config][config-rules].

Whenever a non-complying resource is discovered, AWS Config can execute an action in response to the 
event. Among the supported actions, the one that we will use in today's experiment is the _auto-remediation_.

![][aws-config-diagram]
*AWS Config diagram ([source: AWS](https://d1.awsstatic.com/Products/product-name/diagrams/product-page-diagram-Config_how-it-works.bd28728a9066c55d7ee69c0a655109001462e25b.png))*

## AWS System Manager (SSM)

AWS Config itself doesn't know how to remediate a resource. This task is delegated to [AWS System Manager](https://aws.amazon.com/systems-manager/).
It provides a set of runbooks that can be executed to modify a resource. For example, the runbook `AWS-EnableS3BucketEncryption` can be executed to enable
SSE in an S3 bucket. [A list of all SSM managed runbooks can be found here][ssm-runbooks].

## Hands-on

AWS provides a detailed article on [how to set up everything using the AWS console][aws-remediation-article].

Today, we will focus on the CloudFormation template to automate the entire process. 

### AWS Config Recorder

As mentioned before, AWS Config works by using a recorder to periodically check the state of your AWS resources.

Before we move ahead with the recorder configuration, we need to provision storage for the resource states. AWS Config 
stores these states in an S3 bucket. So, let's create the bucket:

```yaml
#
# S3 bucket used by AWS Config Recorder to record resources state
#
RecorderBucket:
  Type: AWS::S3::Bucket
```

Next, we need an IAM role granting AWS Config permissions to create objects in the recorder bucket above. For this, we
need first a service role for AWS Config and an IAM role granting the necessary permissions and allowing AWS Config to
assume this role:

```yaml
#
# Service role for AWS Config
#
ServiceRole:
  Type: AWS::IAM::ServiceLinkedRole
  Properties:
    AWSServiceName: config.amazonaws.com

#
# IAM role for AWS Config Recorder to interact with the S3 recorder bucket
#
RecorderRole:
  Type: AWS::IAM::Role
  Properties:
    AssumeRolePolicyDocument:
      Version: 2012-10-17
      Statement:
        # Allow AWS Config to assume this role
        - Effect: Allow
          Principal:
            Service:
              - config.amazonaws.com
          Action:
            - sts:AssumeRole
    ManagedPolicyArns:
      - arn:aws:iam::aws:policy/service-role/AWS_ConfigRole
    Policies:
      - PolicyName: S3Policy
        PolicyDocument:
          Version: 2012-10-17
          Statement:
            # Grant permissions to put objects in the bucket
            - Effect: Allow
              Action:
                - s3:PutObject
                - s3:PutObjectAcl
              Resource: !Sub
                - ${BucketArn}/AWSLogs/${AccountId}/Config/*
                - BucketArn: !GetAtt [ RecorderBucket, Arn ]
                  AccountId: !Ref AWS::AccountId
            - Effect: Allow
              Action:
                - s3:GetBucketAcl
              Resource: !GetAtt [ RecorderBucket, Arn ]
```

Next, we need a remediation role. This role will grant SSM permissions to modify the non-compliant buckets and 
bring them back to the expected state:

```yaml
#
# IAM role used by AWS Config auto-remediation to change the configuration on S3 buckets
#
RemediationRole:
  Type: AWS::IAM::Role
  Properties:
    # Assume role policy, granting SSM permissions to assume this role
    AssumeRolePolicyDocument:
      Version: 2012-10-17
      Statement:
        - Effect: Allow
          Principal:
            Service:
              - ssm.amazonaws.com
          Action:
            - sts:AssumeRole
      
    # AWS managed policies, granting permissions for SSM Automation Role operation and full
    # access to our S3 buckets
    ManagedPolicyArns:
      - arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole
      - arn:aws:iam::aws:policy/AmazonS3FullAccess
```

Finally, let's create our AWS Config Recorder. This recorder will be restricted to only S3 buckets: 

```yaml
#
# AWS Config Recorder configuration
#
RecorderConfiguration:
  Type: AWS::Config::ConfigurationRecorder
  Properties:
    Name: S3BucketRecorderConfig
    RecordingGroup:
      AllSupported: false
      IncludeGlobalResourceTypes: false
      ResourceTypes:
        - AWS::S3::Bucket # Limit the recorder scope to only S3 buckets
    RoleARN: !GetAtt [ RecorderRole, Arn ]
```

Recorder set up, let's now move to our rules.

### Rule #1: Bucket versioning

This rule will check for the S3 bucket versioning setup. Buckets with versioning disabled will be considered non-compliant.
This compliance check is done using the AWS Config managed rule 
[s3-bucket-versioning-enabled](https://docs.aws.amazon.com/config/latest/developerguide/s3-bucket-versioning-enabled.html).

```yaml
#
# AWS Config rule for bucket versioning
#
BucketVersioningRule:
  Type: AWS::Config::ConfigRule
  DependsOn: RecorderConfiguration
  Properties:
    ConfigRuleName: BucketVersioningRule
    Description: "Rule to enable versioning on S3 buckets"
    Scope:
      ComplianceResourceTypes:
        - AWS::S3::Bucket
    Source:
      Owner: AWS
      SourceIdentifier: S3_BUCKET_VERSIONING_ENABLED
```

The result is a new rule in AWS Config console, `BucketVersioningRule`:

![][versioning-rule]
*New rule listed on AWS Config Dashboard*

Now, we need to inform AWS Config how to remediate violations of this rule. We will use for this the SSM runbook 
[AWS-ConfigureS3BucketVersioning](https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-aws-configures3bucketversioning.html).

We need to provide some parameters for this runbook:

- `AutomationAssumeRole`: the role assumed by AWS SSM to perform the modifications in the non-compliant resource
- `BucketName`: the name of the non-compliant bucket
- `VersioningState`: the expected versioning state after the runbook is executed

```yaml
#
# AWS Config auto-remediation for bucket versioning
#
BucketVersioningRemediation:
  Type: AWS::Config::RemediationConfiguration
  Properties:
    Automatic: true # Automatically executes this remediation when a non-compliant bucket is found
    MaximumAutomaticAttempts: 5
    RetryAttemptSeconds: 30
    ConfigRuleName: !Ref BucketVersioningRule
    TargetId: AWS-ConfigureS3BucketVersioning # The AWS SSM automation runbook to execute
    TargetType: SSM_DOCUMENT
    Parameters:
      AutomationAssumeRole:
        StaticValue:
          Values:
            - !GetAtt [ RemediationRole, Arn ]
      BucketName:
        ResourceValue:
          Value: RESOURCE_ID # This will fill the "BucketName" attribute with the bucket name provided by the AWS Config rule
      VersioningState:
        StaticValue:
          Values:
            - Enabled
```

Applying our template so far we get the following remediation defined in the AWS Config console:

![][versioning-remediation]
*Versioning remediation listed on AWS Config dashboard*

### Rule #2: Bucket logging

This rule will check whether logging is enabled on a bucket or not. In case it's disabled, this resource is
marked as non-compliant. This check will be performed by the managed rule 
[s3-bucket-logging-enabled](https://docs.aws.amazon.com/config/latest/developerguide/s3-bucket-logging-enabled.html).

```yaml
#
# AWS Config rule for bucket logging
#
BucketLoggingRule:
  Type: AWS::Config::ConfigRule
  DependsOn: RecorderConfiguration
  Properties:
    ConfigRuleName: BucketLoggingRule
    Description: "Rule to enable logging on S3 buckets"
    Scope:
      ComplianceResourceTypes:
        - AWS::S3::Bucket
    Source:
      Owner: AWS
      SourceIdentifier: S3_BUCKET_LOGGING_ENABLED
```

The new rule should be listed in the AWS Config console with the name `BucketLoggingRule`:

![][logging-rule]
*Logging rule on AWS Config Dashboard*

For the remediation, we will be using the managed runbook 
[AWS-ConfigureS3BucketLogging](https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-aws-configures3bucketlogging.html).

For this runbook we provide the following parameters:

- `AutomationAssumeRole`: the role assumed by AWS SSM to perform the modifications in the non-compliant resource
- `BucketName`: the name of the non-compliant bucket
- `GranteeType`: the type of grantee for the logging bucket. In this example, we will be using `Group`
- `GranteeUri`: the URI of the grantee. We will be using the AWS S3 group Log Delivery, which is a managed group 
  recognized by S3 to deliver access logs to a bucket. The group URL is `http://acs.amazonaws.com/groups/s3/LogDelivery`
- `GrantedPermission`: the level of permission granted for the grantee. In our case, we give `FULL_CONTROL`
- `TargetBucket`: the bucket where the logs will be stored

Additionally, we need to create a bucket that will be used to store the access logs for the other buckets. So, our 
Cloudformation snippet for the remediation is:

```yaml
#
# S3 bucket used to log other S3 buckets access
#
LoggingBucket:
  Type: AWS::S3::Bucket
  Properties:
    AccessControl: LogDeliveryWrite # Grant the S3 Log Delivery group write permission on this bucket

#
# AWS Config auto-remediation for bucket logging
#
BucketLoggingRemediation:
  Type: AWS::Config::RemediationConfiguration
  Properties:
    Automatic: true
    MaximumAutomaticAttempts: 5
    RetryAttemptSeconds: 30
    ConfigRuleName: !Ref BucketLoggingRule
    TargetId: AWS-ConfigureS3BucketLogging
    TargetType: SSM_DOCUMENT
    Parameters:
      AutomationAssumeRole:
        StaticValue:
          Values:
            - !GetAtt [ RemediationRole, Arn ]
      BucketName:
        ResourceValue:
          Value: RESOURCE_ID # This will fill the "BucketName" attribute with the bucket name provided by the AWS Config rule
      GrantedPermission:
        StaticValue:
          Values:
            - FULL_CONTROL
      GranteeType:
        StaticValue:
          Values:
            - Group
      GranteeUri:
        StaticValue:
          Values:
            - http://acs.amazonaws.com/groups/s3/LogDelivery
      TargetBucket:
        StaticValue:
          Values:
            - !Ref LoggingBucket
```

Applying this template, we get our second remediation created:

![][logging-remediation]
*Logging remediation created*

### Rule #3: Bucket Public read access

Our third AWS Config rule will be responsible to check for buckets with public read access enabled. 
If so, the bucket is marked as non-compliant.

For this, we will be using the managed rule 
[s3-bucket-public-read-prohibited](https://docs.aws.amazon.com/config/latest/developerguide/s3-bucket-public-read-prohibited.html).

```yaml
#
# AWS Config rule for blocking public read
#
BucketPublicReadProhibitedRule:
  Type: AWS::Config::ConfigRule
  DependsOn: RecorderConfiguration
  Properties:
    ConfigRuleName: BucketPublicReadProhibitedRule
    Scope:
      ComplianceResourceTypes:
        - AWS::S3::Bucket
    Source:
      Owner: AWS
      SourceIdentifier: S3_BUCKET_PUBLIC_READ_PROHIBITED
```

![][public-read-rule]
*Public read rule created*

Since AWS System Manager doesn't provide dedicated remediation for read and write access, we will be using the runbook  
[AWS-DisableS3BucketPublicReadWrite](https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-aws-disables3bucketpublicreadwrite.html),
which disables both read and write for public accessible buckets. This is fine for our use case since we want 
both public read and write access blocked but, in case you want to  have more control over this 
(like restricting only writing access, for example), make sure to check the section about
[custom remediation](#custom-remediation).

The following parameters are provided for the runbook:

- `AutomationAssumeRole`: the role assumed by AWS SSM to perform the modifications in the non-compliant resource
- `BucketName`: the name of the non-compliant bucket

```yaml
#
# AWS Config auto-remediation for bucket public-read access
#
BucketPublicReadRemediation:
  Type: AWS::Config::RemediationConfiguration
  Condition: EnsureNoPublicRW
  Properties:
    Automatic: true
    MaximumAutomaticAttempts: 5
    RetryAttemptSeconds: 30
    ConfigRuleName: !Ref BucketPublicReadProhibitedRule
    TargetId: AWS-DisableS3BucketPublicReadWrite
    TargetType: SSM_DOCUMENT
    Parameters:
      AutomationAssumeRole:
        StaticValue:
          Values:
            - !GetAtt [ RemediationRole, Arn ]
      S3BucketName:
        ResourceValue:
          Value: RESOURCE_ID
```

![][public-read-remediation]
*Public read remediation details*

### Rule #4: Bucket Public write access

This rule works exactly like the previous one. The reason for two separated rules is that AWS Config doesn't provide an
unified managed rule for both read/write permissions.

The only difference to the read rule described before is the managed rule used, which in this case is 
`S3_BUCKET_PUBLIC_WRITE_PROHIBITED` instead of `S3_BUCKET_PUBLIC_READ_PROHIBITED`.

```yaml
#
# AWS Config rule for blocking public write
#
BucketPublicWriteProhibitedRule:
  Type: AWS::Config::ConfigRule
  Condition: EnsureNoPublicRW
  DependsOn: RecorderConfiguration
  Properties:
    ConfigRuleName: BucketPublicWriteProhibitedRule
    Scope:
      ComplianceResourceTypes:
        - AWS::S3::Bucket
    Source:
      Owner: AWS
      SourceIdentifier: S3_BUCKET_PUBLIC_WRITE_PROHIBITED

#
# AWS Config auto-remediation for bucket public-write access
#
BucketPublicWriteRemediation:
  Type: AWS::Config::RemediationConfiguration
  Condition: EnsureNoPublicRW
  Properties:
    Automatic: true
    MaximumAutomaticAttempts: 5
    RetryAttemptSeconds: 30
    ConfigRuleName: !Ref BucketPublicWriteProhibitedRule
    TargetId: AWS-DisableS3BucketPublicReadWrite
    TargetType: SSM_DOCUMENT
    Parameters:
      AutomationAssumeRole:
        StaticValue:
          Values:
            - !GetAtt [ RemediationRole, Arn ]
      S3BucketName:
        ResourceValue:
          Value: RESOURCE_ID
```

![][public-write-rule]
*Public write rule created*

![][public-write-remediation]
*Public write remediation details*

### Rule #5: Bucket SSE

Finally, our 5th and last rule is for bucket SSE (_server-side encryption_) setup. This rule checks if SSE is enabled in the bucket.
If not, it's considered non-compliant. For this, we will be using the managed rule 
[s3-bucket-server-side-encryption-enabled](https://docs.aws.amazon.com/config/latest/developerguide/s3-bucket-server-side-encryption-enabled.html).

```yaml
#
# AWS Config rule for server-side encryption
#
BucketSSERule:
  Type: AWS::Config::ConfigRule
  Condition: EnsureSSE
  DependsOn: RecorderConfiguration
  Properties:
    ConfigRuleName: BucketSSERule
    Scope:
      ComplianceResourceTypes:
        - AWS::S3::Bucket
    Source:
      Owner: AWS
      SourceIdentifier: S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED
```

![][sse-rule]
*SSE (server-side encryption) rule created*

For the automation part, we will be using the runbook 
[AWS-EnableS3BucketEncryption](https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-aws-enableS3bucketencryption.html).

As parameters for this runbook, we will provide:

- `AutomationAssumeRole`: the role assumed by AWS SSM to perform the modifications in the non-compliant resource
- `BucketName`: the name of the non-compliant bucket
- `SSEAlgorithm`: the SSE algorithm to be set on the bucket. In our case, we will use _AES256_, which leverages an S3 
managed key
  
```yaml
#
# AWS Config auto-remediation for bucket server-side encryption
#
BucketSSERemediation:
  Type: AWS::Config::RemediationConfiguration
  Condition: EnsureSSE
  Properties:
    Automatic: true
    MaximumAutomaticAttempts: 5
    RetryAttemptSeconds: 30
    ConfigRuleName: !Ref BucketSSERule
    TargetId: AWS-EnableS3BucketEncryption
    TargetType: SSM_DOCUMENT
    Parameters:
      AutomationAssumeRole:
        StaticValue:
          Values:
            - !GetAtt [ RemediationRole, Arn ]
      BucketName:
        ResourceValue:
          Value: RESOURCE_ID
      SSEAlgorithm:
        StaticValue:
          Values:
            - AES256
```

![][sse-remediation]
*SSE (server-side encryption) remediation details*

## Final template

Collecting all the snippets presented above we have the full Cloudformation implementation of the solution.

For the sake of convenience, [here's a gist with the full implementation][gist-link]. This Gist also includes toggles for
all the rules, so you can enable/disable only those you're interested in.

## Validation

Now that we have our AWS Config setup done with automatic remediation, it's time to see everything in practice.

For this, let's create an S3 bucket violating all the rules covered by our AWS Config setup:

```shell
#
# Creates a bucket with:
#  - Versioning disabled (default)
#  - Logging disabled    (default)
#  - SSE disabled        (default)
#  - Public Read/Write access
#
$ aws s3api create-bucket \
    --bucket super-secret-data \
    --acl public-read-write \
    --create-bucket-configuration LocationConstraint="[YOUR AWS REGION HERE]"
```

![][validation-before]
*Overly permissive bucket*

Pretty bad, huh?!

Now, let's see AWS Config taking care of fixing this mess.

In some minutes, AWS Config recorder will discover our new bucket and run the checks. Since at least one of our 
rules are non-compliant, the bucket is reported as non-compliant as well.

By checking the bucket details, we can see what rules are non-compliant for the resource (in our case, all of them):

![][validation-during-non-compliant]
*Non-compliant bucket discovered*

Since our rules are backed by automated remediation, AWS SSM will start dispatching the runbooks to remediate the bucket.

In the next recorder execution, this bucket will be checked again against our rules. This time, since SSM fixed the
violations automatically, the recorder will realize that the violations were remediated, and the bucket is reported as
compliant.

![][validation-during-compliant]
*Rules are now reported as compliant*

Going back to the S3 console and checking our bucket details we can now see that all violations were fixed, and our bucket is 
now secure.

![][validation-after]

## Custom remediation

Sometimes the managed SSM runbooks aren't enough for us, either because they have limitations or because our use case is very specific.

In such situations, you can create your own remediation logic using AWS Lambda. The idea is, instead of registering a 
managed SSM runbook on the rule auto-remediation, we will invoke a lambda that performs this remediation using the AWS SDK. 
In this case, we have full control over the lambda logic and can implement remediations tailored for our specific case.

### Approach #1: using an SNS topic

AWS Config supports sending notifications to anSNS topic with configuration changes identified by the recorder 
([here's a list of notifications AWS Config sends to an SNS topic](https://docs.aws.amazon.com/config/latest/developerguide/notifications-for-AWS-Config.html)).
Among these changes, there are [compliance change notifications](https://docs.aws.amazon.com/config/latest/developerguide/example-config-rule-compliance-notification.html), which
is sent when a resource transitions between compliant or non-compliant states.

With a proper setup, we can invoke our remediation lambda whenever a compliance change lands the SNS topic.

To receive configuration changes in an SNS topic, we need to create a [AWS Config Delivery Channel](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-config-deliverychannel.html).

```yaml
Topic:
  Type: AWS::SNS::Topic

DeliveryChannel: 
  Type: AWS::Config::DeliveryChannel
  Properties: 
    SnsTopicARN: !Ref Topic
```

> You can have only one delivery channel per region

The snippet above will create a delivery channel for the existing Config recorder in the region. Now, we just need to connect our 
lambda to the SNS topic and execute the logic when a non-compliant resource is identified.

### Approach #2: using EventBridge rule

The second approach is similar to the first one, except that, instead of using an SNS topic, we will be using a 
EventBridge Event Rule as the lambda trigger.

Using EventBridge, we can create a rule to invoke our lambda whenever a resource transitions to a `non-compliant` state. 

```json
{
  "source":[
    "aws.config"
  ],
  "detail":{
    "requestParameters":{
      "evaluations":{
        "complianceType":[
          "NON_COMPLIANT"
        ]
      }
    },
    "additionalEventData":{
      "managedRuleIdentifier":[
        "S3_BUCKET_LOGGING_ENABLED"
      ]
    }
  }
}
```
The rule above will be triggered on non-compliant `S3_BUCKET_LOGGING_ENABLED` rules. With the rule created, we just 
need to define our lambda function as a target.

![][event-bridge-rule]
*EventBridge setup with a lambda function as trigger*

## Conclusion

In this article, you learned how to identify and fix insecure S3 buckets in an automated way. Having this automation is 
essential since you no longer need to keep track of newly created buckets and check for their compliance manually. AWS 
Config will do the heavy-lifting and guarantee that, even if a permissive bucket lands your account, measures to fix this
will be applied automatically whenever necessary.
 
## Resources

- [List of AWS Config Managed Rules](https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html)
- [List of AWS System Manager Automation Runbooks](https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-documents-reference-details.html)
- [List of notifications AWS Config sends to an SNS topic](https://docs.aws.amazon.com/config/latest/developerguide/notifications-for-AWS-Config.html)

<!--
  Links
-->
[last-post]: {{site.url}}/2020/12/17/protect-against-s3-breaches/
[aws-remediation-article]: https://docs.aws.amazon.com/config/latest/developerguide/remediation.html
[config-rules]: https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html
[ssm-runbooks]: https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-documents-reference-details.html
[gist-link]: https://gist.github.com/mauricioklein/62b923208aac0852790625fb7fd5aaef

<!--
  Images
-->
[aws-config-diagram]: https://user-images.githubusercontent.com/11538662/103583114-73a81180-4edf-11eb-86be-34fda0314c34.png

[versioning-rule]: https://user-images.githubusercontent.com/11538662/103583196-9e926580-4edf-11eb-8089-38c622098ad4.png
[versioning-remediation]: https://user-images.githubusercontent.com/11538662/103583231-aa7e2780-4edf-11eb-8c85-89f9e779c9bf.png

[logging-rule]: https://user-images.githubusercontent.com/11538662/103583265-b79b1680-4edf-11eb-95c6-395a2e757375.png
[logging-remediation]: https://user-images.githubusercontent.com/11538662/103583286-c2ee4200-4edf-11eb-9235-7e06bdae0e6e.png

[public-read-rule]: https://user-images.githubusercontent.com/11538662/103583328-d7cad580-4edf-11eb-8154-b2d9c8c2e24e.png
[public-read-remediation]: https://user-images.githubusercontent.com/11538662/103583376-e618f180-4edf-11eb-9663-40b2be14aeaa.png

[public-write-rule]: https://user-images.githubusercontent.com/11538662/103583420-f335e080-4edf-11eb-9499-1c347d5fa611.png
[public-write-remediation]: https://user-images.githubusercontent.com/11538662/103583452-ff21a280-4edf-11eb-8a4d-d9d4ddb2bcfb.png

[sse-rule]: https://user-images.githubusercontent.com/11538662/103583483-0ba5fb00-4ee0-11eb-9c74-f676db18e407.png
[sse-remediation]: https://user-images.githubusercontent.com/11538662/103583503-16609000-4ee0-11eb-9aa2-65c8e9780ed1.png

[validation-before]: https://user-images.githubusercontent.com/11538662/103583547-3001d780-4ee0-11eb-9774-9c273f679895.png

[validation-during-non-compliant]: https://user-images.githubusercontent.com/11538662/103583581-3d1ec680-4ee0-11eb-88e1-f6370d09c811.png
[validation-during-compliant]: https://user-images.githubusercontent.com/11538662/103583605-49a31f00-4ee0-11eb-94ee-8f388a422897.png

[validation-after]: https://user-images.githubusercontent.com/11538662/103583631-54f64a80-4ee0-11eb-9d03-5b51e1939d23.png

[event-bridge-rule]: https://user-images.githubusercontent.com/11538662/103583151-8589b480-4edf-11eb-8c59-98f0d9093af5.png
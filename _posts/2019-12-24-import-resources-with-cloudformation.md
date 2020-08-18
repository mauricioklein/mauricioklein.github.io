---
title: "Importing IAM roles & policies with CloudFormation"
date: 2019-12-24
excerpt: So, CloudFormation now supports resource import. Let's try it out
categories:
  - AWS
redirect_from:
  - /aws/2019/12/24/import-resources-with-cloudformation/
---

If you've been following my blog in the last months, you might remember my last post (you can read it [here][tf-import-post]), where I present an alternative of how to import manually created AWS resources using Terraform. One of the points I mentioned for using Terraform was because ~~I was willing to play with TF import~~ CloudFormation doesn't provide such feature: either you create your resources with CloudFormation since the beginning or you have to deal managing them manually (or recreate afterward using CF).

Turns out that on November 13rd, 2019, AWS announced the support to [Resource Import](https://aws.amazon.com/about-aws/whats-new/2019/11/aws-cloudformation-launches-resource-import/), which makes my previous statement outdated.

So, let's see how _CloudFormation Resouce Import_ works and how we can import our manually created role & policies using it.

## The setup

Before we start, we need to have a manually created role with policies. Similar to the previous post, we're gonna create a role (`foobar`) with three policies:

- `AmazonS3ReadOnlyAccess`, an AWS managed policy giving read-only access to S3 buckets
- `foobar-user-managed-policy`, a user managed policy giving full tag permissions for S3 buckets
- `foobar-inline-policy`, an inline policy attached to the role giving list access for S3 buckets

So, heading to AWS CLI:

```bash
# Define the assume role policy document
$ cat > assume-role-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      }
    }
  ]
}
EOF

# Create the IAM role
$ aws iam create-role --role-name foobar --assume-role-policy-document file://assume-role-policy.json

# Attach the "AmazonS3ReadOnlyAccess" policy to the role
$ aws iam attach-role-policy --role-name foobar --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Define the user managed role document
$ cat > user-managed-policy-document.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:DeleteObjectTagging",
        "s3:PutBucketTagging",
        "s3:ReplicateTags",
        "s3:PutObjectVersionTagging",
        "s3:PutObjectTagging",
        "s3:DeleteObjectVersionTagging"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Create the "foobar-user-managed-policy" policy and attach to the role
$ aws iam create-policy --policy-name foobar-user-managed-policy --policy-document file://user-managed-policy-document.json

# Attach the user managed policy to the role
$ aws iam attach-role-policy --role-name foobar --policy-arn "[ARN of the policy created in the previous step]"

# Define the inline policy document
$ cat > foobar-inline-policy-document.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets",
        "s3:ListBucket",
        "s3:HeadBucket"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Create the "foobar-inline-policy" policy and attach to the role
$ aws iam put-role-policy --role-name foobar --policy-name foobar-inline-policy --policy-document file://foobar-inline-policy-document.json
```

By now, you should have a role setup similar to the following:

![][role-manual-setup]

Role & policies created, let's move to the resource import.

## How CloudFormation Resource Import works

Resource import works by adding existing resources in a CloudFormation stack. This stack can be created in advance or during the import time. Why is the stack necessary? Because the resources are imported via changeset on the stack. The distinction between a regular changeset and an import one is defined by the changeset type, provided in the creation of the changeset: in the case of an import, the type is set to `IMPORT`. Additionally, when an import changeset is created, you need to provide the parameter `--resources-to-import`, which informs CloudFormation what physical resources are being imported and to which logical resources in the stack they will be attached.

## Importing the role

Let's start importing the role with no policies.

First, let's define our initial CloudFormation stack:

```yaml
# role.yaml
Resources:
  Role:
    Type: AWS::IAM::Role
    DeletionPolicy: Retain # This is mandatory for import operations
    Properties:
      RoleName: "foobar"
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action: "sts:AssumeRole"
            Principal:
              AWS: "*"
```

Now let's create the stack, informing CloudFormation that the `Role` resource above will be used to import our existing role:

```bash
$ aws cloudformation create-change-set \
    --stack-name foobar \
    --template-body file://role.yaml \
    --change-set-name ImportRoleChangeSet \
    --change-set-type IMPORT \
    --resources-to-import '[{"ResourceType": "AWS::IAM::Role", "LogicalResourceId": "Role", "ResourceIdentifier": {"RoleName": "foobar"}}]' \
    --capabilities CAPABILITY_NAMED_IAM
```

OK, a lot of stuff happening here, so let's go by steps:

- The first four lines are self-explanatory: a CloudFormation changeset is created and, since the stack still doesn't exist, we provide the initial template (`role.yaml`)
- Fifth and sixth lines are related to the import action: the `change-set-type` is set to `IMPORT` and the `resources-to-import` defines the resource to be imported (the `foobar` role), mapping to the logical resource `Role` in our stack template above. The format for this field follows a JSON specification defined by CloudFormation and is described [here](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/create-change-set.html).
- The last line adds the `CAPABILITY_NAMED_IAM` capability to the stack. It's required because the stack is changing IAM resources

You should now have a new CloudFormation stack (`foobar`) and a changeset (`ImportRoleChangeSet`). The stack remains in the `REVIEW_IN_PROGRESS` state since we need to decide to move forward with the changeset or not.

![][role-changeset]

Before proceeding, let's check the changeset and see what CloudFormation identifies as change:

```bash
$ aws cloudformation describe-change-set --stack-name foobar --change-set-name ImportRoleChangeSet
```

```json
{
  "Changes": [
    {
      "Type": "Resource",
      "ResourceChange": {
        "Action": "Import",
        "LogicalResourceId": "Role",
        "PhysicalResourceId": "foobar",
        "ResourceType": "AWS::IAM::Role",
        "Scope": [],
        "Details": []
      }
    }
  ],
  "ChangeSetName": "ImportRoleChangeSet",
  "ChangeSetId": "[OMITTED]",
  "StackId": "[OMITTED]",
  "StackName": "foobar",
  "Description": null,
  "Parameters": null,
  "CreationTime": "2019-12-22T22:30:02.743Z",
  "ExecutionStatus": "AVAILABLE",
  "Status": "CREATE_COMPLETE",
  "StatusReason": null,
  "NotificationARNs": [],
  "RollbackConfiguration": {},
    "Capabilities": [
        "CAPABILITY_NAMED_IAM"
    ],
  "Tags": null
}
```

As described in the `Changes` section, CloudFormation is importing the physical resource (our `foobar` role) in the stack's logical resource (`Role`). This is what we want, so let's execute the changeset:

```bash
$ aws cloudformation execute-change-set --stack-name foobar --change-set-name ImportRoleChangeSet
```

The stack now changes to the `IMPORT_IN_PROGRESS` state and, as soon the import is done, it goes to the `IMPORT_COMPLETE` state. At this point, your stack should contain a single resource, which is the role we just imported:

![][role-imported]

Finally, let's check if there is any drift between our role definition and the imported role:

```bash
# Create the drift check
$ aws cloudformation detect-stack-drift --stack-name foobar

# Display the drift check result
$ aws cloudformation describe-stack-drift-detection-status --stack-drift-detection-id "[StackDriftDetectionId returned by the previous command]"
```

```json
{
  "StackId": "[OMITTED]",
  "StackDriftDetectionId": "[OMITTED]",
  "StackDriftStatus": "IN_SYNC",
  "DetectionStatus": "DETECTION_COMPLETE",
  "DriftedStackResourceCount": 0,
  "Timestamp": "2019-12-22T22:43:55.390Z"
}
```

Great! We now have the role imported and no drifts, but also no policies.
So, let's move ahead and import our next resource: the inline policy.

## Importing the Inline Policy

For the inline policy, we follow the same procedure performed in the role:

1. Update the stack definition
2. Create the changeset
3. Execute the changeset

The difference is that, for CloudFormation, the inline policy is part of the `IAM::Role`, resource, so no real import operation is performed. Instead, we're doing a regular changeset. Also, at the time I'm writing this post, inline policies aren't detected by CloudFormation drifts (you can check the official relation of drift supported resources [here](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-drift-resource-list.html)).

So, let's update our stack definition to include the inline policy:

```yaml
# role.yaml
Resources:
  Role:
    Type: AWS::IAM::Role
    DeletionPolicy: Retain
    Properties:
      RoleName: "foobar"
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action: "sts:AssumeRole"
            Principal:
              AWS: "*"
      Policies:
        # Inline policy
        - PolicyName: "foobar-inline-policy"
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Effect: Allow
                Action:
                  - "s3:ListAllMyBuckets"
                  - "s3:ListBucket"
                  - "s3:HeadBucket"
                Resource: "*"
```

Now, let's create the changeset and check what will change on our stack:

```bash
# Create the changeset
$ aws cloudformation create-change-set \
    --stack-name foobar \
    --template-body file://role.yaml \
    --change-set-name ImportInlinePolicyChangeset \
    --capabilities CAPABILITY_NAMED_IAM

# Check the detected changes
$ aws cloudformation describe-change-set --stack-name foobar --change-set-name ImportInlinePolicyChangeset
```

```json
{
  "Changes": [
    {
      "Type": "Resource",
      "ResourceChange": {
        "Action": "Modify",
        "LogicalResourceId": "Role",
        "PhysicalResourceId": "foobar",
        "ResourceType": "AWS::IAM::Role",
        "Replacement": "False",
                "Scope": [
                    "Properties"
                ],
        "Details": [
          {
            "Target": {
              "Attribute": "Properties",
              "Name": "Policies",
              "RequiresRecreation": "Never"
            },
            "Evaluation": "Static",
            "ChangeSource": "DirectModification"
          }
        ]
      }
    }
  ],
  "ChangeSetName": "ImportInlinePolicyChangeset",
  "ChangeSetId": "[OMITTED]",
  "StackId": "[OMITTED]",
  "StackName": "foobar",
  "Description": null,
  "Parameters": null,
  "CreationTime": "2019-12-22T23:03:19.154Z",
  "ExecutionStatus": "AVAILABLE",
  "Status": "CREATE_COMPLETE",
  "StatusReason": null,
  "NotificationARNs": [],
  "RollbackConfiguration": {},
    "Capabilities": [
        "CAPABILITY_NAMED_IAM"
    ],
  "Tags": null
}
```

As expected, CloudFormation detected a change in our existing role, and the change is in the `Policies` attribute (exactly where we added the inline policy).

All looks good, let's execute the changeset:

```bash
$ aws cloudformation execute-change-set --stack-name foobar --change-set-name ImportInlinePolicyChangeset
```

This time, the stack transitions to the state `UPDATE_IN_PROGRESS` and, then, `UPDATE_COMPLETED`. You won't see the inline policy in the resources list because CloudFormation treats inline policies as part of the role.

All good! Now we have our `foobar` role and its inline policy imported. Let's move to the user managed policy.

## Importing the User Managed Policy

Since user managed roles have a dedicated logical resource on CloudFormation (i.e. they aren't part of the `IAM::Role` resource) we can perform an import operation.

However, this operation needs to be performed in two steps:
1. Import the user managed policy
2. Attach the imported policy to the role

The reason for this separation is because CloudFormation doesn't support stack changes during import operations. So, while we're importing the policy, we can't change the role definition on the same step.

Let's start our policy import operation, by updating our stack definition:

```yaml
# role.yaml
Resources:
  Role:
    Type: AWS::IAM::Role
    DeletionPolicy: Retain
    Properties:
      RoleName: "foobar"
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action: "sts:AssumeRole"
            Principal:
              AWS: "*"
      Policies:
        - PolicyName: "foobar-inline-policy"
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Effect: Allow
                Action:
                  - "s3:ListAllMyBuckets"
                  - "s3:ListBucket"
                  - "s3:HeadBucket"
                Resource: "*"
  # The user managed policy definition
  UserManagedPolicy:
    Type: AWS::IAM::ManagedPolicy
    DeletionPolicy: Retain
    Properties:
      ManagedPolicyName: "foobar-user-managed-policy"
      PolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action:
              - "s3:PutBucketTagging"
              - "s3:ReplicateTags"
              - "s3:PutObjectVersionTagging"
              - "s3:PutObjectTagging"
              - "s3:DeleteObjectVersionTagging"
            Resource: "*"
```

And the respective changeset:

```bash
$ aws cloudformation create-change-set \
    --stack-name foobar \
    --change-set-name ImportUserManagedPolicyChangeSet \
    --change-set-type IMPORT \
    --resources-to-import '[{"ResourceType": "AWS::IAM::ManagedPolicy", "LogicalResourceId": "UserManagedPolicy", "ResourceIdentifier": {"PolicyArn": "[USER MANAGED POLICY ARN]"}}]' \
    --template-body file://role.yaml \
    --capabilities CAPABILITY_NAMED_IAM
```

> Important: make sure to fill the policy ARN field in the command above with the ARN of the user managed policy. You can find the policy, along with the ARN, running `aws iam list-policies --scope Local`

Now let's check what will change when we apply our changeset:

```bash
$ aws cloudformation describe-change-set --stack-name foobar --change-set-name ImportUserManagedPolicyChangeSet
```

```json
{
  "Changes": [
    {
      "Type": "Resource",
      "ResourceChange": {
        "Action": "Import",
        "LogicalResourceId": "UserManagedPolicy",
        "PhysicalResourceId": "[OMITTED]",
        "ResourceType": "AWS::IAM::ManagedPolicy",
        "Scope": [],
        "Details": []
      }
    }
  ],
  "ChangeSetName": "ImportUserManagedPolicyChangeSet",
  "ChangeSetId": "[OMITTED]",
  "StackId": "[OMITTED]",
  "StackName": "foobar",
  "Description": null,
  "Parameters": null,
  "CreationTime": "2019-12-23T09:20:42.378Z",
  "ExecutionStatus": "AVAILABLE",
  "Status": "CREATE_COMPLETE",
  "StatusReason": null,
  "NotificationARNs": [],
  "RollbackConfiguration": {},
    "Capabilities": [
        "CAPABILITY_NAMED_IAM"
    ],
  "Tags": null
}
```

As expected, a new resource will be imported on the stack. So, let's proceed with the changeset execution:

```bash
$ aws cloudformation execute-change-set --stack-name foobar --change-set-name ImportUserManagedPolicyChangeSet
```

Wait for CloudFormation to fully perform the import and you now might have two resources in the stack: the role and the user managed policy

![][user-managed-policy-imported]

Finally, let's check for drifts between our stack description and the imported resource:

```bash
$ aws cloudformation detect-stack-drift --stack-name foobar
$ aws cloudformation describe-stack-resource-drifts --stack-name foobar
```

```json
{
  "StackId": "[OMITTED]",
  "LogicalResourceId": "UserManagedPolicy",
  "PhysicalResourceId": "[OMITTED]",
  "ResourceType": "AWS::IAM::ManagedPolicy",
  "ExpectedProperties": "{\"ManagedPolicyName\":\"foobar-user-managed-policy\",\"PolicyDocument\":{\"Statement\":[{\"Action\":[\"s3:PutBucketTagging\",\"s3:DeleteObjectVersionTagging\",\"s3:PutObjectTagging\",\"s3:ReplicateTags\",\"s3:PutObjectVersionTagging\"],\"Effect\":\"Allow\",\"Resource\":\"*\"}],\"Version\":\"2012-10-17\"}}",
  "ActualProperties": "{\"ManagedPolicyName\":\"foobar-user-managed-policy\",\"PolicyDocument\":{\"Statement\":[{\"Action\":[\"s3:PutBucketTagging\",\"s3:DeleteObjectVersionTagging\",\"s3:PutObjectTagging\",\"s3:ReplicateTags\",\"s3:PutObjectVersionTagging\",\"s3:DeleteObjectTagging\"],\"Effect\":\"Allow\",\"Resource\":\"*\"}],\"Version\":\"2012-10-17\"}}",
  "PropertyDifferences": [
    {
      "PropertyPath": "/PolicyDocument/Statement/0/Action/5",
      "ExpectedValue": "null",
      "ActualValue": "s3:DeleteObjectTagging",
      "DifferenceType": "ADD"
    }
  ],
  "StackResourceDriftStatus": "MODIFIED",
  "Timestamp": "2019-12-23T16:13:12.280Z"
}
```

Ops! Looks like we have a drift on our stack. By the `PropertyDifferences` field, we can see that we forgot one action on our user managed role description: `s3:DeleteObjectTagging`.

So, let's fix this, by adjusting our stack description and running a new changeset

```yaml
# role.yaml
Resources:
  Role:
    Type: AWS::IAM::Role
    DeletionPolicy: Retain
    Properties:
      RoleName: "foobar"
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action: "sts:AssumeRole"
            Principal:
              AWS: "*"
      Policies:
        - PolicyName: "foobar-inline-policy"
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Effect: Allow
                Action:
                  - "s3:ListAllMyBuckets"
                  - "s3:ListBucket"
                  - "s3:HeadBucket"
                Resource: "*"
  UserManagedPolicy:
    Type: AWS::IAM::ManagedPolicy
    DeletionPolicy: Retain
    Properties:
      ManagedPolicyName: "foobar-user-managed-policy"
      PolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action:
              - "s3:DeleteObjectTagging" # <--- the missing action
              - "s3:PutBucketTagging"
              - "s3:ReplicateTags"
              - "s3:PutObjectVersionTagging"
              - "s3:PutObjectTagging"
              - "s3:DeleteObjectVersionTagging"
            Resource: "*"
```

```bash
# Create the changeset
$ aws cloudformation create-change-set \
    --stack-name foobar \
    --template-body file://role.yaml \
    --change-set-name ImportManagedPolicyChangeset \
    --capabilities CAPABILITY_NAMED_IAM

# Execute the changeset
$ aws cloudformation execute-change-set --stack-name foobar --change-set-name ImportManagedPolicyChangeset

# Wait for the update to finish...

# Check for drifts
$ aws cloudformation detect-stack-drift --stack-name foobar
$ aws cloudformation describe-stack-resource-drifts --stack-name foobar
```

```json
{
  "StackId": "[OMITTED]",
  "LogicalResourceId": "UserManagedPolicy",
  "PhysicalResourceId": "[OMITTED]",
  "ResourceType": "AWS::IAM::ManagedPolicy",
  "ExpectedProperties": "{\"ManagedPolicyName\":\"foobar-user-managed-policy\",\"PolicyDocument\":{\"Statement\":[{\"Action\":[\"s3:PutBucketTagging\",\"s3:DeleteObjectVersionTagging\",\"s3:PutObjectTagging\",\"s3:ReplicateTags\",\"s3:PutObjectVersionTagging\",\"s3:DeleteObjectTagging\"],\"Effect\":\"Allow\",\"Resource\":\"*\"}],\"Version\":\"2012-10-17\"}}",
  "ActualProperties": "{\"ManagedPolicyName\":\"foobar-user-managed-policy\",\"PolicyDocument\":{\"Statement\":[{\"Action\":[\"s3:PutBucketTagging\",\"s3:DeleteObjectVersionTagging\",\"s3:PutObjectTagging\",\"s3:ReplicateTags\",\"s3:PutObjectVersionTagging\",\"s3:DeleteObjectTagging\"],\"Effect\":\"Allow\",\"Resource\":\"*\"}],\"Version\":\"2012-10-17\"}}",
  "PropertyDifferences": [],
  "StackResourceDriftStatus": "IN_SYNC",
  "Timestamp": "2019-12-23T16:20:17.461Z"
}
```

Drift solved! Now, let's attach the policy to the role.
This can be done by a simple stack update and respective changeset:

```yaml
# role.yaml
Resources:
  Role:
    Type: AWS::IAM::Role
    DeletionPolicy: Retain
    Properties:
      RoleName: "foobar"
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action: "sts:AssumeRole"
            Principal:
              AWS: "*"
      ManagedPolicyArns:
        - !Ref UserManagedPolicy # <--- attach the user managed policy to the role
      Policies:
        - PolicyName: "foobar-inline-policy"
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Effect: Allow
                Action:
                  - "s3:ListAllMyBuckets"
                  - "s3:ListBucket"
                  - "s3:HeadBucket"
                Resource: "*"
  UserManagedPolicy:
    Type: AWS::IAM::ManagedPolicy
    DeletionPolicy: Retain
    Properties:
      ManagedPolicyName: "foobar-user-managed-policy"
      PolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action:
              - "s3:DeleteObjectTagging"
              - "s3:PutBucketTagging"
              - "s3:ReplicateTags"
              - "s3:PutObjectVersionTagging"
              - "s3:PutObjectTagging"
              - "s3:DeleteObjectVersionTagging"
            Resource: "*"
```

```bash
# Create the changeset
$ aws cloudformation create-change-set \
    --stack-name foobar \
    --template-body file://role.yaml \
    --change-set-name RolePolicyAssociationChangeset \
    --capabilities CAPABILITY_NAMED_IAM

# Execute the changeset
$ aws cloudformation execute-change-set --stack-name foobar --change-set-name RolePolicyAssociationChangeset

# Wait for the update to finish...

# Check for drifts
$ aws cloudformation detect-stack-drift --stack-name foobar
$ aws cloudformation describe-stack-resource-drifts --stack-name foobar
```

Done! We now have our role, inline policy and user managed policy imported in our stack.

However, if you check the `IAM::Role` drift detection output, you'll see a drift:

```json
{
  "StackId": "[OMITTED]",
  "LogicalResourceId": "Role",
  "PhysicalResourceId": "foobar",
  "ResourceType": "AWS::IAM::Role",
  "PropertyDifferences": [
    {
      "PropertyPath": "/ManagedPolicyArns/1",
      "ExpectedValue": "null",
      "ActualValue": "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
      "DifferenceType": "ADD"
    }
  ],
  "StackResourceDriftStatus": "MODIFIED",
  "Timestamp": "2019-12-23T17:20:18.721Z"
}
```

This is because we're missing our last resource: the AWS managed policy.

## Importing the AWS Managed Policy

AWS managed policies, the same way as inline policies, don't hold a specific logical resource in CloudFormation, being just attached to an existing role.

In this case, the import process becomes adjusting the stack definition and running a changeset.

```yaml
# role.yaml
Resources:
  Role:
    Type: AWS::IAM::Role
    DeletionPolicy: Retain
    Properties:
      RoleName: "foobar"
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action: "sts:AssumeRole"
            Principal:
              AWS: "*"
      ManagedPolicyArns:
        - !Ref UserManagedPolicy
        - arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess # <--- the AWS managed policy
      Policies:
        - PolicyName: "foobar-inline-policy"
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Effect: Allow
                Action:
                  - "s3:ListAllMyBuckets"
                  - "s3:ListBucket"
                  - "s3:HeadBucket"
                Resource: "*"
  UserManagedPolicy:
    Type: AWS::IAM::ManagedPolicy
    DeletionPolicy: Retain
    Properties:
      ManagedPolicyName: "foobar-user-managed-policy"
      PolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action:
              - "s3:DeleteObjectTagging"
              - "s3:PutBucketTagging"
              - "s3:ReplicateTags"
              - "s3:PutObjectVersionTagging"
              - "s3:PutObjectTagging"
              - "s3:DeleteObjectVersionTagging"
            Resource: "*"
```

```bash
# Create the changeset
$ aws cloudformation create-change-set \
    --stack-name foobar \
    --template-body file://role.yaml \
    --change-set-name ImportAWSManagedPolicyChangeset \
    --capabilities CAPABILITY_NAMED_IAM

# Check the detected changes
$ aws cloudformation describe-change-set --stack-name foobar --change-set-name ImportAWSManagedPolicyChangeset
```

```json
{
  "changes": [
    {
      "Type": "Resource",
      "ResourceChange": {
        "Action": "Modify",
        "LogicalResourceId": "Role",
        "PhysicalResourceId": "foobar",
        "ResourceType": "AWS::IAM::Role",
        "Replacement": "False",
        "Scope": [
            "Properties"
        ],
        "Details": [
            {
                "Target": {
                    "Attribute": "Properties",
                    "Name": "ManagedPolicyArns",
                    "RequiresRecreation": "Never"
                },
                "Evaluation": "Static",
                "ChangeSource": "DirectModification"
            }
        ]
      }
    }
  ],
```

The changeset correctly recognized a change on the role's `ManagedPolicyArns` field, so let's proceed with the execution:

```bash
$ aws cloudformation execute-change-set --stack-name foobar --change-set-name ImportAWSManagedPolicyChangeset
```

Finally, let's check for drifts again and make sure that we no longer have a drift in the role's definition

```bash
$ aws cloudformation detect-stack-drift --stack-name foobar
$ aws cloudformation describe-stack-resource-drifts --stack-name foobar
```

```json
{
  "StackId": "[OMITTED]",
  "LogicalResourceId": "Role",
  "PhysicalResourceId": "foobar",
  "ResourceType": "AWS::IAM::Role",
  "PropertyDifferences": [],
  "StackResourceDriftStatus": "IN_SYNC",
  "Timestamp": "2019-12-23T17:30:25.119Z"
}
```

Fantastic! We now have our role & policies fully imported in our CloudFormation stack.

But there's only one way to make sure everything works as expected: let's nuke our manually created role & policies and see how CloudFormation reacts to that.

## Detect stack changes

The moment of truth: let's delete our IAM role & policies manually using the AWS CLI and see how our stack behaves related to drifts:


```bash
# List all managed policies attached to the role
# (should return two: the user managed policy and the AWS managed policy)
$ aws iam list-attached-role-policies --role-name foobar

# For (managed policies returned by the command above) do:
$ aws iam detach-role-policy --role-name foobar --policy-arn "[POLICY ARN]"

# Delete the inline policy
$ aws iam delete-role-policy --role-name foobar --policy-name foobar-inline-policy

# Delete the user managed policy
$ aws iam delete-policy --policy-arn "[USER MANAGED POLICY (returned by the first command)]"

# Delete the role
$ aws iam delete-role --role-name foobar
```

Our role & policies are gone.

Let's now trigger a drift detection on our CloudFormation stack and see the output:

```bash
$ aws cloudformation detect-stack-drift --stack-name foobar
$ aws cloudformation describe-stack-resource-drifts --stack-name foobar
```

```json
{
  "StackResourceDrifts": [
    {
      "StackId": "[OMITTED]",
      "LogicalResourceId": "Role",
      "PhysicalResourceId": "foobar",
      "ResourceType": "AWS::IAM::Role",
      "StackResourceDriftStatus": "DELETED",
      "Timestamp": "2019-12-24T00:48:03.855Z"
    },
    {
      "StackId": "[OMITTED]",
      "LogicalResourceId": "UserManagedPolicy",
      "PhysicalResourceId": "[OMITTED]",
      "ResourceType": "AWS::IAM::ManagedPolicy",
      "StackResourceDriftStatus": "DELETED",
      "Timestamp": "2019-12-24T00:48:04.491Z"
    }
  ]
}
```

As expected, CloudFormation detected that our imported resources no longer exist and, thus, are reported as `DELETED`.

## (Optional) Update the delete policy

Since our import operation is now complete, CloudFormation no longer requires a `Retain` deletion policy.

So, we can remove this deletion policy from our stack definition, so in case a resource is removed from the stack (or the entire stack is removed), the associated resource is deleted.

```yaml
# role.yaml
Resources:
  Role:
    Type: AWS::IAM::Role
    DeletionPolicy: Retain # <-- REMOVE THIS LINE
    Properties:
      RoleName: "foobar"
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action: "sts:AssumeRole"
            Principal:
              AWS: "*"
      ManagedPolicyArns:
        - !Ref UserManagedPolicy
        - arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
      Policies:
        - PolicyName: "foobar-inline-policy"
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Effect: Allow
                Action:
                  - "s3:ListAllMyBuckets"
                  - "s3:ListBucket"
                  - "s3:HeadBucket"
                Resource: "*"
  UserManagedPolicy:
    Type: AWS::IAM::ManagedPolicy
    DeletionPolicy: Retain # <-- REMOVE THIS LINE
    Properties:
      ManagedPolicyName: "foobar-user-managed-policy"
      PolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action:
              - "s3:DeleteObjectTagging"
              - "s3:PutBucketTagging"
              - "s3:ReplicateTags"
              - "s3:PutObjectVersionTagging"
              - "s3:PutObjectTagging"
              - "s3:DeleteObjectVersionTagging"
            Resource: "*"
```

```bash
$ aws cloudformation update-stack --stack-name foobar --template-body file://role.yaml --capabilities CAPABILITY_NAMED_IAM
```

## Conclusion

CloudFormation Resource Import is a brand new feature, so there are still some limitations, such as resource types supported by the import operation (a full updated list can be found [here](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import-supported-resources.html)) and the way how we inform and perform the imports (compared to other solutions, such as Terraform, the update process for CloudFormation isn't still very user friendly).

However, this is a big step for CloudFormation, since it addresses a limitation raised by customers for a long time.

Worth keeping an eye on Resource Import, since it can be of great help moving existing legacy infrastructure to IaC, something mandatory nowadays.

[tf-import-post]: {{site.url}}/terraform/2019/09/30/terraform-import-role-policy
[role-manual-setup]: {{site.url}}/assets/images/posts_images/cf-import/manual-setup.png
[role-changeset]: {{site.url}}/assets/images/posts_images/cf-import/role-changeset.png
[role-imported]: {{site.url}}/assets/images/posts_images/cf-import/role-imported.png
[user-managed-policy-imported]: {{site.url}}/assets/images/posts_images/cf-import/user-managed-policy-imported.png

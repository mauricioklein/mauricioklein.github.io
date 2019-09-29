---
title: "Importing IAM roles & policies in Terraform"
date: 2019-09-30
excerpt: Legacy IAM resources? No problem! Terraform can handle it...
categories:
- Terraform
---

Immutable infrastructure has changed the way operations teams deal with cloud infrastructure and setup. The ability to translate into code the desired state of your infra improves resilience and auditing, just to mention few, by having a formal definition of your cloud requirements.

IaC (_infrastructure as code_, one of the techniques to achieve immutable infrastructure), however, imposes some learning curve, especially if you aren't familiar with the concept and the available tools. As a consequence, sometimes teams skip the automation step and start creating the cloud setup manually. This is evident in early-stage companies, running against the time to delivery its MVP.

But as the company grows, IaC becomes mandatory, otherwise, the whole situation can become chaos pretty fast. You can start automating new resources, but what about the legacy? How do you bring your early-stage infrastructure to IaC?

AWS CloudFormation doesn't have such feature available at its core, but Terraform does. So, let's see how to import your existing AWS roles and policies in Terraform.

## The setup

Before we start, we need to have an existing role with policies, not managed by Terraform. For the sake of simplicity, let's create a role with policies using CloudFormation. From the Terraform perspective, the role and policies are unknown, so they can be seen as manually created resources.

So, our CloudFormation template is the following:

```yaml
# role.yaml
Resources:
  Role:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Ref AWS::StackName
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Action: "sts:AssumeRole"
            Principal:
              AWS: "*"
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess # AWS managed policy
        - !Ref UserManagedPolicy # User managed policy
      Policies:
        - PolicyName: !Sub "${AWS::StackName}-inline-policy"
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
    Properties:
      ManagedPolicyName: !Sub "${AWS::StackName}-user-managed-policy"
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

Outputs:
  RoleName:
    Value: !Ref Role

  AWSManagedPolicyARN:
    Value: arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

  UserManagedPolicyARN:
    Value: !Ref UserManagedPolicy

  InlinePolicyName:
    Value: !Sub "${AWS::StackName}-inline-policy"
```

Now, let's create the stack:

```bash
$ aws cloudformation create-stack \
    --stack-name foobar \
    --template-body file://role.yaml \
    --capabilities CAPABILITY_NAMED_IAM
```

The template above will create the role `foobar` with three policies:
- `AmazonS3ReadOnlyAccess`, an AWS managed policy giving read-only access to S3 buckets
- `foobar-user-managed-policy`, a user managed policy giving full tag permissions for S3 buckets
- `foobar-inline-policy`, an inline policy attached to the role giving list access for S3 buckets

![][cf-role-policy]

Now that we have our role and policies, let's import them into Terraform.

## Terraform import

> The role name, policies ARNs and everything else you need to import the resources in Terraform is available on the CloudFormation stack output:
>
> ```bash
> $ aws cloudformation describe-stacks --stack-name foobar
> ```

Terraform has importing capabilities for most of the AWS resources. By importing a resource, Terraform stores in its state file the setup of the resource, as it's currently on the cloud. So, when you run `terraform plan`, the imported resources are compared with your configuration and the differences are presented.

One important thing to notice is that `terraform import` imports the resources in the state file, but doesn't fill the resource definition. This is a process we have to perform manually.

### Importing the role

Let's start by importing our role.

First of all, we need to have a Terraform resource to bind our imported role. So, let's create it:

```hcl
resource "aws_iam_role" "foobar" {
  name = "foobar"
  assume_role_policy = "{}"
}
```

We start with the most basic setup for the role, containing the role name (which isn't imported by Terraform) and an empty JSON for the assume role policy. Now, let's import the role:

```bash
# Format:
#   terraform import aws_iam_role.[placeholder resource name] [role name]
$ terraform import aws_iam_role.foobar role
```

Role imported, now let's check the differences between our resource definition and the state stored in Terraform:

```bash
$ terraform plan
```

![][role-plan-before]

Terraform is accusing a difference between the state and our resource definition. This is indeed expected since our role definition has an empty assume role policy. If we apply the resource as it is now, we'll overwrite the existing assume role policy by an empty one. That's not what we want, so let's fix it.

We need to implement the missing assume role policy and associate it to the role. So, using the previous plan output as a guideline, our previous role definition becomes:

```hcl
resource "aws_iam_role" "role" {
  name = "foobar"
  assume_role_policy = "${data.aws_iam_policy_document.assume-role-policy.json}"
}

data "aws_iam_policy_document" "assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}
```

Running `terraform plan` again:

![][role-plan-after]

Now our role definition matches the imported state.

However, the Terraform role isn't considering any policy. We have the right role setup, but no attached policy. Let's move to the next step: policies import

### Importing the AWS managed policy

The first policy in our list to be imported is the AWS managed policy `AmazonS3ReadOnlyAccess`. Since this is an AWS managed policy, we don't need to define the policy, just import it using the policy ARN. So, as done before with the role, let's define our terraform resource that will glue the role and policy together:

```hcl
resource "aws_iam_role_policy_attachment" "aws-managed-policy-attachment" {
  role = "${aws_iam_role.role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
```

Now, let's import the role/policy attachment and check the plan output:

```bash
# Format:
#   terraform import aws_iam_role_policy_attachment.[placeholder resource name] [role name]/[aws managed policy ARN]
$ terraform import \
    aws_iam_role_policy_attachment.aws-managed-policy-attachment \
    foobar/arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

$ terraform plan
```

![][aws-managed-policy-plan]

Great! Our first policy is imported to Terraform. Let's move to the next one: the user managed policy.

### Importing the user managed policy

Our next policy is `foobar-user-managed-policy`. This is a user managed policy, so using the ARN directly, as we did with the previous policy, won't work, because in case this policy is gone, we don't know how to recreate it. In this case, we need to first import the policy definition and, then, bind it with the role.

Let's start with our placeholder for the policy:

```hcl
resource "aws_iam_policy" "user-managed-policy" {
  name = "foobar-user-managed-policy"
  policy = "{}"
}
```

Now let's import the policy:

```bash
# Format:
#   terraform import aws_iam_policy.[placeholder resource name] [user managed policy ARN]
$ terraform import aws_iam_policy.user-managed-policy arn:aws:iam::xxxxxxxxxxxx:policy/foobar-user-managed-policy
```

Now that the policy is imported, let's check the `terraform plan` output:

```bash
$ terraform plan
```

![][user-managed-policy-plan-before]

As expected, there's a drift between the existing policy and our resource definition. Let's fix this by implementing the equivalent policy document:

```hcl
resource "aws_iam_policy" "user-managed-policy" {
  name = "foobar-user-managed-policy"
  policy = "${data.aws_iam_policy_document.user-managed-policy-document.json}"
}

data "aws_iam_policy_document" "user-managed-policy-document" {
  statement {
    actions = [
      "s3:DeleteObjectTagging",
      "s3:PutBucketTagging",
      "s3:ReplicateTags",
      "s3:PutObjectVersionTagging",
      "s3:PutObjectTagging",
      "s3:DeleteObjectVersionTagging"
    ]

    resources = ["*"]
  }
}
```

Running `terraform plan` again confirm that now our resource definition matches the existing policy:

```hcl
$ terraform plan
```

![][user-managed-policy-plan-after]

Our policy is now imported but, still, not connected to our role. So, the same way we did with the AWS managed role, let's import our role/policy attachment:

```hcl
resource "aws_iam_role_policy_attachment" "user-managed-policy-attachment" {
  role = "${aws_iam_role.role.name}"
  policy_arn = "${aws_iam_policy.user-managed-policy.arn}"
}
```

```bash
# Format:
#   terraform import aws_iam_role_policy_attachment.[placeholder resource name] [role name]/[user managed policy ARN]
$ terraform import \
    aws_iam_role_policy_attachment.user-managed-policy-attachment \
    foobar/arn:aws:iam::xxxxxxxxxxxx:policy/foobar-user-managed-policy

$ terraform plan
```

![][user-managed-policy-plan-after-attachment]

Now our user managed policy is imported successfully and attached to the role.

Let's move to the last resource: the inline policy.


### Importing the inline policy

The importing process for the inline policy is a bit different: since the policy doesn't exist without being attached to a role, the role/policy attachment resource isn't necessary, since it's guaranteed during the inline policy creation. Also, on the inline policy definition, we need to specify the role to which the policy is attached. So, let's start with our policy placeholder:

```hcl
resource "aws_iam_role_policy" "inline-policy" {
  name = "foobar-inline-policy"
  role = "${aws_iam_role.role.name}"
  policy = "{}"
}
```

Now, let's import the policy and check the plan output:

```bash
# Format:
#   terraform import aws_iam_role_policy.[placeholder resource name] [role name]:[inline policy name]
$ terraform import aws_iam_role_policy.inline-policy foobar:foobar-inline-policy
$ terraform plan
```

![][inline-policy-plan-before]

We have a drift, so let's fix our inline policy definition to match the existing one:

```hcl
resource "aws_iam_role_policy" "inline-policy" {
  name = "foobar-inline-policy"
  role = "${aws_iam_role.role.name}"
  policy = "${data.aws_iam_policy_document.inline-policy-document.json}"
}

data "aws_iam_policy_document" "inline-policy-document" {
  statement {
    actions = [
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
      "s3:HeadBucket"
    ]

    resources = ["*"]
  }
}
```

```bash
$ terraform plan
```

![][inline-policy-plan-after]

No changes, so our last policy is imported.

By this time, our Terraform resources definition should look like this:

```hcl
#
# ROLE:
#
resource "aws_iam_role" "role" {
  name = "foobar"
  assume_role_policy = "${data.aws_iam_policy_document.assume-role-policy.json}"
}

data "aws_iam_policy_document" "assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

#
# AWS MANAGED POLICY
#
resource "aws_iam_role_policy_attachment" "aws-managed-policy-attachment" {
  role = "${aws_iam_role.role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

#
# USER MANAGED POLICY:
#
resource "aws_iam_policy" "user-managed-policy" {
  name = "foobar-user-managed-policy"
  policy = "${data.aws_iam_policy_document.user-managed-policy-document.json}"
}

resource "aws_iam_role_policy_attachment" "user-managed-policy-attachment" {
  role = "${aws_iam_role.role.name}"
  policy_arn = "${aws_iam_policy.user-managed-policy.arn}"
}

data "aws_iam_policy_document" "user-managed-policy-document" {
  statement {
    actions = [
      "s3:DeleteObjectTagging",
      "s3:PutBucketTagging",
      "s3:ReplicateTags",
      "s3:PutObjectVersionTagging",
      "s3:PutObjectTagging",
      "s3:DeleteObjectVersionTagging"
    ]

    resources = ["*"]
  }
}

#
# INLINE POLICY:
#
resource "aws_iam_role_policy" "inline-policy" {
  name = "foobar-inline-policy"
  role = "${aws_iam_role.role.name}"
  policy = "${data.aws_iam_policy_document.inline-policy-document.json}"
}

data "aws_iam_policy_document" "inline-policy-document" {
  statement {
    actions = [
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
      "s3:HeadBucket"
    ]

    resources = ["*"]
  }
}
```

Now, let's check if our setup indeed works.

### Checking our Terraform state

Since our role and policies were successfully imported in Terraform, we should be able to restore them in case they're deleted or changed. Let's simulate this:

Since our initial resources were created using CloudFormation, let's delete the stack, so the role and policies will be deleted from the AWS account:

```bash
$ aws cloudformation delete-stack --stack-name foobar
```

Wait for the stack to be fully deleted and let's run our `terraform plan` again:

```bash
$ terraform plan
```

![][tf-plan-after-all]

As expected, Terraform correctly identified that our resources are gone and plan to recreate them. Let's proceed with the Terraform apply and check the result on AWS console:

![][tf-apply]

![][new-resources]

Success!

Now you have your manually created role and policies fully imported in Terraform. From now on, all the changes can (and should) be made via Terraform, so you always have the state as the source of truth for your infra.

### Cleanup (optional)

Now that the experiment is over, you can delete the role and policies created. Since they're now managed by Terraform, the cleanup is as easy as:

```bash
$ terraform destroy -auto-approve
```

[cf-role-policy]: {{site.url}}/assets/images/posts_images/terraform-role-import/cf-role-policy.png

[role-plan-before]: {{site.url}}/assets/images/posts_images/terraform-role-import/role/plan-before.png
[role-plan-after]: {{site.url}}/assets/images/posts_images/terraform-role-import/role/plan-after.png

[aws-managed-policy-plan]: {{site.url}}/assets/images/posts_images/terraform-role-import/aws-managed-policy/plan.png

[user-managed-policy-plan-before]: {{site.url}}/assets/images/posts_images/terraform-role-import/user-managed-policy/plan-before.png
[user-managed-policy-plan-after]: {{site.url}}/assets/images/posts_images/terraform-role-import/user-managed-policy/plan-after.png
[user-managed-policy-plan-after-attachment]: {{site.url}}/assets/images/posts_images/terraform-role-import/user-managed-policy/plan-after-attachment.png

[inline-policy-plan-before]: {{site.url}}/assets/images/posts_images/terraform-role-import/inline-policy/plan-before.png
[inline-policy-plan-after]: {{site.url}}/assets/images/posts_images/terraform-role-import/inline-policy/plan-after.png

[tf-plan-after-all]: {{site.url}}/assets/images/posts_images/terraform-role-import/tf-plan-after-all.png
[tf-apply]: {{site.url}}/assets/images/posts_images/terraform-role-import/tf-apply.png
[new-resources]: {{site.url}}/assets/images/posts_images/terraform-role-import/new-resources.png

---
title: "Replace your long-term keys by temporary credentials with AWS CLI & Console"
excerpt: Let's learn how to retire your long-term keys and replace them by temporary credentials
date: 2021-02-09
categories:
  - AWS
  - Security
---

E-commerce, serverless application, data lake, container service...

Doesn't matter what kind of service you're creating. If you're building it on AWS, there's
one thing you can't run away from: IAM.

AWS IAM (_Identity & Access Management_) is the gatekeeper of your entire AWS account. It says who can access your account and what this person/service can and cannot do.

For applications running in the cloud, IAM roles are the recommended way to grant the necessary permissions your service requires. However, when the topic is accessing your AWS account from localhost using the AWS CLI, most users still rely on long-term credentials.

While long-term credentials are convenient, they can put you in trouble if they get leaked. With enough permissions, anyone in possession of your keys can start services at your expense, steal sensitive data or even put your service down.

In this post, I'll show you how to replace your long-term credentials by temporary ones, so you can enhance the security of your local setup and reduce the blast radius in case of a leak.

By the end of this post, you will have a fully configured setup to acquire temporary credentials whenever needed and renew them when expired.

> This article will focus on environments with few accounts (like personal accounts and startups). For large environments, [AWS Organizations](https://aws.amazon.com/organizations/) and [AWS SSO](https://aws.amazon.com/single-sign-on/) gives you a much more scalable and maintainable way to set up access via federation.

---

## Requirements

### Valid credentials

This tutorial will assume you have valid credentials stored in the named profile `default` and that these credentials have enough permissions to perform IAM related operations. `IAMFullAccess` is a good candidate while following the tutorial (don't worry, you can remove this policy by the end of the tutorial).

In case you don't have the credentials, [follow the official docs to create them](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey).

### MFA

MFA (_multi factor authentication_) provides a second layer of authentication to your setup. In this tutorial, I'll use a virtual MFA device, which is basically an app running on my personal smartphone that generates OTPs (_one-time password_). However, this tutorial should work just fine with any MFA device supported by AWS.

To set up your virtual MFA device and link to your account, [follow the official documentation here](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa_enable_virtual.html).

---

## Setup

Our solution will leverage [`STS AssumeRole`](https://docs.aws.amazon.com/cli/latest/reference/sts/assume-role.html) to request temporary credentials based on an IAM role. By calling `AssumeRole`, AWS returns temporary credentials granting all the permissions assigned to the assumed role. Permissions aren't cumulative, so once you assume a role using _STS_, you forfeit access to the original permissions attached to your IAM user.

Additionally, to make the authentication process more secure, we will make sure the role can only be assumed if MFA authentication is presented during the operation.

So, let's start by creating the IAM role with the permissions for the temporary credentials. For this role, we need to define the assume role policy:

> _file://role-policy.json_

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "[you user ARN]"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    }
  ]
}
```

The assume role policy above grants permission to your user to assume roles, but with the condition that MFA authentication is presented. It means that, if you try to assume a role using your long-term credentials directly (without MFA), it will be rejected. This grants an additional layer of security, since, if your long-term credentials get leaked, the attacker won't have the power to assume the role unless he/she gets access to your MFA device.

Now, let's create the role:

```bash
# Create the IAM role
$ aws iam create-role --role-name PowerUserRole --assume-role-policy-document file://role-policy.json

# Attach the PowerUserAccess policy to the role
$ aws iam attach-role-policy --role-name PowerUserRole --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

We attached the AWS managed policy `PowerUserAccess` to the role. This policy grants full access to your AWS account, except for actions in `IAM`, `Organizations` and `Account`. In other words, the role has full access to the account but can't change permissions, add/remove users, etc.

Next, let's allow your user to call _assume-role_ action on the _PowerUserRole_ role created above. 

> _file: assume-role-policy.json_

```json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": [
      "[PowerUserRole ROLE ARN]"
    ]
  }
}
```

```bash
# Create the user perms policy
$ aws iam create-policy --policy-name AllowAssumeRolePolicy --policy-document file://assume-role-policy.json

# Attach the policy to your user
$ aws iam attach-user-policy --user-name [your user name] --policy-arn [AllowAssumeRolePolicy POLICY ARN]
```

From now on, your user has permissions to assume the _PowerUserRole_ role in your AWS account, but MFA must be presented during the _assume-role_ operation.

## CLI access

Let's set up our named profile (`mfa`). This profile will instruct AWS CLI to assume the role `PowerUserRole` whenever the profile is used. It will also inform the MFA device used for the multi-factor authentication. Additionally, we will inform the session duration desired for the temporary credentials. 

```bash
# Source profile is the named profile holding the long-term credentials used for
# the "assume-role" operation
$ aws configure --profile mfa set source_profile default

# The ARN of the role to be assumed
$ aws configure --profile mfa set role_arn [PowerUserRole ROLE ARN]

# The ARN of your MFA device
$ aws configure --profile mfa set mfa_serial [MFA DEVICE ARN]

# Set session duration for 1 hour (3600 seconds)
$ aws configure --profile mfa set duration_seconds 3600
```

Now, you just need to use the profile as usual. Whenever the temporary credentials expires, AWS CLI will ask you for a new OTP and refresh your credentials. Easy and convenient 😊

```bash
$ aws s3 ls --profile mfa
# Enter MFA code for arn:aws:iam::XXXXXXXXXXXX:mfa/myself

# 2021-01-01 00:00:00 bucket-a
# 2020-01-01 00:00:00 bucket-b
```

> Attention:
>
> For assumed role credentials, AWS CLI treats any session with expiration within 15 min as expired. So, as an example, if your session is still valid for 10 minutes, using it for issuing a new CLI command will make AWS CLI request new ones (and ask you for a new _OTP_).
>
> [More information can be found here](https://github.com/aws/aws-cli/issues/5880#issuecomment-769243927)

## Console access

You can use the very same setup to assume a role in the console instead of using your IAM user's permissions.

To do so, log in on AWS console using your regular IAM user's credentials and go to `Switch Roles` in the dropdown menu in the upper-right part of the screen.

Now, you just need to fill in the information as follows:

- `AccountId`: your AWS account ID
- `Role`: the name of the role to assume
- `Display Name`: (optional) a custom display name to present on the dropdown menu (and assume-role history).

![][assume-role-console-setup]
*Assuming a role on AWS console*

By clicking on `Switch Role` you will be redirected back to console, but now your permissions are defined by the assumed role.

![][assumed-role-console]
*Assumed IAM role on AWS console*

In case you wanna go back to your IAM user, just go to the dropdown menu and click on `Back to [your user name]`.

Once a role is assumed the first time, it remains in the dropdown assume-role history. So, switching to the role next time is one click away.

> Session duration for an assumed role on the console is given by the maximum session duration defined in the role or the remaining session duration for the IAM user session, whichever is less ([more information here](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-console.html)).

[A full documentation about how to assume role on console can be found here](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-console.html).

### Session duration

IAM roles are created by default with the maximum session duration set to one hour. It means that, if you set `duration-seconds` parameter on your named profile for anything longer than one hour, _assume-role_ will fail. If you want to allow longer sessions, you can append the parameter `max-session-duration` to the `create-role` command.

```bash
# Create the IAM role "PowerUserRole" with maximum session duration of 4 hours (i.e. 14400 seconds) 
$ aws iam create-role --role-name PowerUserRole --assume-role-policy-document file://role-policy.json --max-session-duration 14400

# ... or update the maximum session duration of the existing "PowerUserRole" role
$ $ aws iam update-role --role-name PowerUserRole --max-session-duration 14400
```

Maximum session duration is provided in seconds and accepts any value between 1 hour and 12 hours.

## Admin User

Now that you have an IAM role granting you permissions via temporary credentials, you can remove any permissions assigned directly to your IAM user (except the `AllowAssumeRolePolicy` policy). This will guarantee that your long-term credentials can be used only to request the temporary ones. If leaked, attackers won't have much power unless they get access to your MFA device too.

However, our role has the `PowerUserAccess` policy attached, which means it can't change anything IAM related. How do you manage to adjust your setup in the future?

The recommended way is setting up an admin IAM user, which Administrator access. This user will be used solely for administrative tasks (such as adjusting your IAM roles and permissions) and shouldn't be used for your day-to-day operations.

[Instructions on how to create a new admin user can be found here](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html).

Finally, if you decide to use your admin user credentials via CLI (and, thus, need to generate long-term credentials), it might be a good idea to deactivate your credentials when not in use. This will require you to log in to the console in order to re-activate the credentials, but guarantee that your credentials are only valid while you're actually using them.

## Conclusion

In this article, we saw how easy is to retire your long-term AWS keys and leverage temporary credentials.

Temporary credentials enhance the security of your account. First, because in a situation of credentials leakage, the attacker has a limited amount of time to do any damage. Second, because MFA adds an extra layer of security, making it harder for attackers to hijack your account.

Also, IAM roles give you more control about what permissions are in effect for a specific session. By creating fine-grained IAM roles, you can create dedicated named profiles in your localhost with the same setup presented in this article and use them according to your need. This approach provides a more secure setup and complies with the AWS concept of least privilege.

[assume-role-console-setup]: https://user-images.githubusercontent.com/11538662/107290201-6cd46780-6a66-11eb-81d0-c045b5e988e5.png

[assumed-role-console]: https://user-images.githubusercontent.com/11538662/107290205-6e059480-6a66-11eb-87f7-b68c185a8717.png
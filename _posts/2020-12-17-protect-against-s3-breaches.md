---
title: "Protect your S3 buckets from breaches"
date: 2020-12-17
excerpt: Learn how to protect your S3 buckets from breaches and don't become the next victim
categories:
  - AWS
  - S3
  - Security
---

If you have been following the latest news on AWS world, headlines like these aren't uncommon:

- _"Company A exposes customers data after major S3 bucket breach"_
- _"Company B leaks the data of over 30.000 partners"_
- _"Company C exposes 2M users on misconfigured AWS storage"_

Breaches related to S3 buckets are more common than it should be and, most of the time, puts companies in a bad situation, exposing their private information or, even worse, their customer's.

[Corey Quinn](https://twitter.com/QuinnyPig), cloud economist at The Duckbill Group and active member of the community, even created the _S3 Bucket Negligence Award_, to "reward" individuals or companies that made it to the news after a major data breach.

<center>
  <blockquote class="twitter-tweet">
    <p lang="en" dir="ltr">
      This week&#39;s S3 Bucket Negligence Award goes to Facebook!<br><br>&quot;Oh, it was one of their partners--&quot; Stop talking immediately. They were the stewards of the data. They shared it with their partner. It is their responsibility, full stop. 
      <a href="https://t.co/mYqYA2pAnP">https://t.co/mYqYA2pAnP</a>
    </p>
    &mdash; Corey Quinn (@QuinnyPig) <a href="https://twitter.com/QuinnyPig/status/1113522979772674048?ref_src=twsrc%5Etfw">April 3, 2019</a>
  </blockquote>
  <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
</center>

But, what all these cases have in common? They all happened due to the lack of proper security applied to bucket setup.

In this post, I will present the most common causes of S3 breaches and how to protect yourself against them.

By the end of this post, you will have a better knowledge about the tooling available and how to apply them to protect your data and don't become the next victim.

## Prerequisites

Familiarity with AWS and S3 is required to take the maximum out of this post.

## Breach #1: the public bucket

This is by far the most common breach involving S3.

S3 buckets are, by default, created with all public access denied. It means that, unless special privileges are granted, one can't access the data. When a bucket is made publicly accessible, you give up restricting access to your data.

This has two major impacts: privacy and costs.

By having a public bucket, you no longer have control over who can or can't access your data. While it can be OK for public files, this can be a big issue for sensitive information.

Also, [as described on S3 pricing model](https://aws.amazon.com/s3/pricing), the costs associated with a bucket are determined not only by the amount of storage used but also by the number of requests and data transfer, among others. So, with no caching mechanism in place, all requests are served directly by S3, and this can make your monthly bill pretty salty.

### How to fix it?

The immediate action here depends on the impact of the breach.

If you're exposing sensitive information or violating any regulation, no questions asked: close the public access right away. This can be done by going to your bucket's permissions and editing the public access setup.

![][s3-public-access-setup]
*Bucket with all public access blocked*

However, if the damage is low and you have time, a deeper analysis is recommended.

It might be that one or more of your services are working on the assumption that the bucket will always be public. If so, closing the access can impair your operations. This is a bad practice and should be avoided. Instead, you should leverage IAM roles and bucket policies to restrict access to the concerned services.

![][bucket-policy]
*Example of bucket policy granting GetObject permission for a specific role*

But how can we know what services are using this bucket? Going service by service can be doable in a small context, but on large ecosystems this is impracticable. For this, you can leverage [S3 server access logging](https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerLogs.html) to record all requests performed to the bucket. The logs will contain a list of requests performed on the bucket, including operation (`PUT`, `GET`, etc), date, and IP address of the client. Using the logs, you can then check the services interacting with the bucket and grant the appropriate permissions.

![][bucket-logging]
*Enabling access logging to a bucket*

Another great alternative is to use [Access Analyzer for S3](https://docs.aws.amazon.com/AmazonS3/latest/user-guide/access-analyzer.html). With Access Analyzer, you can get notified if one or more buckets allow public access to the internet or AWS accounts outside your organization. Also, Access Analyzer provides a `Block all public access` option, which can be used to restrict all public access to buckets with a single click.

![][access-analyzer]
*Access Analyzer for S3, presenting a list of publicly accessible buckets discovered by the analyzer*

Once the impact is estimated and corrective measures are taken, you can turn the public access off on the bucket.

> _- "But I still need my data to be publicly accessible"_

In this case, a CDN (_content delivery network_) would be the best choice. By using a CDN, not only you have the data cached on edges (which reduces the number of requests served directly by S3) but also reduces the latency for the end-user since the data is closely available on the closest edge.

[CloudFront is a great candidate here](https://aws.amazon.com/blogs/networking-and-content-delivery/amazon-s3-amazon-cloudfront-a-match-made-in-the-cloud/), since it natively supports S3 buckets as the origin.

## Breach #2: the unwelcomed visitor

This is as variation of [breach #1](#breach-1-the-public-bucket).

Here, the bucket isn't necessarily public, but policies are overly permissive. By applying overly permissive policies, you might be opening your bucket for unwanted visitors. 

Let's consider a bucket used to store sensitive information from your customer, such as addresses, phone numbers, etc. The bucket has the following bucket policy applied:

![][bucket-overly-permissive-policy]

This policy is granting full permission to anyone with access to the AWS account owning this bucket. A bad intended actor could exploit this breach to collect data from your customer and use it for self-benefit. This actor can be not only external attackers that manage to access your account but also internal ones. Additionally, this policy also grants write access to the bucket, which means customer data can be modified unrestrictedly.

### How to fix it?

The solution here is to follow the [principle of least-privilege](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege). This principle defines that the permissions granted to a party should be the minimum necessary to perform its duties. So, instead of granting read and write access to any service and user inside your organization, specific permissions should be granted based on their level of interaction with the bucket.

By using bucket policies, you can restrict what users are allowed to interact with the bucket and what actions are they allowed to perform. Associated with IAM roles and groups, permissions can be granted to groups and/or services instead of individuals, which makes everything much easily manageable.

![][bucket-restricted-policy]
*The same policy, but now restricting permissions to a single IAM role*

## Breach #3: the encrypted bucket

This is a very interesting breach and can put a company in a very delicate situation.

You might think that stealing your data is the worst that can happen, but it can get even worse. Consider an attacker that manages to access your account and, due to a poor set of permissions, is granted write access. Using a private key, the attacker can manage to encrypt all the data in the bucket. It means that, from now on, only those in possession of the encryption key can read the object's content from the bucket.

Under these circumstances, the attacker is in control of the situation and can ask, among other things, for a ransom to decrypt the data.

### How to fix it?

The first point here, once again, is to tighten your permissions, so attackers don't have privileged access to the bucket. [Enabling MFA for the users in your account is highly recommended](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa.html), since it adds an extra layer of security against unauthorized access. You can then deny access to principals in your bucket that don't have MFA enabled.

![][deny-if-no-mfa]
*Bucket policy denying access if MFA isn't enabled*

But we can do better.

This situation could be reverted if [versioning](https://docs.aws.amazon.com/AmazonS3/latest/dev/Versioning.html) was enabled on the bucket. By enabling bucket versioning, uploading a same object generates a new version instead of overwriting it. It means that, in a situation where the data is encrypted by an attacker, you can revert the affected objects to the previous version (which is unencrypted or encrypted by a key you have control).

![][bucket-versioning]
*Enabling versioning for a bucket*

## Breach #4: the data loss

Our last breach involves the accidental or intentional deletion of data in a bucket. It can be done by a malicious actor (like a hacker that manages to access your bucket) or even non-malicious (like accidental deletion or a bug in your system).

The result is the loss of data that can be hard or even impossible to reproduce and impact the reliability of your service.

### How to fix it?

This problem can be addressed by using two strategies.

First, as mentioned in the previous breach, [enabling bucket versioning](https://docs.aws.amazon.com/AmazonS3/latest/dev/Versioning.html) helps to avoid losing the data indefinitely. On a versioned S3 bucket, deleting an object doesn't actually deletes it, but simply puts a `delete` marker on it. By enabling `List versions` in the UI, you can see all the versions for the object, including the `delete` marker. So, un-deleting the object is as simple as removing the marker.

![][object-delete-marker]
*Delete marker in a bucket object. To undelete the object, delete the "Delete marker" entry*

The second strategy is [enabling MFA delete on the bucket](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMFADelete.html). In buckets with MFA delete enabled, MFA (_multi-factor authentication_) is required to permanently delete an object and change the versioning setup of the bucket. So, even if the object has a delete marker, the only way to permanently delete the object will require a MFA token.

![][enable-mfa]
*Enabling MFA Delete on a S3 bucket*

## Conclusion

This post presented situations where the integrity and privacy of your S3 bucket can be at risk and how to remediate them. Although the range of situations is virtually infinite, sticking with the best practices is always the way to go and should protect you from the majority of the cases. 

These best practices includes:

- Block public access
- Enable encryption
- Enable versioning
- Tighten bucket policies

## Next steps

Keeping one bucket safe is relatively easy, but at scale, automation is necessary. Having an automated system that checks your buckets continuously, evaluate breaches and perform actions in response is necessary to keep your data secure and let your team focus on what matters for your customers.

On my next post, we will implement this automation, so stay tuned and follow me on Twitter down below to receive the notification when the post is out 🙂 

## Continue reading

- [Ten worst Amazon S3 breaches](https://businessinsights.bitdefender.com/worst-amazon-breaches)
- [How to find public buckets](https://auth0.com/blog/fantastic-public-s3-buckets-and-how-to-find-them/#The-Context)
- [AWS least privilege principle](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege)
- [Using bucket versioning](https://docs.aws.amazon.com/AmazonS3/latest/dev/Versioning.html)
- [Using bucket MFA Delete](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMFADelete.html)

<!--
  Images
-->
[s3-public-access-setup]: https://user-images.githubusercontent.com/11538662/102489099-51a03980-406d-11eb-979d-3a860815646b.png
[access-analyzer]: https://user-images.githubusercontent.com/11538662/102489086-4f3ddf80-406d-11eb-9172-691492fa57a0.png
[bucket-policy]: https://user-images.githubusercontent.com/11538662/102489088-506f0c80-406d-11eb-8b35-e92352ad6663.png
[bucket-logging]: https://user-images.githubusercontent.com/11538662/102489020-35040180-406d-11eb-8553-2bd6f9173314.png
[bucket-overly-permissive-policy]: https://user-images.githubusercontent.com/11538662/102489070-4816d180-406d-11eb-8cb3-8a435fb1edd0.png
[bucket-restricted-policy]: https://user-images.githubusercontent.com/11538662/102489089-506f0c80-406d-11eb-882e-dfbc6bbb9d1b.png
[bucket-versioning]: https://user-images.githubusercontent.com/11538662/102489090-506f0c80-406d-11eb-894f-f9d9390abeae.png
[object-delete-marker]: https://user-images.githubusercontent.com/11538662/102489095-5107a300-406d-11eb-8ded-6771ff3d1bd9.png
[enable-mfa]: https://user-images.githubusercontent.com/11538662/102489092-5107a300-406d-11eb-82ec-54e40755ccea.png
[deny-if-no-mfa]: https://user-images.githubusercontent.com/11538662/102490697-77c6d900-406f-11eb-84ef-b83647ab6b9c.png

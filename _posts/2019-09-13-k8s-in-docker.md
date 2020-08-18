---
title: "Multi-node K8s cluster... without nodes! WHAAAT?"
date: 2019-09-13
excerpt: K8s cluster without nodes? Are you nuts? Hold your horses...
categories:
  - Kubernetes
redirect_from:
  - /kubernetes/2019/09/13/k8s-in-docker/
---

When I started using K8s, some years ago, it was pretty hard to find a cluster to run my experiments. Basically, the way to go was using Minikube. I don't know if it was me, but I never got lucky with Minikube: every time I tried using it, I ended spending more time setting up the environment than actually using it.

Sometime after, Docker Desktop added native support to K8s. It was the glory! With a single click, I get a single node K8s cluster up and running, ready for usage. Sure, depending on how hard you use this humble cluster, your Macbook can reach temperatures high enough to prepare bacon and eggs while you rollout a deployment.

Docker Desktop has been serving me well since then, but as I evolve in my K8s studies, multi-node cluster became mandatory, especially when the subject is resilience and HA. Docker Desktop, unfortunately, is single node cluster, period, and I don't wanna get back to the Minikube pain again.

That's when I found [Kind][kind].

Kind (**K**8s **in** **D**ocker) is a tool for running a multi-node K8s cluster in Docker, using containers to emulate a real node.
This is fantastic if you need a quick environment for testing an app, or when you don't have access to an online cluster at the moment. Also, needless to say, it's much more lightweight than starting multiple VMs in your localhost.

So, let's see Kind in action.

## Kind in action

The [official Kind page][kind-installation] has all the instructions on how to install the dependencies and the tool itself.

After the environment is prepared, creating a single node cluster is as easy as:

```
$ kind create cluster
```

Kind will setup a single node cluster, first downloading the base node image and setting up the container to behave like a K8s node.

![][single-node]

Running `docker ps` shows you a new container running, which is your "node". After loading the Kubeconfig setup by Kind, you're ready to start creating your resources:

![][single-node-run]

Deleting the cluster is no-brain:

```
$ kind delete cluster
```

Pooff! Gone!

> But what about multi-node cluster?

Kind allows you to describe your cluster in a config file. So, for a cluster with two masters (why not a HA master?) and two workers, the basic setup is:

```yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
nodes:
  - role: control-plane
  - role: control-plane
  - role: worker
  - role: worker
```

And the command to create the cluster becomes:

```
$ kind create cluster --config kind-config.yaml
```

And watch the magic happen:

![][ha-cluster]

If you run `docker ps` with this cluster, you won't see four, but five containers. That's because, due to the multi-master setup, Kind provisions a "load balancer" (which, in reality, is a container running a HA proxy) to distribute the traffic among the master nodes.

> **I WANT MORE!!!**

You got it!

In [this repo][lab-repo], I set up a CloudFormation script that provisions an EC2 instance with Docker, Kubectl and Kind pre-installed. Also, in the README, you can find some experiments using K8s. Enjoy :)

## Conclusion

Kind is a very versatile tool for performing quick experiments with K8s or using as a virtual cluster for integration and E2E tests. Since it's an emulation of a real cluster, the tool has some limitations, which you can see [here][kind-limitations]. For more complex cases, you might end going back to a real cluster, maybe using the good old [Kops][kops]. But, for more simple, day-to-day usage, Kind can be a powerful tool in your toolbox.

[kind]:              https://kind.sigs.k8s.io
[kind-installation]: https://kind.sigs.k8s.io/docs/user/quick-start/
[kind-limitations]:  https://kind.sigs.k8s.io/docs/user/known-issues/
[kops]:              https://github.com/kubernetes/kops
[lab-repo]:          https://github.com/mauricioklein/kind-experiment

[single-node]:     {{site.url}}/assets/images/posts_images/kind/single-node.png
[single-node-run]: {{site.url}}/assets/images/posts_images/kind/single-node-run.png
[ha-cluster]:      {{site.url}}/assets/images/posts_images/kind/ha-cluster.png

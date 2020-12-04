---
title: "Playing with Ansible... on Docker"
date: 2018-02-23
excerpt: Why bother creating Amazon VMs when you have Docker?
categories:
  - Ansible
  - Docker
redirect_from:
  - /ansible/docker/2018/02/23/ansible-docker/
---

(*TL;DR: The project presented here, with all the necessary files and setup steps,
  can be found on [this repository][code-repo]*)

So, this week I decide to study Ansible and, after reading and watching some tutorials about
the technology, I decided to get my hands dirty.

So, my first think was:

> OK, I need some machines to provision, so quite probably I'll need to
> create some EC2 instances to play with Ansible...

But then I realised:

> Wait a second... I've Docker... Hum...

## What's Ansible?

Ansible is a set of tools that automates software provisioning, configuration of services and application deployment. More information can be found on [the official website][ansible-website].

## The project

So, before starting, we need to define the architecture and the roles of each component.

On this project, we'll have four Docker containers running:

- One container with `Ansible` installed. This will be our "master" machine, responsible to provision
  the other ones.

- Three clean containers, with only `sshd` (*ssh deamon*) installed and configured. These containers will play
  the role of servers, it means, the machines that will actually be prepared to run our service.

Also, we need some service to test that our servers are well configured and ready to use. So, we're going to use [this project][hello-world], which is a simple "hello world" written in NodeJS that I found on Github.

Architecture and actors defined, let's move to the setup.

## The server "machine"

So, first, we need a clean Docker image, having only the ssh daemon installed. This clean image will have none of our dependencies installed, since the objective here is to see Ansible taking care of that.

So, here's the Dockerfile used to create this image:

```docker
FROM ubuntu:16.04

RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:ansible' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
```

This image creates a Docker container with SSH access enabled, necessary in order to Ansible run the remote commands. The SSH access is set using `root` and `ansible` as user and password, respectively.

## SSH config

To avoid strict host key checking when connection to the servers the first time, we need to disable this check in the ssh config file:

```
Host *
   StrictHostKeyChecking no
```

## Ansible hosts

Ansible relies on `/etc/ansible/hosts` files to define which machines are going to be provisioned. Ansible supports groups of machines, so you can refer to a group in the playbook instead of each machine individually. Since we've defined an architecture with 3 server machines, our hosts file will be the following:

```yaml
[server_hosts]
ansibledocker_server_[1:3]

[server_hosts:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_user=root
ansible_ssh_pass=ansible
```

Our group `server_hosts` includes 3 machines:

- ansibledocker_server_1
- ansibledocker_server_2
- ansibledocker_server_3

These hostnames were defined based on the containers names given by docker compose when scaling the number of servers. Don't worry: it will become clearer when we run the entire docker environment.

The `server_hosts:vars` section is used to define some extra parameters for Ansible when provisioning machines from the `server_hosts` group. In our case, we're defining the Python interpreter and the SSH authentication credentials to connect to our servers.

We could use some ssh public key here to avoid hardcoding the auth credentials, but for the sake of simplicity, we're using the `user:pass` approach.

## Ansible playbook

The most important file of the whole project: the Ansible playbook.

Here's the file content with comments, explaining the purpose of each task:

```yaml
---
# Provision all hosts
- hosts: all
  remote_user: root

  tasks:
    # Install Git binary.
    # Git is necessary to download our NodeJS project from Github.
    - name: Install Git
      include_role:
        name: ANXS.git

    # Downloads the Node project from Github and save
    # on `hello-world/` directory
    - name: Download project
      git:
        repo: 'https://github.com/azat-co/nodejs-hello-world'
        dest: 'hello-world'

    # Install NodeJS library
    - name: Install NodeJS
      include_role:
        name: geerlingguy.nodejs

    # Install all the necessary Node modules for the project,
    # using `npm`.
    - name: Install project dependencies
      command: npm install
      args:
        chdir: hello-world/

    # Install Forever tool.
    # This tool is used to run the Node server in background
    # and keep tracking of the running process
    - name: Install Forever
      npm: name=forever global=yes state=present

    # This is an auxiliary task, used to identify if our Node service
    # is already running (avoids restarting the service on each playbook
    # execution)
    - name: Get Forever's list of running processes
      command: forever list
      register: forever_list
      changed_when: false

    # Start the node server using "Foverer"
    # The `when` clause identifies if the server is already
    # running. If so, this task is skipped
    - name: Start service
      command: forever start web.js
      when: "forever_list.stdout.find('hello-world/web.js') == -1"
      args:
        chdir: hello-world/
```

## The Docker compose file

Finally, to glue everything together, comes the compose file.

So, considering we've the following file structure with our existing resources:

![][filesystem]

The resulting compose file is:

```yaml
version: '3'
services:
  ansible:
    image: williamyeh/ansible:debian9
    volumes:
      - "./ssh/config:/root/.ssh/config"
      - "./ansible/hosts:/etc/ansible/hosts"
      - "./playbooks:/root/playbooks"
    links:
      - server

  server:
    build: .
```

The compose basically defines two types of container:

- **ansible**: this is our main container, with Ansible installed. This is the container that will dispatch the commands for the other containers. Some configuration files for ssh and Ansible are mapped as volumes on this container, since they're going to be used to provision the servers.

- **server**: this is our "server" container. It's created based on the clean Docker image we've defined in `Dockerfile` file, with only sshd installed.

## Getting hands dirty

Architecture explained, it's time to see the things running.

So, first, let's start the base environment:

```bash
$ docker-compose run ansible bash
```

This will start the `ansible` container and one `server` container, opening a console with the former one:

![][compose-run]

Unfortunately, `docker-compose run` doesn't support the `scale` flag, so we need to scale the servers containers manually. In a separated terminal, run:

```bash
$ docker-compose scale server=3
```

![][scale-servers]

This will scale our servers to three containers, with the hostnames `ansibledocker_server_1`, `ansibledocker_server_2` and `ansibledocker_server_3`. Not by coincidence, these are exactly the same hosts defined on the Ansible's host file, as explained before.

Back to the Ansible console, we can now test that our 3 servers are accessible. Therefore, we can use the Ansible's `ping` role:

```bash
$ ansible all -m ping
```

![][ansible-ping]

> Some readers are getting the following error when running the _ping_:
>
> _Failed to connect to the host via ssh: Bad owner or permissions on /root/.ssh/config_
>
> If this is your case, please check the [troubleshooting section](#troubleshooting).

Now that all servers are accessible, we can prepare to run the playbook. First, we need to download some additional Ansible roles. The best place to find reusable Ansible content is [Ansible Galaxy][ansible-galaxy]. It behaves like a central repository for Ansible, containing roles for basically everything you can imagine. Worth to give a check :)

So, let's install the extra roles:

```bash
# ANXS.git:           role to install the Git binary
# geerlingguy.git:    role to operate Git (i.e. download repository)
# geerlingguy.nodejs: role to install NodeJS
$ ansible-galaxy install ANXS.git geerlingguy.git geerlingguy.nodejs
```

![][download-roles]

Now that all roles are available, we can finally fire the playbook:

```bash
$ ansible-playbook /root/playbooks/setup.yml
```

Ansible will now run all our tasks, ensuring that all the dependencies are installed and configured. This can take some time, so go grab a coffee... I'll wait :)

After finished, Ansible will display a recapitulation of the affected servers and those who changed (installation/uninstallation/modification/etc):

![][playbook-run]


## Testing

At this point, all the servers should be configured and our Node project should be running on port `5000`.

So, let's see if everything is OK:

```bash
$ curl -XGET ansibledocker_server_1:5000
$ curl -XGET ansibledocker_server_2:5000
$ curl -XGET ansibledocker_server_3:5000
```

For each one of the requests above, you should get a `Hello World` as response:

![][curl-check]

## Success!

Hooray!

You've just provisioned 3 servers with NodeJS using Ansible :)

## Conclusion

- This project uses Docker for convenience. Therefore, we don't have to bother about starting Amazon servers only for testing purposes. However, since the containers used here behave exactly like a plain machine with sshd installed, the very same setup should work on any cloud or bare-metal architecture.

- The objective of this project **isn't** to teach how to provision Docker containers using Ansible. As stated by [Michael DeHaan][dehaan], creator of Ansible, Docker containers typically have a single responsibility and, thus, much less configuration. So, the overhead of having a complete Ansible configuration to provision them are, most of the time, unnecessary.

Finally, the entire project, with the configuration files, Ansible playbook and everything else presented here can be found [on this repository][code-repo].

Hope you enjoyed this post and happy coding! :)

---

## Troubleshooting

#### 1. _Failed to connect to the host via ssh: Bad owner or permissions on /root/.ssh/config_

This happens because Docker compose is mapping the ssh config file with the wrong permissions.

Checking ssh _man_ documentation, we can read this:

> _Because of the potential for abuse, this file must have strict permissions:_
> _**read/write for the user, and not writable by others.**_
> _It may be group-writable provided that the group in question contains only the user._

So, in order to fix this problem, inside the Ansible container, run:

```ssh
$ chown root ~/.ssh/config
$ chmod 644 ~/.ssh/config
```

[ansible-website]: https://www.ansible.com/
[ansible-galaxy]: https://galaxy.ansible.com/
[hello-world]: https://github.com/azat-co/nodejs-hello-world
[dehaan]: https://github.com/mpdehaan
[code-repo]: https://github.com/mkleinio/ansible-docker

[filesystem]: {{site.url}}/assets/images/posts_images/ansible-docker/filesystem.png
[compose-run]: {{site.url}}/assets/images/posts_images/ansible-docker/compose-run.png
[scale-servers]: {{site.url}}/assets/images/posts_images/ansible-docker/scale-servers.png
[ansible-ping]: {{site.url}}/assets/images/posts_images/ansible-docker/ansible-ping.png
[download-roles]: {{site.url}}/assets/images/posts_images/ansible-docker/download-roles.png
[playbook-run]: {{site.url}}/assets/images/posts_images/ansible-docker/playbook-run.png
[curl-check]: {{site.url}}/assets/images/posts_images/ansible-docker/curl-check.png

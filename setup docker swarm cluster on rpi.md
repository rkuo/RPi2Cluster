

[toc]

# RPi Cluster - Swarm

## Materials
* 1 [USB power hub](http://elinux.org/RPi_Powered_USB_Hubs#USB_hub_power_circuitry_tests) with 4 ports 2amp per port minimun.
* 4 Raspberry Pi 2B (1GB, no wifi)
* 4 SD cards minimun 8GB, I use 32GB here.
* 4 wifi dongles (for rpi2)
* 1 router (to be used later)

## Research and reference

* [Raspberry Pi 3 Super Computing Cluster Part 2 - Software Config](https://www.youtube.com/watch?v=eZ5uX-JJbyY) <<--- follow this for networking 20170522  
* [Setup Kubernetes on a Raspberry Pi Cluster easily the official way!](https://blog.hypriot.com/post/setup-kubernetes-raspberry-pi-cluster/) <<--- follow this 20170522
* [How I setup a Raspberry Pi 3 Cluster Using The New Docker Swarm Mode In 29 Minutes](https://medium.com/@bossjones/how-i-setup-a-raspberry-pi-3-cluster-using-the-new-docker-swarm-mode-in-29-minutes-aa0e4f3b1768)
* [Cluster computing on the Raspberry Pi with Kubernetes](https://opensource.com/life/16/2/build-a-kubernetes-cloud-with-raspberry-pi)
* [Docker Swarmmode Test Scenarios](https://github.com/alexellis/swarmmode-tests/tree/master/arm)
* [Docker Swarm Mode Walkthrough](https://www.youtube.com/watch?v=KC4Ad1DS8xU)
* [Get Started with Docker on Raspberry Pi](http://blog.alexellis.io/getting-started-with-docker-on-raspberry-pi/) has additional notes about create docker image and access GPIO.

## Install Docker 

### Option 1 - Install Docker as Addon to Jessie
- create a SD with Jessie (2017-04-10-raspbian-jessie.img) on it.
- [install docker](https://www.raspberrypi.org/blog/docker-comes-to-raspberry-pi/)    
`$ curl -sSL https://get.docker.com | sh`
- add current user, pi, to docker group to avoid type `sudo` each time.   
`$ sudo usermod -aG docker pi`.
- auto start      
`$ sudo systemctl enable docker`

```
pi@rpi-01:~ $ sudo systemctl enable docker
Synchronizing state for docker.service with sysvinit using update-rc.d...
Executing /usr/sbin/update-rc.d docker defaults
Executing /usr/sbin/update-rc.d docker enable
pi@rpi-01:~ $
```

* this gives use rpi with 
	* image 2017-04-10-raspbian-jessie.img
	* dynamic wifi (consider to move to static IP later)
	* docker
	
This requires installation of docker-machine and docker-compose separately. See procedures at the links below:     

* [docker end to end app](http://blog.alexellis.io/getting-started-with-docker-on-raspberry-pi/), this covers building OS images for ARM and GPIO applications.

### Option 2 - Install Hypriot (used here)
Hypriot provides a distribution, Hypriot, which has docker pre-installed. 

#### Reference 
* [Docker on ARM Raspberry Pi](https://www.slideshare.net/e2m/docker-on-arm-raspberry-pi)
* [[Guide] Installing Docker Swarm on HypriotOS](http://kubecloud.io/running-swarm-on-rpi-cluster/)

hostname.local does not work out of box. 

```
HypriotOS/armv7: pirate@rpi-m1 in ~
$ ping rpi-s2.local -c5
ping: unknown host rpi-s2.local
HypriotOS/armv7: pirate@rpi-m1 in ~
$ hostnamectl
   Static hostname: rpi-m1
         Icon name: computer
           Chassis: n/a
        Machine ID: 9989a26f06984d6dbadc01770f018e3b
           Boot ID: f1c4d9d1856343c3a15fcd68b3ad59bd
  Operating System: Raspbian GNU/Linux 8 (jessie)
            Kernel: Linux 4.4.50-hypriotos-v7+
      Architecture: arm
HypriotOS/armv7: pirate@rpi-m1 in ~
```
We need to install [mDNS service](https://www.howtogeek.com/167190/how-and-why-to-assign-the-.local-domain-to-your-raspberry-pi/) for example, `avahi-daemon`. There are other ways.

### Use the utility program `flash` to download image and copy to SD

There is an utility [flash](https://github.com/hypriot/flash) to simple the process of copying image and setup configuration.

* get image from [here](https://blog.hypriot.com/downloads/)
* default user “pirate” (password “hypriot”).
* create a config file: device-init.yaml as below; 

```
hostname: rpi-m1    <<--- modify this for each node
wifi:
  interfaces:
    wlan0:
      ssid: "<ACCESS-POINT-ID>"
      password: "<PASSWORD>"
```

* download and create a SD with device config file; modify hostname for each node.

`flash -c device-init.yaml https://github.com/hypriot/image-builder-rpi/releases/download/v1.4.0/hypriotos-rpi-v1.4.0.img.zip`

* or copy it by following instruction [here](https://medium.com/a-swift-misadventure/backing-up-your-raspberry-pi-sd-card-on-mac-the-simple-way-398a630f899c) to clone image, then change node name or just re-download with different node name in. 

```
➜  rpi2cluster git:(master) ✗ nmap -sP 192.168.1.0/24 | grep rpi-
Nmap scan report for rpi-s3 (192.168.1.81)
Nmap scan report for rpi-s2 (192.168.1.84)
Nmap scan report for rpi-s1 (192.168.1.86)
Nmap scan report for rpi-m1 (192.168.1.88)
```

* check docker installation.   

```
➜  rpi2cluster git:(master) ✗ ssh pirate@192.168.1.88
The authenticity of host '192.168.1.88 (192.168.1.88)' can't be established.
ECDSA key fingerprint is SHA256:CMQc15FF7V/t7N4hfcTmS+/xIuQ00xFlWYezymsUE18.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.1.88' (ECDSA) to the list of known hosts.
pirate@192.168.1.88's password:

HypriotOS (Debian GNU/Linux 8)

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker -v
Docker version 17.03.0-ce, build 60ccb22
HypriotOS/armv7: pirate@rpi-m1 in ~
```

check `docker-compose` and `docker-machine`

```
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker-compose -v
docker-compose version 1.11.2, build dfed245
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker-machine -v
docker-machine version 0.9.0, build 15fd4c7
HypriotOS/armv7: pirate@rpi-m1 in ~
```

swarm needs to be installed separately,

```
$ swarm  <<--- this is wrong command, use `docker swarm init`
-bash: swarm: command not found
HypriotOS/armv7: pirate@rpi-m1 in ~
```

There is bug for ping,
```
$ ping rpi-s1
ping: icmp open socket: Operation not permitted
HypriotOS/armv7: pirate@rpi-m1 in ~
$ ping 192.168.1.86
ping: icmp open socket: Operation not permitted
HypriotOS/armv7: pirate@rpi-m1 in ~
$ sudo chmod u+s /bin/ping
HypriotOS/armv7: pirate@rpi-m1 in ~
$ ping rpi-s1
PING rpi-s1 (192.168.1.86) 56(84) bytes of data.
64 bytes from rpi-s1 (192.168.1.86): icmp_seq=1 ttl=64 time=95.9 ms
64 bytes from rpi-s1 (192.168.1.86): icmp_seq=2 ttl=64 time=2.38 ms
64 bytes from rpi-s1 (192.168.1.86): icmp_seq=3 ttl=64 time=3.61 ms
64 bytes from rpi-s1 (192.168.1.86): icmp_seq=4 ttl=64 time=2.60 ms
^C
--- rpi-s1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3004ms
rtt min/avg/max/mdev = 2.381/26.147/95.991/40.327 ms
HypriotOS/armv7: pirate@rpi-m1 in ~
```

## Create SSH Keys
There is some error about cloning, see [here](http://stackoverflow.com/questions/32386975/cant-connect-to-github-via-ssh) for solution.

* delete the ssh entry in `~/.ssh/known_hosts` before `ssh` login the node.

`ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts`

```
HypriotOS/armv7: pirate@rpi-m1 in ~
$ ssh-keygen -t rsa -C "pirate@rpi-m1"
Generating public/private rsa key pair.
Enter file in which to save the key (/home/pirate/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/pirate/.ssh/id_rsa.
Your public key has been saved in /home/pirate/.ssh/id_rsa.pub.
The key fingerprint is:
c7:61:7a:96:68:2e:10:4e:08:3a:7f:f6:a6:63:4a:37 pirate@rpi-m1
The key's randomart image is:
+---[RSA 2048]----+
|.                |
|.. .             |
|o . o     o      |
| o o .   = o     |
|  . =   S *      |
|   o o o +       |
|  . E + .        |
| . .o+ .         |
|  .o..           |
+-----------------+
```
### Copy SSH Key of Master Node (rpi-m1) to Workers (rpi-s1, rpi-s2, rpi-s3) 

```
HypriotOS/armv7: pirate@rpi-m1 in ~
$ ssh-copy-id pirate@192.168.1.86
The authenticity of host '192.168.1.86 (192.168.1.86)' can't be established.
ECDSA key fingerprint is 3a:da:ef:3e:57:dd:dc:6a:44:8c:21:87:36:a6:5c:2b.
Are you sure you want to continue connecting (yes/no)? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
pirate@192.168.1.86's password:

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'pirate@192.168.1.86'"
and check to make sure that only the key(s) you wanted were added.
$
```
repeat it for rpi-s2, rpi-s3

### Test SSH Key

```
HypriotOS/armv7: pirate@rpi-m1 in ~
$ ssh pirate@192.168.1.86

HypriotOS (Debian GNU/Linux 8)

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Tue May 16 20:36:41 2017 from waterlily
HypriotOS/armv7: pirate@rpi-s1 in ~
```
Works.

## Create Docker Swarm Manager

### Reference

[Docker Swarm Cheatsheet-1](http://blog.programster.org/docker-swarm-cheatsheet/)  
[Docker Swarm Cheatsheet-2](https://www.docker.com/sites/default/files/Docker_CheatSheet_08.09.2016_0.pdf)  
[docker-machine](https://docs.docker.com/machine/get-started/#use-machine-to-run-docker-containers) can be cloud or local VM.
[Getting started with swarm mode](https://docs.docker.com/engine/swarm/swarm-tutorial/)  
[How to Create a Cluster of Docker Containers with Docker Swarm and DigitalOcean on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-create-a-cluster-of-docker-containers-with-docker-swarm-and-digitalocean-on-ubuntu-16-04)

### Architecture

![docker-swarm architecture - 1](https://i.stack.imgur.com/QBvhX.png)
![docker-swarm architecture - 2](https://image.slidesharecdn.com/dockerswarmv1-150401123157-conversion-gate01/95/docker-swarm-introduction-13-638.jpg?cb=1427891574)

### Features
[highlights](https://docs.docker.com/engine/swarm/#feature-highlights)

* Cluster management
* Declarative service model: Docker Engine uses a declarative approach to let you define the desired state of the various services in your application stack.  
* Scaling; task can be consider like POTs in Kubernetes.
* Maintain desired state via reconciliation.
* Multi-host networking: You can specify an overlay network for your services. 
* Service discovery: Swarm manager nodes assign each service in the swarm a unique DNS name and load balances running containers. 
* Load balancing: You can expose the ports for services to an external load balancer. 
* Secure by default.
* Rolling updates the service.

### UML

![docker-swarm UML](https://pbs.twimg.com/media/CEsJtdNUsAECNY5.png:large)

### Initialize the Swarm Manager at Master Node

```
$ clear
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker swarm init
Swarm initialized: current node (g4vy8ewdl9ci8ct0lheqpxjbg) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join \
    --token SWMTKN-1-0obaaqul2si12iu0mxlxwmoa0ig1frdsnjtyalpxnk7clp434e-9l9sx9idajcloasfdw4a01g2y \
    192.168.1.88:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

HypriotOS/armv7: pirate@rpi-m1 in ~
```

### Add 3 Worker Nodes to Join Swarm

```
HypriotOS/armv7: pirate@rpi-s1 in ~
$ docker swarm join \
>     --token SWMTKN-1-0obaaqul2si12iu0mxlxwmoa0ig1frdsnjtyalpxnk7clp434e-9l9sx9idajcloasfdw4a01g2y \
>     192.168.1.88:2377
This node joined a swarm as a worker.
HypriotOS/armv7: pirate@rpi-s1 in ~
$
```

### Review Swarm Info

```
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker info
Containers: 4
 Running: 0
 Paused: 0
 Stopped: 4
Images: 17
Server Version: 17.03.0-ce
Storage Driver: overlay2
 Backing Filesystem: extfs
 Supports d_type: true
 Native Overlay Diff: true
Logging Driver: json-file
Cgroup Driver: cgroupfs
Plugins:
 Volume: local
 Network: bridge host macvlan null overlay
Swarm: active  <<-------------
 NodeID: g4vy8ewdl9ci8ct0lheqpxjbg
 Is Manager: true
 ClusterID: pyrvg5qzok221w7pfzetgcoxl
 Managers: 1
 Nodes: 4
 Orchestration:
  Task History Retention Limit: 5
 Raft:
  Snapshot Interval: 10000
  Number of Old Snapshots to Retain: 0
  Heartbeat Tick: 1
  Election Tick: 3
 Dispatcher:
  Heartbeat Period: 5 seconds
 CA Configuration:
  Expiry Duration: 3 months
 Node Address: 192.168.1.88
 Manager Addresses:
  192.168.1.88:2377
Runtimes: runc
Default Runtime: runc
Init Binary: docker-init
containerd version: 977c511eda0925a723debdc94d09459af49d082a
runc version: a01dafd48bc1c7cc12bdb01206f9fea7dd6feb70
init version: 949e6fa
Kernel Version: 4.4.50-hypriotos-v7+
Operating System: Raspbian GNU/Linux 8 (jessie)
OSType: linux
Architecture: armv7l
CPUs: 4
Total Memory: 861.9 MiB
Name: rpi-m1
ID: ZGHJ:GLKM:QIHZ:QKIZ:ZQAG:T7VW:STPB:3JX7:ESHQ:Y2ZQ:UDPA:NCRD
Docker Root Dir: /var/lib/docker
Debug Mode (client): false
Debug Mode (server): false
Registry: https://index.docker.io/v1/
Experimental: false
Insecure Registries:
 127.0.0.0/8
Live Restore Enabled: false
HypriotOS/armv7: pirate@rpi-m1 in ~
$
```
### List of Nodes

```
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker node ls
ID                           HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
g4vy8ewdl9ci8ct0lheqpxjbg *  rpi-m1    Ready   Active        Leader
u5oktv61epxq0jui2oq1iaytj    rpi-s2    Ready   Active
y7umdundbo2zm5cljz1wd708i    rpi-s3    Ready   Active
ywf90mm103qd28r6a0upldtu1    rpi-s1    Ready   Active
HypriotOS/armv7: pirate@rpi-m1 in ~
```

### Running Services in the Docker Swarm
No service yet.

```
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker node ps
ID  NAME  IMAGE  NODE  DESIRED STATE  CURRENT STATE  ERROR  PORTS
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker service ls
ID  NAME  MODE  REPLICAS  IMAGE
HypriotOS/armv7: pirate@rpi-m1 in ~
$
```

Deploy it.

```
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker service create -p 80:80 --name webserver nginx
0eyzq92p6oduhcu56arphi23o
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker node ps
ID            NAME         IMAGE         NODE    DESIRED STATE  CURRENT STATE             ERROR  PORTS
vy1gymsrar89  webserver.1  nginx:latest  rpi-m1  Running        Preparing 26 seconds ago
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker service ls
ID            NAME       MODE        REPLICAS  IMAGE
0eyzq92p6odu  webserver  replicated  0/1       nginx:latest
HypriotOS/armv7: pirate@rpi-m1 in ~
```


```
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker service ls
ID  NAME  MODE  REPLICAS  IMAGE
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
647353628c83        bridge              bridge              local
698f31954f63        docker_gwbridge     bridge              local
ce2a385643c4        host                host                local
ifah9kmkvht2        ingress             overlay             swarm
a2800c300829        none                null                local
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker network create \
> --driver overlay \
> --subnet 10.10.1.0/24 \
> --opt encrypted \
> services
e3npyw8gejcyr5dkijqoyqwkp
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
647353628c83        bridge              bridge              local
698f31954f63        docker_gwbridge     bridge              local
ce2a385643c4        host                host                local
ifah9kmkvht2        ingress             overlay             swarm
a2800c300829        none                null                local
e3npyw8gejcy        services            overlay             swarm
HypriotOS/armv7: pirate@rpi-m1 in ~
```
why the service is not running??

```
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker service create \
> --replicas 2 \
> --name nginx \
> --network services \
> --publish 80:80 \
> nginx
y50id9yg99z3ehada3mhgga1b
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker service ls
ID            NAME   MODE        REPLICAS  IMAGE
y50id9yg99z3  nginx  replicated  0/2       nginx:latest
HypriotOS/armv7: pirate@rpi-m1 in ~
```

do it again.
```
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker node ls
ID                           HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
g4vy8ewdl9ci8ct0lheqpxjbg *  rpi-m1    Ready   Active        Leader
nduvj0l8h30jl5kgq53bdwjzh    rpi-s3    Ready   Active
qa44ke9lu72ixaw2b57h4y4y8    rpi-s2    Ready   Active
ywf90mm103qd28r6a0upldtu1    rpi-s1    Ready   Active
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker service ls
ID  NAME  MODE  REPLICAS  IMAGE
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker service create -p 80:80 --name web --replicas 2 nginx
ttsu5t4sml6496gedsvi5b0wk
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker service ls
ID            NAME  MODE        REPLICAS  IMAGE
ttsu5t4sml64  web   replicated  0/2       nginx:latest
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker service create --name ping hypriot/rpi-alpine-scratch ping 8.8.8.8
r25uzlw259zs9bivutju7h75c
HypriotOS/armv7: pirate@rpi-m1 in ~
```
Service is running at rpi-s2.

```
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker service ls
ID            NAME  MODE        REPLICAS  IMAGE
r25uzlw259zs  ping  replicated  1/1       hypriot/rpi-alpine-scratch:latest
ttsu5t4sml64  web   replicated  0/2       nginx:latest
HypriotOS/armv7: pirate@rpi-m1 in ~
$
```

```
HypriotOS/armv7: pirate@rpi-s2 in ~
$ docker ps
CONTAINER ID        IMAGE                                                                                                COMMAND             CREATED             STATUS              PORTS               NAMES
4b22f39ebc1f        hypriot/rpi-alpine-scratch@sha256:708171e6a1bd7c60a0ec9a5657900ada854bf14623be053f5865f918e0e2691c   "ping 8.8.8.8"      12 minutes ago      Up 12 minutes                           ping.1.iisxbwpgk25s1efw1a3195zcj
HypriotOS/armv7: pirate@rpi-s2 in ~
```

It is no at rpi-s3 or rpi-s1.
scale up to 3;

```
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker service update --replicas 3 ping
ping
HypriotOS/armv7: pirate@rpi-m1 in ~
$ docker service ls
ID            NAME  MODE        REPLICAS  IMAGE
r25uzlw259zs  ping  replicated  1/3       hypriot/rpi-alpine-scratch:latest
ttsu5t4sml64  web   replicated  0/2       nginx:latest
HypriotOS/armv7: pirate@rpi-m1 in ~
$
```
still has problem, try [ping service](https://medium.com/@bossjones/how-i-setup-a-raspberry-pi-3-cluster-using-the-new-docker-swarm-mode-in-29-minutes-aa0e4f3b1768)

```
HypriotOS/armv7: pirate@rpi-s2 in ~
$ docker ps
CONTAINER ID        IMAGE                                                                                                COMMAND             CREATED             STATUS              PORTS               NAMES
4b22f39ebc1f        hypriot/rpi-alpine-scratch@sha256:708171e6a1bd7c60a0ec9a5657900ada854bf14623be053f5865f918e0e2691c   "ping 8.8.8.8"      22 minutes ago      Up 22 minutes                           ping.1.iisxbwpgk25s1efw1a3195zcj
HypriotOS/armv7: pirate@rpi-s2 in ~
$
```

## Monitoring
* [Visualize your Raspberry Pi containers with Portainer or UI for Docker](https://blog.hypriot.com/post/new-docker-ui-portainer/)
* [Deploying an IoT Swarm with Docker Machine](https://blog.hypriot.com/post/deploy-swarm-on-chip-with-docker-machine/)


## Use Docker
[use Docker](http://blog.alexellis.io/getting-started-with-docker-on-raspberry-pi/)

### Create a test Docker image


#### Create a dockerfile
```
➜  rpi2cluster git:(master) ✗ nano Dockerfile
```
add following script to file:

```
FROM resin/rpi-raspbian:latest
ENTRYPOINT []

RUN apt-get update && \
    apt-get -qy install curl ca-certificates

CMD ["curl", "https://docker.com"]
```
save and exit editor.

#### Build image

```
➜  rpi2cluster git:(master) ✗ docker build -t curl_docker .
Sending build context to Docker daemon  1.136MB
Step 1/4 : FROM resin/rpi-raspbian:latest
latest: Pulling from resin/rpi-raspbian
9db3fbbea6c1: Pull complete
50527cfe3f1f: Pull complete
... clip ...
Step 4/4 : CMD curl https://docker.com
 ---> Running in 5c5c16d3b037
 ---> e9a68d8061f7
Removing intermediate container 5c5c16d3b037
Successfully built e9a68d8061f7
Successfully tagged curl_docker:latest
```
The image can be found in image repo.

```
➜  rpi2cluster git:(master) ✗ docker images
REPOSITORY                    TAG                 IMAGE ID            CREATED             SIZE
curl_docker                   latest              e9a68d8061f7        56 seconds ago      138MB
resin/rpi-raspbian            latest              aa1d2f443aa9        40 hours ago        122MB
portainer/portainer           latest              89883cee365b        7 weeks ago         9.96MB
kitematic/hello-world-nginx   latest              03b4557ad7b9        23 months ago       7.91MB
➜  rpi2cluster git:(master) ✗
```
when we run the container, it does not produce any output.

```
➜  rpi2cluster git:(master) ✗ docker run curl_docker
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:02 --:--:--     0
```
edit Dockerfile, change `CMD ["curl", "https://docker.com"]` to `CMD ["curl", "https://www.docker.com"]` and re-build.
works.

### Push to dockerhub

tag the image and push it to dockerhub.

```
➜  rpi2cluster git:(master) ✗ docker tag curl_docker rkuo/curl_docker:first
➜  rpi2cluster git:(master) ✗ docker push rkuo/curl_docker:first
The push refers to a repository [docker.io/rkuo/curl_docker]
f2dd0fa70f50: Pushed
87e4cab2b6c9: Mounted from resin/rpi-raspbian
13e86b166052: Mounted from resin/rpi-raspbian
91803b35897b: Mounted from resin/rpi-raspbian
0a4054d140f4: Mounted from resin/rpi-raspbian
bab354dffa8f: Mounted from resin/rpi-raspbian
eddeb391e435: Mounted from resin/rpi-raspbian
46ef2f4c0b3b: Mounted from resin/rpi-raspbian
2c7c0f4569cb: Mounted from resin/rpi-raspbian
first: digest: sha256:0adbee9545bcde63a1ee99bc6f9da36d0502830ffd3b19128e3a9a33740be768 size: 2191
➜  rpi2cluster git:(master) ✗
```

verify the existance

![dockerhub](https://www.evernote.com/l/AS7sfngzQyhNZ4dbsUn8pKcJa_9wQnZTKysB/image.png)

It does not work. 
Try to make commit first before push.

```
➜  rpi2cluster git:(master) ✗ docker commit 603e39830290 rkuo/curl_docker:latest
sha256:1b8b178243d20b9834368b0180e9d59cb8957fe99a284bc3558828c51c6abedc
➜  rpi2cluster git:(master) ✗
```

push it again

```
➜  rpi2cluster git:(master) ✗ docker push rkuo/curl_docker:latest
The push refers to a repository [docker.io/rkuo/curl_docker]
f2dd0fa70f50: Layer already exists
87e4cab2b6c9: Layer already exists
13e86b166052: Layer already exists
91803b35897b: Layer already exists
0a4054d140f4: Layer already exists
bab354dffa8f: Layer already exists
eddeb391e435: Layer already exists
46ef2f4c0b3b: Layer already exists
2c7c0f4569cb: Layer already exists
latest: digest: sha256:70fcff2f6b94f8c22b88ab6e42a7bcb25e2f843654adc52428ee5d2166c53aa4 size: 2191
```

try to run it again in development, works. then m1 node,works.

```
$ docker run rkuo/curl_docker
Unable to find image 'rkuo/curl_docker:latest' locally
latest: Pulling from rkuo/curl_docker
9db3fbbea6c1: Pull complete
50527cfe3f1f: Pull complete
2e7952f5c36f: Pull complete
e88c3fa55783: Pull complete
57bff5132eab: Pull complete
8ede50ef16eb: Pull complete
77c630334981: Pull complete
e766c16523c1: Pull complete
d0685a87f457: Pull complete
Digest: sha256:70fcff2f6b94f8c22b88ab6e42a7bcb25e2f843654adc52428ee5d2166c53aa4
Status: Downloaded newer image for rkuo/curl_docker:latest
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:01 --:--:--     0<!doctype html>
<html class="no-js" lang="en">
<head>
        ... clip ...
```

## Physical IO

* [Let's get physical with Docker on the Raspberry Pi](https://blog.hypriot.com/post/lets-get-physical/)
* [Wiring Pi - GPIO Interface library for the Raspberry Pi](http://wiringpi.com/)

### Create a Node.js application

edit Dockerfile

```
FROM resin/rpi-raspbian:latest  
ENTRYPOINT []

RUN apt-get update && \  
    apt-get -qy install curl \
                build-essential python \
                ca-certificates
WORKDIR /root/  
RUN curl -O \  
  https://nodejs.org/dist/v4.5.0/node-v4.5.0-linux-armv6l.tar.gz
RUN tar -xvf node-*.tar.gz -C /usr/local \  
  --strip-components=1

CMD ["node"]  
```

build image

```
➜  rpi2cluster git:(master) ✗ docker build -t node:arm .
Sending build context to Docker daemon  1.141MB
Step 1/7 : FROM resin/rpi-raspbian:latest
... clip ...
Removing intermediate container 14640f423571
Step 7/7 : CMD node
 ---> Running in 0e740fe200c0
 ---> 2cdcd91d8ec3
Removing intermediate container 0e740fe200c0
Successfully built 2cdcd91d8ec3
Successfully tagged node:arm
➜  rpi2cluster git:(master) ✗
```

run

```
➜  rpi2cluster git:(master) ✗  docker run -ti node:arm
> console.log('hello')
hello
undefined
>
```
ctrl-d to exit Node.

➜  `rpi2cluster git:(master) ✗ docker run -ti node:arm`

```
> process.version  
'v4.5.0'  
> var fs = require('fs');  
undefined
> console.log(fs.readFileSync("/etc/hosts", "utf8"));
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::0	ip6-localnet
ff00::0	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
172.17.0.2	b631ec6ba0e2
undefined
> process.exit()
➜  rpi2cluster git:(master) ✗
```

### Create an Raspberry Pi app
* the container needs to set privilage mode to use gpio
* need to import gpio library.

compose a Dockfile with gpio lobrary installed

```
➜  rpi2cluster git:(master) ✗ cat Dockerfile
FROM resin/rpi-raspbian:latest
ENTRYPOINT []

RUN apt-get -q update && \
    apt-get -qy install \
        python python-pip \
        python-dev python-pip gcc make

RUN pip install rpi.gpio
```

build container

```
➜  rpi2cluster git:(master) ✗ docker build -t gpio-base .
Sending build context to Docker daemon  1.144MB
Step 1/4 : FROM resin/rpi-raspbian:latest
 ---> aa1d2f443aa9
Step 2/4 : ENTRYPOINT
... snip ...

rmv6l-2.7/source/soft_pwm.o build/temp.linux-armv6l-2.7/source/py_pwm.o build/temp.linux-armv6l-2.7/source/common.o build/temp.linux-armv6l-2.7/source/constants.o -o build/lib.linux-armv6l-2.7/RPi/_GPIO.so

Successfully installed rpi.gpio
Cleaning up...
 ---> bf8e92212635
Removing intermediate container 8c4aa077c690
Successfully built bf8e92212635
Successfully tagged gpio-base:latest 
```

#### Wiring

wire sensor or actuator to breadboard.

##### Reference 
[compare gpio 26 vs 40](http://www.raspberrypi-spy.co.uk/2012/06/simple-guide-to-the-rpi-gpio-header-and-pins/).   
[The comprehensive GPIO Pinout guide for the Raspberry Pi](https://pinout.xyz/) with good interactive description.

![gpio-40 pins](https://pihw.files.wordpress.com/2016/01/rpigpiopinout.png?w=614)  

```   
import RPi.GPIO as GPIO  
import time  
GPIO.setmode(GPIO.BCM)  
led_pin = 11  
GPIO.setup(led_pin, GPIO.OUT)

while(True):  
    GPIO.output(led_pin, GPIO.HIGH)
    time.sleep(1)
    GPIO.output(led_pin, GPIO.LOW)
    time.sleep(1)
```   




## Summary 
put architecture diagram here.????

## Miscellanous

### Cheat Sheet

![cheat sheet 1](https://www.evernote.com/l/AS5_8xx_2HlA1r-7RhP1i1m7qPxDrYruGH8B/image.png)

### CLI

swarm init
swarm join
service create
service inspect
service ls
service rm
service scale
service ps
service update



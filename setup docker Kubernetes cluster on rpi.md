

[toc]

## Install Kubernetes

See more detail, [Running Docker on ARM](https://pt.slideshare.net/DieterReuter/running-docker-on-arm) has good summary for both methods. 
[installation](https://blog.hypriot.com/post/setup-kubernetes-raspberry-pi-cluster/)

* [Setup Kubernetes on a Raspberry Pi Cluster easily the official way!](https://blog.hypriot.com/post/setup-kubernetes-raspberry-pi-cluster/) <<--- follow this 20170522
* [Cluster computing on the Raspberry Pi with Kubernetes](https://opensource.com/life/16/2/build-a-kubernetes-cloud-with-raspberry-pi)


* Clone this repository on your Pi

```
$ git clone git@github.com:Project31/kubernetes-installer-rpi.git
$ cd ./kubernetes-installer-rpi
```
* Install a master `build-master.sh` script

```
$ ./build-master.sh
```

* On a different RPi install a node `build-node.sh` script

## UML
![UML](https://www.evernote.com/l/AS4G2HX7TA5Gc4BM0tB4CO9axkcNqB6FHisB/image.png)

from [here](https://beroux.com/english/articles/kubernetes/?part=2)


## Monitoring
* [Visualize your Raspberry Pi containers with Portainer or UI for Docker](https://blog.hypriot.com/post/new-docker-ui-portainer/)
* [Deploying an IoT Swarm with Docker Machine](https://blog.hypriot.com/post/deploy-swarm-on-chip-with-docker-machine/)

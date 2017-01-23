#!/bin/sh

sed -i "s:.*INSECURE_REGISTRY='--insecure-registry':INSECURE_REGISTRY='--insecure-registry 172.30.0.0/16':g" /etc/sysconfig/docker

systemctl restart docker

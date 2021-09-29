#!/bin/bash
url=registry.cn-hangzhou.aliyuncs.com/google_containers
version=v1.21.4
images=(`kubeadm config images list --kubernetes-version=$version|awk -F '/' '{print $2}'`)
for imagename in ${images[@]} ; do
  docker pull $url/$imagename
  docker tag $url/$imagename k8s.gcr.io/$imagename
  docker rmi -f $url/$imagename
done

docker pull v5cn/coredns:v1.8.0
docker tag v5cn/coredns:v1.8.0 k8s.gcr.io/coredns/coredns:v1.8.0
docker rmi v5cn/coredns:v1.8.0
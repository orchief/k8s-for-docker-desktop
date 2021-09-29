# 卸载原docker
systemctl stop docker

yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine

rm -rf /etc/systemd/system/docker.service.d
rm -rf /var/lib/docker
rm -rf /var/run/docker

yum install -y yum-utils   device-mapper-persistent-data   lvm2

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

yum install docker-ce-20.10.8 docker-ce-cli-20.10.8 containerd.io

systemctl start docker
systemctl enable docker

yum -y install bash-completion

source /etc/profile.d/bash_completion.sh
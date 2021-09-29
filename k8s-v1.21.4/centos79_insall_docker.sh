# 安装docker 版本 Docker version 20.10.8

# 1. 卸载原docker
systemctl stop docker
yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
rm -rf /etc/systemd/system/docker.service.d
rm -rf /var/lib/docker
rm -rf /var/run/docker

# 2. 安装docker
yum install -y yum-utils   device-mapper-persistent-data   lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce-20.10.8 docker-ce-cli-20.10.8 containerd.io
systemctl start docker
systemctl enable docker

# 配置好互联网出口 具体需要配置的域名如下
# https://docker.mirrors.ustc.edu.cn

cd /etc/docker

tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

systemctl daemon-reload
systemctl restart docker
docker run hello-world

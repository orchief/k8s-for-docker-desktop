# 配置好互联网出口 具体需要配置的域名如下
# https://docker.mirrors.ustc.edu.cn

# 已经安装完毕docker 版本 Docker version 20.10.8

systemctl enable docker
# 配置docker
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

# 注意是node
hostnamectl set-hostname node03
more /etc/hostname

# 配置host具体按照实际情况
cat >> /etc/hosts << EOF
172.31.162.110    master
172.31.162.101    node01
172.31.162.100    node02
172.31.162.95     node03
172.31.162.94     node04
172.31.162.93     node05
172.31.162.104    node06
172.31.162.103    node07
EOF

swapoff -a
sed -i.bak '/swap/s/^/#/' /etc/fstab

cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl -p /etc/sysctl.d/k8s.conf

#修改daemon.json，新增‘"exec-opts": ["native.cgroupdriver=systemd"’
# more /etc/docker/daemon.json 
# {
#   "registry-mirrors": ["https://v16stybc.mirror.aliyuncs.com"],
#   "exec-opts": ["native.cgroupdriver=systemd"]
# }

# systemctl daemon-reload
# systemctl restart docker

# 设置kubernetes源
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

#更新缓存
yum clean all
yum -y makecache
yum list kubelet --showduplicates | sort -r 

#  安装kubelet、kubeadm和kubectl
yum install -y kubelet-1.21.4 kubeadm-1.21.4 kubectl-1.21.4

# 启动kubelet并设置开机启动
systemctl enable kubelet && systemctl start kubelet

#  kubelet命令补全
# cd 
# echo "source <(kubectl completion bash)" >> ~/.bash_profile
# source .bash_profile 



# 加入master

kubeadm join 172.31.162.110:6443 --token wgbcvp.lzzldh3cvyfymp2a  --discovery-token-ca-cert-hash sha256:24af0f5e2fa20b8a62182a4e514ce3c2924c4e453f7e2ccd33493b6b99281d08

# 配置好互联网出口 具体需要配置的域名如下
# https://docker.mirrors.ustc.edu.cn

# 已经安装完毕docker 版本 Docker version 20.10.8

# 配置docker
cd /etc/docker

tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
}
EOF

systemctl daemon-reload
systemctl restart docker
docker run hello-world

hostnamectl set-hostname master
more /etc/hostname

# 配置host具体按照实际情况
cat >> /etc/hosts << EOF
172.31.162.110    master
172.31.162.101    node01
172.31.162.100    node02
172.31.162.95     node03
EOF

172.31.162.110    
172.31.162.101    
172.31.162.100    
172.31.162.95     

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

systemctl daemon-reload
systemctl restart docker

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
cd 
echo "source <(kubectl completion bash)" >> ~/.bash_profile
source .bash_profile 

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

kubeadm init --kubernetes-version=1.21.4 --apiserver-advertise-address 172.31.162.110 --pod-network-cidr=10.244.0.0/16

# 加载环境变量
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
source .bash_profile

# 安装pod网络
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# 添加node

# 查看令牌
kubeadm token list

# 生成新的令牌
kubeadm token create

openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
   openssl dgst -sha256 -hex | sed 's/^.* //'

# To start using your cluster, you need to run the following as a regular user:

#   mkdir -p $HOME/.kube
#   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#   sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Alternatively, if you are the root user, you can run:

#   export KUBECONFIG=/etc/kubernetes/admin.conf

# You should now deploy a pod network to the cluster.
# Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
#   https://kubernetes.io/docs/concepts/cluster-administration/addons/

# Then you can join any number of worker nodes by running the following on each as root:

# kubeadm join 172.31.162.110:6443 --token 7j33r0.hvjlvkzhlpuqi4yf \
#         --discovery-token-ca-cert-hash sha256:24af0f5e2fa20b8a62182a4e514ce3c2924c4e453f7e2ccd33493b6b99281d08 

# dashboard安装

wget  https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.4/aio/deploy/recommended.yaml kubernetes-dashboard.yaml


cat >> kubernetes-dashboard.yaml << EOF
---
# ------------------- dashboard-admin ------------------- #
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard-admin
  namespace: kube-system

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: dashboard-admin
subjects:
- kind: ServiceAccount
  name: dashboard-admin
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
EOF

kubectl apply -f kubernetes-dashboard.yaml 

kubectl get deployment kubernetes-dashboard -n kube-system
kubectl get pods -n kube-system -o wide
kubectl get services -n kube-system
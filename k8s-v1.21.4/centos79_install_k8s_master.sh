# 需要根据实际机器修改
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

# 运行镜像拉取脚本
./image.sh

kubeadm init --kubernetes-version=1.21.4 --apiserver-advertise-address 172.31.162.110 --pod-network-cidr=10.244.0.0/16

# 加载环境变量
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
source .bash_profile

# 安装pod网络
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# 添加node

# 查看令牌
kubeadm token list

# 生成新的token
kubeadm token create

# 令牌
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'

kubectl apply -f kubernetes-dashboard.yaml 

kubectl get deployment kubernetes-dashboard -n kube-system
kubectl get pods -n kube-system -o wide
kubectl get services -n kube-system
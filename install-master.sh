#!/bin/bash

echo "Enter cluster IP or DNS hostname: "
read cluter_k8s
swapoff -a
echo "ATENTION! Please coment the line about swap, to kubelet work properly!"
echo "PRESS ENTER to enter in fstab file"
vi /etc/fstab
apt update -y && apt upgrade -y
curl -fsSL https://get.docker.com/ | bash

cat > /etc/docker/daemon.json << EOF
{
	"exec-opts": ["native.cgroupdriver=systemd"],
	"log-driver": "json-file",
	"log-opts": {
		"max-size": "100m"
	},
	"storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker

cat > /etc/modules-load.d/k8s.conf <<EOF
br_netfilter
ip_vs
ip_vs_rr
ip_vs_sh
ip_vs_wrr
nf_conntrack_ipv4
overlay
EOF

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward =
EOF

sysctl --system
apt update -y && apt upgrade -y

# CONTAINERD
### Adding repo key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - 

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update

## Installing containerd
sudo apt install -y containerd.io

## Configuring containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

## Enable and restart service
systemctl enable containerd
systemctl restart containerd

# Installing K8S tools
apt update && apt install -y apt-transport-https gnupg2
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
	echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
	apt update
	apt install -y kubelet kubeadm kubectl
	kubectl completion bash > /etc/bash_completion.d/kubectl
	kubeadm completion bash > /etc/bash_completion.d/kubeadm

# K8S

kubeadm config images pull --cri-socket /run/containerd/containerd.sock
kubeadm init --upload-certs --control-plane-endpoint=$cluter_k8s --cri-socket /run/containerd/containerd.sock

#Show kubeadm join again
kubeadm token create --print-join-command
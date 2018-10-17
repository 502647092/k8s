master='k8s-node1'
declare -A hosts=(                                                                                                                                   
["k8s-node1"]='192.168.2.101'
["k8s-node2"]='192.168.2.102'
["k8s-node3"]='192.168.2.103'
["k8s-node4"]='192.168.2.104'
)                                                                                                                                                    
for host in ${!hosts[*]}; do
  ip=${hosts[${host}]}
  echo "开始安装 ${host} IP地址 ${ip} ..."

  echo "初始化基础环境 同步时间.."
  ssh -Tq ${ip}<<EOF
cat > /etc/resolv.conf<<END
# Generated by NetworkManager
nameserver 119.29.29.29
END
yum install -y wget
wget -qO- https://blog.yumc.pw/attachment/script/shell/base.sh | bash
EOF

  echo "关闭防火墙和Swap分区..."
  ssh -Tq ${ip}<<EOF
systemctl stop firewalld.service
systemctl disable firewalld.service
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab
EOF

  echo "使用DockerMachine安装Docker..."
  docker-machine rm ${host} -f
  docker-machine --debug create --driver generic --generic-ip-address=${ip} ${host}

  echo "开始拉取基础镜像..."
  ssh -Tq ${ip}<<EOF
curl -qs https://raw.githubusercontent.com/502647092/k8s/master/pull_from_sixi.sh | bash
EOF

  echo "开始安装 Kubeadm ..."
  ssh -Tq ${ip}<<EOF
cat > /etc/yum.repos.d/kubernetes.repo<<END
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
END
yum install -y -q kubeadm
EOF
  if [[ "${host}" == "${master}" ]]; then
  echo "开始初始化主节点..."
  ssh -Tq ${ip}<<EOF
cat > kubeadm.yml<<END
apiVersion: kubeadm.k8s.io/v1alpha3
kind: ClusterConfiguration
imageRepository: k8s.gcr.io
kubernetesVersion: v1.12.0
apiServerExtraArgs:
  runtime-config: api/all=true
controllerManagerExtraArgs:
  horizontal-pod-autoscaler-sync-period: 10s
  horizontal-pod-autoscaler-use-rest-clients: "true"
  node-monitor-grace-period: 10s
END
kubeadm init --config kubeadm.yml
EOF
  fi

  echo "设置 Kubelet 为开机自启动..."
  ssh -Tq ${ip}<<EOF
systemctl enable kubelet.service
systemctl start kubelet.service
EOF

done

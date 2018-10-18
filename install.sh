# 使用前需要将主节点和各个从节点配置SSH互通 包括主节点自身
# 不知道的就按照这个步骤
# ssh-keygen 一直按回车
# 复制密钥 IP自己改
# ssh-copy-id root@192.168.2.101 回车后输入密码

# 主节点的名称
master='k8s-node1'
# 集群IP和Host
hosts=(
'k8s-node1:192.168.25.101'
'k8s-node2:192.168.25.102'
'k8s-node3:192.168.25.103'
)
# Kubernetes版本
KUBE_VERSION='v1.12.1'

install_docker_machine() {
  if [ -z "$(which docker-machine | grep which)" ]; then
    yum install -y wget
    wget -qO- https://blog.yumc.pw/attachment/script/shell/docker/machine.sh | bash
  fi
}

init_base_env() {
  local ip=$1
  echo "Install Base Env Sync Time.."
  ssh -Tq ${ip}<<EOF
cat > /etc/resolv.conf<<END
nameserver 119.29.29.29
END
yum install -y wget
wget -qO- https://blog.yumc.pw/attachment/script/shell/base.sh | bash
EOF
}

set_firewalld_and_swap() {
  local ip=$1
  echo "Stop & Disable Firewalld And Close Swap..."
  ssh -Tq ${ip}<<EOF
systemctl stop firewalld.service
systemctl disable firewalld.service
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab
EOF
}

set_kernel_config() {
  local ip=$1
  echo "Config kernel Param Enable ipvs..."
  ssh -Tq ${ip}<<EOF
echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
echo net.bridge.bridge-nf-call-iptables=1 >> /etc/sysctl.conf
echo net.bridge.bridge-nf-call-ip6tables=1 >> /etc/sysctl.conf
sysctl -p
models='ip_vs ip_vs_rr ip_vs_wrr ip_vs_sh'
for model in \${models} ; do
  modprobe \${model}
done
EOF
}

install_docker_form_yum() {
  local ip=${1}
  ssh -Tq ${ip}<<EOF
cat > /etc/yum.repos.d/CentOS-Base.repo<<END
# CentOS-Base.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the 
# remarked out baseurl= line instead.
#
#
[base]
name=CentOS-$releasever - Base - 163.com
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os
baseurl=http://mirrors.163.com/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=http://mirrors.163.com/centos/RPM-GPG-KEY-CentOS-7

#released updates
[updates]
name=CentOS-$releasever - Updates - 163.com
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates
baseurl=http://mirrors.163.com/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=http://mirrors.163.com/centos/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras - 163.com
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras
baseurl=http://mirrors.163.com/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=http://mirrors.163.com/centos/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus - 163.com
baseurl=http://mirrors.163.com/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=http://mirrors.163.com/centos/RPM-GPG-KEY-CentOS-7
END
yum install -y docker
EOF
}

install_docker_with_docker_machine() {
  local host=$1
  local ip=$2
  echo "Use Docker Machine Install Docker On Node ${host} IP: ${ip} ..."
  docker-machine rm ${host} -f
  docker-machine --debug create --driver generic --generic-ip-address=${ip} ${host}
}

pull_require_images_from_sixi_registry() {
  local ip=${1}
  echo "Pull Image From Sixi Registry..."
  ssh -Tq ${ip}<<EOF
curl -qs https://raw.githubusercontent.com/502647092/k8s/master/pull_from_sixi.sh | bash
EOF
}

install_kubeadm() {
  local ip=${1}
  echo "Install Kubeadm ..."
  ssh -Tq ${ip}<<EOF
if [ -z "\$(which kubeadm | grep which)" ]; then
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
fi
EOF
}

enable_kubelet() {
  echo "Enable Kubelet StartUp..."
  ssh -Tq ${ip}<<EOF
systemctl enable kubelet.service
systemctl start kubelet.service
EOF
}

init_master() {
  local ip=${1}
  echo "Init Master Node IP: ${ip} ..."
  cat > kubeadm.yml<<END
apiVersion: kubeadm.k8s.io/v1alpha3
kind: ClusterConfiguration
imageRepository: k8s.gcr.io
kubernetesVersion: ${KUBE_VERSION}
controlPlaneEndpoint: '${ip}'
apiServerExtraArgs:
  runtime-config: api/all=true
controllerManagerExtraArgs:
  horizontal-pod-autoscaler-sync-period: 10s
  horizontal-pod-autoscaler-use-rest-clients: "true"
  node-monitor-grace-period: 10s
END
  kubeadm init --config kubeadm.yml
  mkdir -p $HOME/.kube
  sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

init_slave() {
  local ip=${1}
  local token=$(kubeadm token list | grep token | awk '{print $1}')
  echo "Init Slave Node>> Master NodeIP: ${ip} Token: ${token}..."
  if [ -z "${ip}" ]; then
    echo "Master NodeIP is Empty!! exit..."
    exit 0
  fi
  if [ -z "${token}" ]; then
    echo "Master Token is empty Please init Master Node First!!! exit..."
    exit 0;
  fi
  run_command_on_slave_node "kubeadm join ${ip}:6443 --token ${token} --discovery-token-unsafe-skip-ca-verification"
}

init_cni_weave() {
  if [ -n "$(kubectl get ds -n=kube-system | grep weave)" ]; then
    kubectl delete -f https://git.io/weave-kube-1.6
  fi
  kubectl apply -f https://git.io/weave-kube-1.6
}

init_pv_rook() {
  kubectl apply -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/operator.yaml
  kubectl apply -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/cluster.yaml
  init_sc_rook
}

init_sc_rook() {
  cat > rook-storage.yaml<<EOF
apiVersion: ceph.rook.io/v1beta1
kind: Pool
metadata:
  name: replicapool
  namespace: rook-ceph
spec:
  replicated:
    size: 3
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rook-ceph-block
provisioner: ceph.rook.io/block
parameters:
  pool: replicapool
  clusterNamespace: rook-ceph
EOF
  kubectl apply -f rook-storage.yaml
}

init_dashboard() {
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
    cat > dashboard-svc.yml<<EOF
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  type: NodePort
  ports:
    - port: 8443
      targetPort: 8443
      nodePort: 30443
  selector:
    k8s-app: kubernetes-dashboard
EOF
    kubectl apply -f dashboard-svc.yml
}

init_admin_role() {
  cat > admin-role.yaml<<EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: admin
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: admin
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
EOF
  kubectl apply -f admin-role.yaml
}

reset_cluster() {
  run_command_on_each_node "kubeadm reset -f"
}

init_cluster() {
  local ip=${hosts[${master}]}
  init_master ${ip}
  init_slave ${ip}
}

reinit_cluster() {
  reset_cluster
  init_cluster
}

get_admin_role_token() {
  if  [ -z "$(kubectl get secrets --namespace kube-system | grep admin-token)" ]; then
      init_admin_role
  fi
  echo $(kubectl describe secrets $(kubectl get secrets --namespace kube-system | grep admin-token | awk '{print $1}') --namespace kube-system | grep token: | awk '{print $2}')
}

run_command_on_each_node() {
  command=${1}
  for name in $(docker-machine ls | grep node | awk '{print $1}'); do
    echo "Run Command On ${name} ..."
    docker-machine ssh ${name} ${command}
  done
}

run_command_on_slave_node() {
  command=${1}
  for name in $(docker-machine ls | grep node | grep -v $(hostname) | awk '{print $1}'); do
    echo "Run Command On ${name} ..."
    docker-machine ssh ${name} ${command}
  done
}

install() {
  install_docker_machine
  for host in ${hosts[*]}; do
    local node=${host%:*}
    local ip=${host#*:}
    init_base_env ${ip}
    set_firewalld_and_swap ${ip}
    set_kernel_config ${ip}
    install_docker_form_yum ${ip}
    install_docker_with_docker_machine ${node} ${ip}
    install_kubeadm ${ip}
    enable_kubelet ${ip}
    pull_require_images_from_sixi_registry ${ip}
  done
  init_cluster
  init_cni_weave
  init_pv_rook
  init_admin_role
  init_dashboard
  echo "Dashboard Token: $(get_admin_role_token)"
}

action=${1}
param=${2}
case "${action}" in
    help)
        echo "help - list help";
        echo "init [kubeadm|weave] - init k8s or plugin";
        echo "reset - reset all node use kubeadm";
        echo "";
        ;;
    info)
        kubectl get nodes,po,svc --all-namespaces
        ;;
    install|i)
        install
        ;;
    init)
        case "${param}" in
            kubeadm|k8s)
                reinit_cluster
                ;;
            weave)
                init_cni_weave
                ;;
            rook)
                init_pv_rook
                ;;
            dashboard)
                init_admin_role
                init_dashboard
                echo "Dashboard Token: $(get_admin_role_token)"
                ;;
        esac
        ;;
    reset)
        reset_node
        ;;
    reinit)
        reinit
        ;;
    run)
        run_command_on_each_node "${param}"
        ;;
    token)
        echo "Admin Role Token: $(get_admin_role_token)"
        ;;
    *)
        ;;
esac

SOURCE='docker.sixi.com'
TARGET='k8s.gcr.io'
K8S_VERSION='v1.12.1'

declare -A K8S_SERVER=(
["kube-apiserver"]="${K8S_VERSION}"
["kube-controller-manager"]="${K8S_VERSION}"
["kube-scheduler"]="${K8S_VERSION}"
["kube-proxy"]="${K8S_VERSION}"
["kubernetes-dashboard-amd64"]="v1.10.0"
["pause"]="3.1"
["etcd-amd64"]="3.2.18"
["coredns"]="1.1.3"
)

declare -A SERVER=(
["weaveworks/weave-kube"]="2.4.1"
["rook/ceph"]="master"
)

echo "Pull and Tag K8s Images..."

for s in ${!K8S_SERVER[*]}; do
    v=${K8S_SERVER[${s}]}
    docker pull "${SOURCE}/${s}:${v}"
    docker tag "${SOURCE}/${s}:${v}" "${TARGET}/${s}:${v}"
done

echo "Pull and Tag Normal Images..."

for s in ${!SERVER[*]}; do
    v=${SERVER[${s}]}
    docker pull "${SOURCE}/${s}:${v}"
    docker tag "${SOURCE}/${s}:${v}" "${s}:${v}"
done

echo "Done !"

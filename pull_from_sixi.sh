SOURCE='docker.sixi.com/miaowoo'
TARGET='k8s.gcr.io'
K8S_VERSION='v1.11.3'

declare -A K8S_SERVER=(
["kube-apiserver-amd64"]="${K8S_VERSION}"
["kube-controller-manager-amd64"]="${K8S_VERSION}"
["kube-scheduler-amd64"]="${K8S_VERSION}"
["kube-proxy-amd64"]="${K8S_VERSION}"
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
    docker push 
done

echo "Done !"

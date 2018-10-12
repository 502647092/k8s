SOURCE='registry.sixi.com'
USERNAME='anonymous'
PASSWORD='anonymous'
TARGET='k8s.gcr.io'
K8S_VERSION='v1.12.1'

docker login ${SOURCE} -u ${USERNAME} -p ${PASSWORD}

declare -A K8S_SERVER=(
["kube-apiserver"]="${K8S_VERSION}"
["kube-controller-manager"]="${K8S_VERSION}"
["kube-scheduler"]="${K8S_VERSION}"
["kube-proxy"]="${K8S_VERSION}"
["kubernetes-dashboard-amd64"]="v1.10.0"
["metrics-server-amd64"]="v0.3.1"
["heapster-amd64"]="v1.5.4"
["pause"]="3.1"
["etcd"]="3.2.24"
["coredns"]="1.2.2"
)

declare -A SERVER=(
["weaveworks/weave-kube"]="2.4.1"
["weaveworks/weave-npc"]="2.4.1"
["rook/ceph"]="master"
)

echo "Pull and Tag K8s Images..."

for s in ${!K8S_SERVER[*]}; do
    echo "=== Mirror ${s} ==="
    v=${K8S_SERVER[${s}]}
    docker pull "${SOURCE}/${s}:${v}"
    docker tag "${SOURCE}/${s}:${v}" "${TARGET}/${s}:${v}"
done

echo "Pull and Tag Normal Images..."

for s in ${!SERVER[*]}; do
    echo "=== Mirror ${s} ==="
    v=${SERVER[${s}]}
    docker pull "${SOURCE}/${s}:${v}"
    docker tag "${SOURCE}/${s}:${v}" "${s}:${v}"
done

echo "Done !"

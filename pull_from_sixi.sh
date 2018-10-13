SOURCE='registry.sixi.com'
USERNAME='anonymous'
PASSWORD='anonymous'
K8S_VERSION='v1.12.1'

docker login ${SOURCE} -u ${USERNAME} -p ${PASSWORD}

PRIVATE_IMAGES=(
k8s.gcr.io/kube-apiserver:${K8S_VERSION}
k8s.gcr.io/kube-controller-manager:${K8S_VERSION}
k8s.gcr.io/kube-scheduler:${K8S_VERSION}
k8s.gcr.io/kube-proxy:${K8S_VERSION}
k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.0
k8s.gcr.io/metrics-server-amd64:v0.3.1
k8s.gcr.io/heapster-amd64:v1.5.4
k8s.gcr.io/pause:3.1
k8s.gcr.io/etcd:3.2.24
k8s.gcr.io/coredns:1.2.2
gcr.io/kubernetes-helm/tiller:v2.11.0
)

IMAGES=(
weaveworks/weave-kube:2.4.1
weaveworks/weave-npc:2.4.1
rook/ceph:master
)

echo "Pull and Tag Private Images..."

for s in ${PRIVATE_IMAGES}; do
    echo "=== Mirror ${s} ==="
    IMAGE=${s#*/}
    docker pull "${SOURCE}/${IMAGE}"
    docker tag "${SOURCE}/${IMAGE}" "${s}"
done

echo "Pull and Tag Hub Images..."

for s in ${IMAGES}; do
    echo "=== Mirror ${s} ==="
    docker pull "${SOURCE}/${s}"
    docker tag "${SOURCE}/${s}" "${s}"
done

echo "Done !"

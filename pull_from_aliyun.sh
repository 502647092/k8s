SOURCE='registry.cn-hangzhou.aliyuncs.com/miaowoo'
K8S_VERSION='v1.12.1'

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
docker.io/weaveworks/weave-kube:2.4.1
docker.io/weaveworks/weave-npc:2.4.1
docker.io/rook/ceph:master
)

echo "Pull and Tag Private Images..."

for s in ${PRIVATE_IMAGES[*]}; do
    echo "=== Mirror ${s} ==="
    IMAGE=$(echo ${s#*/} | sed s@/@_@g -)
    docker pull "${SOURCE}/${IMAGE}"
    docker tag "${SOURCE}/${IMAGE}" "${s}"
    docker rmi "${SOURCE}/${IMAGE}"
done

echo "Done !"

SOURCE='registry.sixi.com/miaowoo'
TARGET='k8s.gcr.io'
VERSION='v1.11.3'
SERVER="kubernetes-dashboard-amd64:v1.10.0 kube-apiserver-amd64:${VERSION} kube-controller-manager-amd64:${VERSION} kube-scheduler-amd64:${VERSION} kube-proxy-amd64:${VERSION} pause:3.1 etcd-amd64:3.2.18 coredns:1.1.3"
for s in ${SERVER}; do
    docker pull "${SOURCE}/${s}"
    docker tag "${SOURCE}/${s}" "${TARGET}/${s}"
done

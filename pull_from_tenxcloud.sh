SOURCE='index.tenxcloud.com/miaowoo'
TARGET='k8s.gcr.io'
SERVER='kube-apiserver-amd64:v1.11.3 kube-controller-manager-amd64:v1.11.3 kube-scheduler-amd64:v1.11.3 kube-proxy-amd64:v1.11.3 pause:3.1 etcd-amd64:3.2.18 coredns:1.1.3'
for s in ${SERVER}; do
    docker pull "${SOURCE}/${s}"
    docker tag "${SOURCE}/${s}" "${TARGET}/${s}"
done

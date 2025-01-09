
# 离线安装高可用k8s集群.

## 预先准备

```bash
# 安装ansible
pip3 install ansible

pip3 install prisma
```

## 快速开始

```bash
# 修改inventroy，添加主机
vim inventory
# 从互联网预先下载组件
make download
# 开始安装
make install
```

---
## 包含组件

- Core
  - [kubernetes](https://github.com/kubernetes/kubernetes)
  - [etcd](https://github.com/etcd-io/etcd)
  - [containerd](https://github.com/containerd/containerd)
- Network Plugin
  - [cni-plugins](https://github.com/containernetworking/plugins)
  - [calico](https://github.com/projectcalico/calico)
  - [cilium](https://github.com/cilium/cilium)
  - [flanneld](https://github.com/flannel-io/flannel)
  - [kube-router](https://github.com/cloudnativelabs/kube-router)
  - [macvlan](https://github.com/containernetworking/plugins)
- Application
  - [coredns](https://github.com/coredns/coredns)
  - [node-local-dns](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/dns/nodelocaldns)
  - [metrics-server](https://github.com/kubernetes-sigs/metrics-server)
  - [nvidia_device_plugin](https://github.com/NVIDIA/k8s-device-plugin)
  - [cert-manager](https://cert-manager.io/)
  - [ingress-nginx](https://github.com/kubernetes/ingress-nginx)
  - [metallb](https://metallb.universe.tf/)
  - [grafana-loki](https://grafana.com/docs/loki/latest/)
  - [prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

# NodeLocal DNSCach

[back to README](../README.md)

The most common use case for LRP is to optimize DNS performance, alongside the [NodeLocal DNSCache](https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns) Kubernetes architecture. This architecture relies on a DNS caching agent running on each cluster node as a DaemonSet. With LRP you can be sure that DNS traffic from a pod goes to the DNS cache running on the same node as the pod, reducing latency, among [other benefits](https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/#motivation)

See [config sample](https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/#configuration), [yaml](https://github.com/kubernetes/kubernetes/blob/master/cluster/addons/dns/nodelocaldns/nodelocaldns.yaml)

```bash
# Need to fix
# __PILLAR__LOCAL__DNS__: 169.254.20.10
# __PILLAR__DNS__SERVER__: 10.96.0.10
# in deployment

kubedns=$(kubectl get svc kube-dns -n kube-system -o jsonpath={.spec.clusterIP})
domain="cluster.local"
localdns=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

wget https://raw.githubusercontent.com/kubernetes/kubernetes/refs/heads/master/cluster/addons/dns/nodelocaldns/nodelocaldns.yaml

# If kube-proxy is running in IPTABLES mode
sed -i "s/__PILLAR__LOCAL__DNS__/$localdns/g; s/__PILLAR__DNS__DOMAIN__/$domain/g; s/__PILLAR__DNS__SERVER__/$kubedns/g" nodelocaldns.yaml

# __PILLAR__CLUSTER__DNS__ and __PILLAR__UPSTREAM__SERVERS__ will be populated by the node-local-dns pods. In this mode, the node-local-dns pods listen on both the kube-dns service IP as well as <node-local-address>, so pods can look up DNS records using either IP address.

# If kube-proxy is running in IPVS mode
sed "s/__PILLAR__LOCAL__DNS__/$localdns/g; s/__PILLAR__DNS__DOMAIN__/$domain/g; s/,__PILLAR__DNS__SERVER__//g; s/__PILLAR__CLUSTER__DNS__/$kubedns/g" nodelocaldns.yaml

# this file ready to use, just apply
kubectl apply -f examples/performance/lpr/nodelocaldns.yaml

# or use ready yaml
# __PILLAR__LOCAL__DNS__: 169.254.20.10
# __PILLAR__DNS__SERVER__: 10.96.0.10
kubectl apply -f examples/performance/lpr/node-local-dns.yaml
```

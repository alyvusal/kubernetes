# metrics server

[back](../../README.md)

Provides CPU and Memory metrics only

- [github](https://github.com/kubernetes-sigs/metrics-server)
- [helm](https://artifacthub.io/packages/helm/metrics-server/metrics-server)

## installation

### install with manifest

if signed cert used in cluster

```bash
# single pod
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# ha
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability-1.21+.yaml
```

to override cert verification issue for not signed certs use `kustomize`

```bash
kubectl apply -k kustomization
```

**[TODO]**
if you want unsigned cert with metrics server ([read](https://github.com/kubernetes-sigs/metrics-server/blob/master/KNOWN_ISSUES.md#kubelet-doesnt-report-pod-metrics)), then run below command on control node

```bash
kubectl -n kube-system create configmap front-proxy-ca --from-file=front-proxy-ca.crt=/etc/kubernetes/pki/front-proxy-ca.crt -o yaml | kubectl -n kube-system replace configmap front-proxy-ca -f -
```

### install with helm

```bash
helm install --namespace kube-system metrics-server metrics-server/metrics-server

# to override cert verification issue for not signed certs
helm install --set 'args={--kubelet-insecure-tls}' --namespace kube-system metrics-server metrics-server/metrics-server
```

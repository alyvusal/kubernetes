# Calico

[back](../README.md)

```bash
kind create cluster --config /depo/docs/github/sre/kind/calico.yml --image kindest/node:v1.27.3
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
kubectl apply -k kubernetes/cni/calico/kustamization

# verify installation
watch kubectl get pods -l k8s-app=calico-node -A
```

## REFERENCE

- [k3d](https://k3d.io/stable/usage/advanced/calico/#references)

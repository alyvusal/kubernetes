# Kubernetes Dashbaord

[back](../README.md)

## Install

### with manifest

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

compare with helm manifest, use helm template`

### with helm

TODO: ingress not created, but port forward is ok

```bash
helm upgrade -i kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --create-namespace -n kubernetes-dashboard \
  --version 7.10.0
  # without kong not working
  #\
  #-f dashboard/helm/values/kubernetes-dashboard.yaml
```

## Access to dashboard

```bash
kubectl create serviceaccount -n kubernetes-dashboard admin-user
kubectl create clusterrolebinding -n kubernetes-dashboard admin-user --clusterrole cluster-admin --serviceaccount=kubernetes-dashboard:admin-user

# or
kubectl apply -f dashboard/account.yaml
kubectl -n kubernetes-dashboard create token admin-user

# access
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
# or
kubectl proxy
```

## REFERENCE

- [Github](https://github.com/kubernetes/dashboard)
- [Deploy and Access the Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
- [Create user](https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md)

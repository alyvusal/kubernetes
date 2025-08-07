# kubernetes

[back](../README.md)

## [API document](https://raw.githubusercontent.com/kubernetes/kubernetes/master/api/openapi-spec/swagger.json)

Check resource explanation

```bash
kubectl explain pod

# install kubectl-explore with krew
kubectl explore pod

# kexplain https://github.com/tony612/kexplain
kexplain pod
```

## native objects

|Deployment|Configuration|Security|Network|
|-|-|-|-|
|[Job](./job/README.md)|[ConfigMaps](./configMaps/README.md)|[Admission Controllers (ResourceQuota, LimitRange)](./admission-controllers/README.md)|[Ingress](./ingress/README.md)|
|[CronJob](./cronJob/README.md)|[Secret](./secret/README.md)|[Pod Security Admission](./pod-security-admission/README.md)|[Headless service](./headless-service/README.md)|
|[initContainer](./initContainers/README.md)|[Storage & Volume](./storage/README.md)|[Service Account](./service-account/README.md)|[CNI](./cni/README.md)|
|[StatefulSets](./statefulSets/README.md)|[Limits & Requests](./resource/README.md)|[AAA & RBAC](./aaa-rbac/README.md)|[Service](./service/README.md)|
|[Rolling Update](./rolling-update/README.md)|[PodDisruptionBudget](./pdb/README.md)|[Network Policy](./network-policy/README.md)||
|[Liveness, Readiness and Startup Probes (Healthchecks)](./healthcheck-and-probes/README.md)||[Audit](./audit/README.md)||
|||||

## addons

|mixed|service-mesh|ingress|scaling|templating|
|-|-|-|-|-|
|[Metrics server](./addons/metrics-server/README.md)|[Istio](../istio/README.md)|[ingress-nginx](../ingress-nginx/README.md)|[KEDA](../keda/README.md)|[helm](../helm/README.md)|
|[Dashboard](./addons/dashboard/README.md)|-|[MetalLB](../metallb/README.md)|[Karpenter](../karpenter/README.md)|[kustomize](../kustomize/README.md)|
|[External DNS](../external-dns/README.md)||[Traefik](../traefik/README.md)|[HPA](./hpa/README.md)|[jsonnet](../jsonnet/README.md)|
|[External Secrets](../external-secrets/README.md)||[Gateway API](./addons/gateway-api/README.md)|[VPA](./vpa/README.md)|kapitan|
|[Sealed Secrets](../sealed-secrets/README.md)||[AWS Load Balancer Controller](../aws-loadbalancer-controller/README.md)|[Cluster Autoscaler](./autoscaler/README.md)|ksonnet|
|||||dockerize|
|||||kubecfg|

## [Security](../security/README.md)

## Exam

[Exam questions](./exam/README.md)

## [Sample Apps](./sample-apps/README.md)

## REFERENCE

- [kube-scheduler-simulator](https://github.com/kubernetes-sigs/kube-scheduler-simulator)

## Useful commands

[A namespace is stuck in the Terminating state](https://www.ibm.com/docs/en/cloud-private/3.2.0?topic=console-namespace-is-stuck-in-terminating-state)

```bash
#  show you what resources remain in the namespace and can not delete namespace
kubectl api-resources --verbs=list --namespaced -o name \
  | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <namespace>

# force delete namespace
NS=`kubectl get ns |grep Terminating | awk 'NR==1 {print $1}'` && kubectl get namespace "$NS" -o json   | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/"   | kubectl replace --raw /api/v1/namespaces/$NS/finalize -f -
```

curl pod

```bash
kubectl run --rm -i --tty --image curlimages/curl curl -- sh
```

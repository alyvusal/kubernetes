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
|[Static Pod](./static-pod/README.md)||[Security Context](./privileged-pods-securityContext/README.md)||

## addons

|mixed|service-mesh|ingress|scaling|templating|
|-|-|-|-|-|
|[Metrics server](./addons/metrics-server/README.md)|[Istio](../istio/README.md)|[ingress-nginx](https://github.com/alyvusal/ingress-nginx)|[KEDA](https://github.com/alyvusal/keda)|[helm](https://github.com/alyvusal/helm)|
|[Dashboard](./addons/dashboard/README.md)|-|[MetalLB](https://github.com/alyvusal/metallb)|[Karpenter](https://github.com/alyvusal/karpenter)|[kustomize](https://github.com/alyvusal/kustomize)|
|[External DNS](https://github.com/alyvusal/external-dns)||[Traefik](https://github.com/alyvusal/traefik)|[HPA](./hpa/README.md)|[jsonnet](../jsonnet/README.md)|
|[External Secrets](https://github.com/alyvusal/external-secrets)||[Gateway API](./addons/gateway-api/README.md)|[VPA](./vpa/README.md)|kapitan|
|[Sealed Secrets](https://github.com/alyvusal/sealed-secrets)||[AWS Load Balancer Controller](https://github.com/alyvusal/aws-loadbalancer-controller)|[Cluster Autoscaler](./autoscaler/README.md)|ksonnet|
|||||dockerize|
|||||kubecfg|

## [Security](../security/README.md)

## Exam

[Exam questions](./exam/README.md)

## [Sample Apps](./sample-apps/README.md)

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

## REFERENCE

- [kube-scheduler-simulator](https://github.com/kubernetes-sigs/kube-scheduler-simulator)
- [Glossary](https://kubernetes.io/docs/reference/glossary/?all=true)

# Network Policy

[back](../README.md)

## Some points to note

- **Connection State**: NetworkPolicy is stateful and will allow an established connection to communicate both ways.
- **OSI Layer**: Control traffic flow at the IP address or port level (OSI layer 3 or 4)
- **Ingress and Egress**: Ingress means the traffic that is entering the Pod. Similarly, egress is the traffic that is leaving the pod.
- **Default = Allow All**: By default, the pod allows all ingress and egress. It means it has no restrictions for both inbound and outbound traffic.
- **No Deny Rules**: There are no denied rules in Network policies. **You can only specify traffic to be allowed and the rest is denied** (you can't write what to deny). You cannot get in if traffic is not allowed on the policy.
- **Empty selector** `{}`: An empty selector means everything. If `PodSelector:{}` is mentioned, it will select all the pods in the namespace.
- **Null selector** `[]`: If the policy contains a Null selector, means it is not selecting anything (so all traffic is blocked).
- **Policies are 'OR'ed**: Network policies are additive. If multiple policies are applied to a single pod, all the policies are `OR`ed.
- **Network policies do not conflict**; they are additive. If any policy or policies apply to a given pod for a given direction, the connections allowed in that direction from that pod are the union of what the applicable policies allow. Thus, the order of evaluation does not affect the policy result.
- **Network policy is namespace scoped**: Network Policies are scoped to the namespace, which means it will affect the traffic of the pods in the namespace at which the policy is applied.
- **Network policies do not conflict**: they are additive. If any policy or policies apply to a given pod for a given direction, the connections allowed in that direction from that pod is the union of what the applicable policies allow. Thus, order of evaluation does not affect the policy result.

When defining a pod- or namespace-based NetworkPolicy, you use a selector to specify what traffic is allowed to and from the Pod(s) that match the selector.

- [The two sorts of pod isolation](https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-two-sorts-of-pod-isolation)
- [Behavior of to and from selectors](https://kubernetes.io/docs/concepts/services-networking/network-policies/#behavior-of-to-and-from-selectors)

## Create demo apps and namespaces to test

destination app

```bash
for i in p1 p2; do
  kubectl create ns $i
  for a in 1 2; do
    kubectl -n $i create deployment nginx-$a --image=nginx
    kubectl -n $i expose deployment nginx-$a --port=80
  done
done

kubectl -n p1 create ingress nginx-1 --rule="nginx-192.168.0.100.nip.io/*=nginx-1:80"
# or kubectl apply -f examples/ingress.yaml

```

create curl app in p1, p2 and default namespaces

```bash
kubectl run access --rm -ti -l app=curl --image busybox /bin/sh
kubectl run -n p1 access --rm -ti -l app=curl --image busybox /bin/sh
kubectl run -n p2 access --rm -ti -l app=curl --image busybox /bin/sh

# add below alias
alias curl='wget --spider --timeout=1'
```

## podSelector

selects Pods that match a defined set of labels.

```yaml
podSelector:
  matchLabels:
    app: demo
```

## namespaceSelector

selects an entire namespace using labels. All the Pods in the namespace will be included

```yaml
namespaceSelector:
  matchLabels:
    app: demo
```

You can match a specific namespace by name by referencing the kubernetes.io/metadata.name label that Kubernetes automatically assigns:

```yaml
namespaceSelector:
  matchLabels:
    kubernetes.io/metadata.name: demo-namespace
```

## ipBlock

Used to allow traffic to or from specific IP address CIDR ranges. This is intended to be used to filter traffic from IP addresses that are **outside** the cluster. It’s not suitable for controlling Pod-to-Pod traffic because Pod IP addresses are ephemeral—they will change when a Pod is replaced.

```yaml
ipBlock:
  cidr: 10.0.0.0/24
```

## Combining selectors

The following policy selects all the Pods that are either labeled `demo-api` or belong to a namespace labeled `app: demo`:

This example represents a logical **`OR`**.

```yaml
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            app: demo
      - podSelector:
          matchLabels:
            app: demo-api
```

You can also create “and” conditions by combining selectors together. This policy only targets Pods that are both labeled `app: demo-api` and in a namespace labeled `app: demo`"

```yaml
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            app: demo
        podSelector:
          matchLabels:
            app: demo-api
```

## Setting allowed port ranges

Communication is only allowed on TCP ports in the range 32000 to 32100. You can omit the `endPort` field if you only use a single port

```yaml
ingress:
  - from:
      - podSelector:
          matchLabels:
            app: demo
    ports:
      - protocol: TCP
        port: 32000
        endPort: 32100
```

## Manifest

## REFERENCE

- [concept](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [task](https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/)
- [Kubernetes policy (Calico)](https://docs.tigera.io/calico/latest/network-policy/get-started/kubernetes-policy/)
- [Network Policy Editor](https://networkpolicy.io/editor)([Github](https://github.com/networkpolicy/tutorial))
- [API Definition](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#networkpolicy-v1-networking-k8s-io)
- [NetworkPolicy Tutorial](https://github.com/networkpolicy/tutorial)
- [11 Kubernetes Network Policies You Should Know](https://overcast.blog/11-kubernetes-network-policies-you-should-know-4374ce11db1f)

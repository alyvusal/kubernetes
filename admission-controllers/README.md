# Admission Controllers

[back](../README.md)

- [Admission Controllers Reference](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
- [Dynamic Admission Control](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)
- [A Guide to Kubernetes Admission Controllers](https://kubernetes.io/blog/2019/03/21/a-guide-to-kubernetes-admission-controllers/)
- [Validating Admission Policy](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/)

![img](./img/admission-controller.png "Request evaulation order")
Admission controll webhooks:

- **MutatingAdmissionWebhook**: Modify request (inject sidecar, change user, add label etc.)
- **ValidatingAdmissionWebhook**: Accept/Reject request

To see which admission plugins are enabled:

```bash
kube-apiserver -h | grep enable-admission-plugins

sudo nano /etc/kubernetes/manifests/kube-apiserver.yaml
  ...
  --enable-admission-plugins=NodeRestriction,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,Priority,ResourceQuota
  ...

systemctl restart kubelet
```

## Controllers

In Kubernetes 1.31, the default ones are:

CertificateApproval, CertificateSigning, CertificateSubjectRestriction, DefaultIngressClass, DefaultStorageClass, DefaultTolerationSeconds, LimitRanger, MutatingAdmissionWebhook, NamespaceLifecycle, PersistentVolumeClaimResize, PodSecurity, Priority, ResourceQuota, RuntimeClass, ServiceAccount, StorageObjectInUseProtection, TaintNodesByCondition, ValidatingAdmissionPolicy, ValidatingAdmissionWebhook

### ResourceQuota (Quota for namespace)

With ResourceQuotas, you can set a memory or CPU limit to the _entire namespace_, ensuring that entities in it can’t consume more from that amount.

### LimitRange (Quota for each resource)

- [concept](https://kubernetes.io/docs/concepts/policy/limit-range/)
- [Configure Default Memory Requests and Limits for a Namespace](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/memory-default-namespace/)
- [Configure Minimum and Maximum Memory Constraints for a Namespace](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/memory-constraint-namespace/)
- [openshift limit guide](https://docs.openshift.com/container-platform/4.8/nodes/clusters/nodes-cluster-limit-ranges.html)

LimitRanges are a Kubernetes policy that restricts the resource settings for _each entity_ in a namespace.

- `default`: Containers created will have this value if none is specified.
- `min`: Containers created can’t have limits or requests smaller than this.
- `max`: Containers created can’t have limits or requests bigger than this.

**Quaranteed QoS**: `requests` = `limits`. To achive this also need to disable SWAP entirely on node

#### Test

Apply [LimitRange manifest](./LimitRange.yml), then run `python` image to test

As default value for memory is 250 Mi, lets assign value below and above this value

```bash
$ kubectl run --restart Never --rm -ti --image=python pymemtest
If you don't see a command prompt, try pressing enter.
# lets assign 1Mi value
>>> big_value = "X" * 1000000
# lets increate it to 200Mi
>>> big_value = "X" * 1000000 * 200
# now lets increase value above 250 Mi
>>> big_value = "X" * 1000000 * 200 * 100
pod "pymemtest" deleted
pod default/pymemtest terminated (OOMKilled)
```

#### Enable SWAP

Add flag `--fail-swap-on=false` on kubelet (Otherwise it won't start)

## REFERENCE

- [Admission Controllers Reference](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers)

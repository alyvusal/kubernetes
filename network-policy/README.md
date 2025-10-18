# 🧩 [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

[back](../README.md)

Kubernetes **NetworkPolicies** control the flow of traffic (ingress and egress) at the **network layer (L3/L4)** between Pods within a cluster.
They act as **firewall rules** for Pod-level communication.

## 🔹 Key Concepts and Behaviors

### 🧠 Core Principles

- **Connection State**
  - NetworkPolicies are **stateful**.
    Once a connection is established, **return traffic is automatically allowed**, even if not explicitly permitted by another policy.

- **OSI Layer**
  - Operates at **Layer 3 (IP)** and **Layer 4 (TCP/UDP ports)**.
  - Controls traffic flow at the IP address or port level.
  - No visibility or filtering at **Layer 7** (application protocols like HTTP, DNS, Kafka, etc.).

- **Ingress and Egress**
  - **Ingress** → Traffic **entering** a Pod.
  - **Egress** → Traffic **leaving** a Pod.
  - Both directions can be independently controlled within a policy.

- **Default = Allow All**
  - By default, Pods **allow all ingress and egress**.
  - If **no NetworkPolicy** applies to a Pod, it has **no restrictions** for inbound or outbound traffic.

- **Implicit Deny Model (No Deny Rules)**
  - Once a NetworkPolicy applies to a Pod, **only traffic explicitly allowed is permitted** — everything else is denied.
  - There are **no explicit “deny” rules** in Kubernetes NetworkPolicy.
  - You **cannot write** a policy that says “deny X”; you can only write what to **allow**.
    Any traffic not matching an allow rule is **implicitly denied**.

---

### 🎯 Selectors and Matching

Selectors determine **which Pods and traffic sources/destinations** the policy applies to.

- **`podSelector: {}` (Empty Selector)**
  Selects **all Pods** in the namespace.

- **`podSelector: []` (Null or Omitted Selector)**
  Selects **no Pods**, effectively applying to nothing (blocking all ingress or egress).

- **`namespaceSelector`**
  Selects Pods **across namespaces** that match specific labels.

- **`ipBlock`**
  Matches external IP ranges or CIDRs outside the cluster.

- When defining Pod- or Namespace-based NetworkPolicies, use **selectors** to specify what traffic is **allowed** to and from Pods that match those selectors.

---

### ⚙️ Policy Evaluation & Behavior

- **Policies Are Additive (“OR’ed”)**
  - Multiple NetworkPolicies can apply to the same Pod.
  - NetworkPolicies **do not conflict** — they are **additive**. Once a pod is selected by multiple policies, all their `allow` rules are combined (unioned like yaml merge).
  - The **union of all allowed traffic** from every applicable policy defines what’s permitted.

- **Order of Evaluation**
  - There is **no priority or order** — policies are evaluated as a **set**.
  - The order in which policies are applied or created does **not** affect the result.

- **Namespace Scope**
  - NetworkPolicies are **namespace-scoped**.
  - A policy only affects Pods **within the same namespace** where the policy is defined.
  - Cross-namespace communication must be allowed using a **namespaceSelector**.

- **NetworkPolicy vs Enforcement**
  - The Kubernetes API will accept and store NetworkPolicies.
  - Actual enforcement depends on the **CNI plugin** (Calico, Cilium, Antrea, etc.).
  - CNIs like **Flannel** or default **EKS/Azure/GKE** setups may not enforce them without additional configuration.

### 📘 Summary

> **Kubernetes NetworkPolicy = Allow-only firewall at L3/L4, namespace-scoped, additive, no explicit deny.**

---

- [The two sorts of pod isolation](https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-two-sorts-of-pod-isolation)
- [Behavior of to and from selectors](https://kubernetes.io/docs/concepts/services-networking/network-policies/#behavior-of-to-and-from-selectors)

---

## 🔐 Kubernetes Network Policies vs [Cilium Network Policies](https://github.com/alyvusal/kubernetes-cni-cilium/blob/main/README.md)

Kubernetes **NetworkPolicies** and **CiliumNetworkPolicies** define how Pods can communicate with each other and with external endpoints.
While Kubernetes provides **L3/L4 isolation**, **Cilium** extends this to **L7**, enabling deep visibility, explicit deny rules, and advanced identity-based filtering.

### ⚖️ Compare NetworkPolicy vs CiliumNetworkPolicy

| Feature / Behavior | **Kubernetes NetworkPolicy** | **CiliumNetworkPolicy / CiliumClusterwideNetworkPolicy** |
|---------------------|------------------------------|-----------------------------------------------------------|
| **API Group** | `networking.k8s.io/v1` | `cilium.io/v2` |
| **CRD Type** | `NetworkPolicy` | `CiliumNetworkPolicy`, `CiliumClusterwideNetworkPolicy` |
| **Scope** | Namespace | Namespace or Cluster-wide |
| **Default Behavior (no policy)** | All traffic allowed | All traffic allowed |
| **Policy Model** | Allow-only (implicit deny) | Allow + Explicit Deny |
| **Deny Rules Supported** | ❌ No | ✅ Yes (`ingressDeny`, `egressDeny`) |
| **Rule Precedence** | N/A (union of allows) | **Deny > Allow** |
| **Ingress:** `[]` | Deny all ingress | Deny all ingress |
| **Ingress:** `- {}` | ❌ Invalid / no effect | ✅ Allow all ingress (wildcard) |
| **Omitting `ingress` / `egress`** | Deny all for the missing direction | Deny all for the missing direction |
| **Egress Control** | ✅ Supported (since v1.8) | ✅ Fully supported (with deny) |
| **CIDR Filtering** | ✅ Basic (`ipBlock`) | ✅ Advanced (`fromCIDRSet`, `toCIDRSet`, `toFQDNs`) |
| **Pod / Namespace Label Matching** | ✅ Yes | ✅ Yes + identity-based |
| **FQDN / DNS Filtering** | ❌ No | ✅ Yes (`toFQDNs`) |
| **L4 (port) Filtering** | ✅ Yes | ✅ Yes |
| **L7 (HTTP, DNS, Kafka, gRPC)** | ❌ No | ✅ Yes (via Envoy proxy) |
| **Order of Evaluation** | Irrelevant | Deny → Allow |
| **Policy Merging Behavior** | Additive (union of allows) | Additive (allows + denies, with deny precedence) |
| **Visibility & Metrics** | Minimal (CNI logs) | ✅ Hubble integration (flows, metrics, audit) |
| **Identity-Aware Enforcement** | ❌ No | ✅ Yes |
| **Clusterwide Enforcement** | ❌ No | ✅ Yes (CCNP) |
| **Default Deny Example** | `ingress: []`, `egress: []` | `ingress: []`, `egress: []` |
| **Allow All Example** | ❌ Not expressible | ✅ `ingress: - {}`, `egress: - {}` |
| **Underlying Mechanism** | Implemented by CNI plugin (Calico, Cilium, etc.) | Implemented via **eBPF** in kernel (Cilium agent) |

#### 💡 TL;DR

| Use Case | Recommendation |
|-----------|----------------|
| Basic L3/L4 isolation within namespaces | ✅ **Kubernetes NetworkPolicy** |
| Application-aware, deny rules, or cluster-wide security | 🚀 **CiliumNetworkPolicy** |
| Need for observability and auditability | ✅ **Cilium (with Hubble)** |
| Strict compliance / Zero Trust enforcement | ✅ **CiliumNetworkPolicy** with explicit deny rules |

---

### 🔄 Connection Statefulness — NetworkPolicy vs CiliumNetworkPolicy

| Aspect | **Kubernetes NetworkPolicy** | **CiliumNetworkPolicy (CNP)** |
|---------|------------------------------|--------------------------------|
| **Connection Tracking** | ✅ **Stateful** — Once an ingress or egress flow is allowed, **return traffic is automatically permitted**, even if not explicitly defined in the opposite direction. | ✅ **Stateful by default** (via eBPF). However, Cilium also allows **fine-grained control** over connection tracking behavior (e.g., per-direction enforcement, L7 awareness). |
| **Implementation Mechanism** | Relies on the **CNI plugin’s conntrack** or Linux `iptables`/`nftables` state tracking. There is **no way to disable** statefulness in standard NetworkPolicies. | Uses **eBPF connection tracking** in the Linux kernel. Can enforce at **connection setup**, **per packet**, or **L7-aware flow** depending on policy configuration. |
| **Bidirectional Flow Handling** | Once ingress is allowed from Pod A → Pod B, the **reverse traffic (B → A)** for that connection is automatically allowed. | Cilium tracks both directions at the flow level. With **L7 rules**, response paths can be enforced based on **protocol semantics** (e.g., HTTP method, status). |
| **Stateless Mode** | ❌ Not possible — all implementations are stateful. | ⚙️ Optional — certain Cilium modes (e.g., `allow-localhost: false`, or `toPorts` with L7 enforcement) can behave **semi-stateless** for more restrictive control. |
| **Visibility of Connection State** | Limited — you can’t inspect or control connection state within a NetworkPolicy. | 🔍 Deep visibility with **Hubble**: you can monitor flows, states, and policy verdicts (e.g., allowed, denied, forwarded). |
| **Effect on Return Traffic** | Always allowed automatically (implicit). | Configurable — return traffic allowed automatically unless restricted by **explicit deny rules** or **L7 filters**. |

For a connection from a source pod to a destination pod to be allowed, **both** the `egress policy on the source pod` and the `ingress policy on the destination pod` need to **allow** the connection. If either side does not allow the connection, it will not happen.

---

#### 🧠 Summary

- Both **Kubernetes NetworkPolicy** and **CiliumNetworkPolicy** are *stateful* by design.
- Kubernetes NetworkPolicy offers **no control** over connection tracking — it’s always stateful, symmetrical, and L3/L4-only.
- **CiliumNetworkPolicy** is **stateful by default**, but offers **deeper visibility and control**:
  - It tracks flows using **eBPF**.
  - You can mix **stateful + protocol-aware L7 filtering**.
  - You can apply **explicit deny** rules or **restrict return traffic** using `ingressDeny` / `egressDeny`.

#### TL;DR

> **Both policies are stateful**,
> but **CiliumNetworkPolicy** extends this concept with eBPF-based, L7-aware, and **explicitly controllable** connection state management.

### ✅ Example Comparison in Plain Terms

| Scenario | NetworkPolicy Behavior | CiliumNetworkPolicy Behavior |
|-----------|------------------------|-------------------------------|
| Allow ingress from Pod A to Pod B | B can respond to A automatically (stateful) | Same, but Cilium can also inspect and log the flow via Hubble |
| Block return traffic from B to A explicitly | ❌ Not possible | ✅ Possible with `egressDeny` or L7 rules |
| Restrict by HTTP method (e.g., allow only GET) | ❌ Not supported | ✅ Supported via L7 rules (Envoy-based) |
| Disable stateful behavior for testing | ❌ Not possible | ⚙️ Possible with specific configuration or L7 rules that terminate reverse flows |

---

## 🚦 CNI Plugins and NetworkPolicy Support

Not all Kubernetes CNIs (Container Network Interfaces) support the `NetworkPolicy` API.
Some CNIs completely ignore `NetworkPolicy` objects, while others only offer partial support or require add-ons.

This section lists which CNIs **support**, **partially support**, or **do not support** Kubernetes NetworkPolicies.

---

### 🚫 CNIs That **Do Not Support** NetworkPolicy

These CNIs **ignore NetworkPolicy objects** — meaning policies apply without error but have **no real effect** on traffic.

| CNI Plugin | NetworkPolicy Support | Notes |
|-------------|----------------------|--------|
| **Flannel** | ❌ **No** | Does not implement NetworkPolicy at all. Requires an additional plugin (e.g., Calico or Cilium) for enforcement. |
| **Weave Net** | ⚠️ **Partial / Deprecated** | Previously supported basic policies but project is **archived** and unmaintained. Not production-ready. |
| **Amazon VPC CNI (EKS default)** | ⚠️ **Partial** | No native enforcement. Must install **Calico** or **Cilium** on top for NetworkPolicy. |
| **Azure CNI (legacy)** | ⚠️ **Partial** | Limited support through `Azure NPM` (Network Policy Manager) add-on. Not full NetworkPolicy spec. |
| **Google GKE (VPC-native)** | ⚠️ **Partial** | Needs the **"Network Policy" add-on**, which installs **Calico** under the hood. Without it, policies are ignored. |
| **Kube-router** | ⚠️ **Partial** | Supports basic ingress/egress rules but lacks advanced features (no named ports, DNS egress, or IPBlock exceptions). |
| **Kindnet** (used by `kind` clusters) | ❌ **No** | Simple test CNI for local clusters — no NetworkPolicy support. |
| **Canal** (Flannel + Calico hybrid) | ✅ **Yes (if Calico enabled)** | If Calico’s policy engine is disabled → behaves like Flannel (**no policy support**). |

---

### ✅ CNIs That **Fully Support** NetworkPolicy

These CNIs fully implement the **Kubernetes NetworkPolicy spec** and often extend it with extra features (L7, deny rules, cluster-wide policies, etc.).

| CNI Plugin | NetworkPolicy Support | Extra Capabilities |
|-------------|----------------------|--------------------|
| **Calico** | ✅ **Full** | Advanced policies, global network sets, explicit deny rules (`GlobalNetworkPolicy`). |
| **Cilium** | ✅ **Full** | L3–L7 enforcement, explicit deny, FQDN & identity-based rules, Hubble observability. |
| **Antrea** | ✅ **Full** | OVS-based CNI with cluster policies, tiers, and traceability. |
| **Kube-OVN** | ✅ **Full** | Implements NetworkPolicy and additional ACL extensions for isolation. |
| **Romana** | ✅ **Full** | Native support for NetworkPolicy (less common today). |

---

### 🧠 TL;DR Summary

| Support Level | CNI Examples |
|----------------|--------------|
| ❌ **No support** | Flannel, Kindnet |
| ⚠️ **Partial support** | Amazon VPC CNI, Azure CNI, GKE (without add-on), Kube-router, Weave Net |
| ✅ **Full support** | Calico, Cilium, Antrea, Kube-OVN, Romana |

---

### ☁️ Cloud Provider Defaults

Here’s a revised view of how major managed Kubernetes services handle **NetworkPolicy support** by default — including whether it is **enforced out-of-the-box** or requires additional configuration.

| Cloud Provider | Default CNI / Networking Model | NetworkPolicy API Supported | Enforcement Enabled by Default? | Recommended Add-on / Notes |
|----------------|-------------------------------|-----------------------------|---------------------------------|----------------------------|
| **AWS EKS** | Amazon VPC CNI | ✅ Yes ([AWS Docs](https://docs.aws.amazon.com/eks/latest/userguide/cni-network-policy.html)) | ⚠️ Only if the VPC CNI add-on is configured with `enableNetworkPolicy=true` (v1.14+) ([Configure docs](https://docs.aws.amazon.com/eks/latest/userguide/cni-network-policy-configure.html)) | ➕ For full policy enforcement, ensure your VPC CNI is upgraded and policy support enabled — or install **Calico** / **Cilium** |
| **Google GKE** | GKE native CNI (or Dataplane V2) ([GKE Docs](https://cloud.google.com/kubernetes-engine/docs/concepts/network-overview)) | ✅ Yes | ⚠️ For *Standard* clusters, not enforced unless you enable `--enable-network-policy` or the NetworkPolicy add-on. For **Autopilot** or **Dataplane V2** clusters, enforcement is enabled by default ([How-to guide](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy)) | ➕ If Standard cluster, enable NetworkPolicy at creation or upgrade |
| **Azure AKS** | Azure CNI / Azure CNI powered by Cilium ([AKS Docs](https://learn.microsoft.com/en-us/azure/aks/azure-cni-powered-by-cilium)) | ✅ Yes | ⚠️ Not automatically enforced for all networking modes. Kubenet/Azure CNI must be combined with a policy engine (Azure NPM, Calico, or Cilium) ([Tigera Blog](https://www.tigera.io/blog/exploring-aks-networking-options/)) | ➕ Use `--network-policy calico` or switch to Azure CNI powered by Cilium |
| **DigitalOcean Kubernetes** | Cilium (default) | ✅ Yes | ✅ Yes — full support out of the box | ➕ Built-in L3–L7 policy support via Cilium |
| **Linode LKE** | Calico (default) | ✅ Yes | ✅ Yes — full support out of the box | ➕ Ready for standard policy usage |
| **IBM Cloud Kubernetes Service** | Calico (default) | ✅ Yes | ✅ Yes — full support out of the box | ➕ Includes global policy / multi-namespace features |

---

### 💡 Quick Takeaways

- 🧱 In general, a cluster may **support the NetworkPolicy API**, but that doesn’t guarantee enforcement — it depends on the CNI.
- 🔐 **EKS**: The API exists, but enforcement only happens when `enableNetworkPolicy=true` or when using **Calico/Cilium**.
- ⚙️ **GKE**: Standard clusters need the NetworkPolicy add-on; **Autopilot** and **Dataplane V2** already enforce it.
- ☁️ **AKS**: Enforcement requires enabling a policy engine (Azure NPM, Calico, or Cilium).
- 🎯 For advanced or zero-trust setups, use **Calico** or **Cilium** for L7, explicit deny, and cluster-wide policies.

---

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
    app: demo-pod
```

## namespaceSelector

selects an entire namespace using labels. All the Pods in the namespace will be included

```yaml
namespaceSelector:
  matchLabels:
    app: demo-namespace
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
- ipBlock:
    cidr: 10.0.0.0/24
    except:
      - 10.10.0.0/24
      - 10.10.1.0/24
```

## Combining selectors

The following policy selects all the Pods that are **either** *labeled `demo-api`* **or** *belong to a namespace labeled `app: demo-namespace`*:

This example represents a logical **`OR`**.

```yaml
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            app: demo-namespace
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
            app: demo-namespace
        podSelector:
          matchLabels:
            app: demo-pod
```

## Setting allowed port ranges and protocol

Communication is only allowed on TCP ports in the range 32000 to 32100. You can omit the `endPort` field if you only use a single port

```yaml
ingress:
  - from:
      - podSelector:
          matchLabels:
            app: demo-pods
    ports:
      - protocol: TCP
        port: 32000
        endPort: 32100
```

## Manifest

## 📚 REFERENCE

- [Kubernetes Network Policy Documentation](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Task](https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/)
- [Kubernetes policy (Calico)](https://docs.tigera.io/calico/latest/network-policy/get-started/kubernetes-policy/)
- [Network Policy Editor](https://networkpolicy.io/editor)([Github](https://github.com/networkpolicy/tutorial))
- [API Definition](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#networkpolicy-v1-networking-k8s-io)
- [NetworkPolicy Tutorial](https://github.com/networkpolicy/tutorial)
- [11 Kubernetes Network Policies You Should Know](https://overcast.blog/11-kubernetes-network-policies-you-should-know-4374ce11db1f)

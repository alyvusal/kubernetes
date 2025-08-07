# Pod Security Admission

[back](../README.md)

- [concept](https://kubernetes.io/docs/concepts/security/pod-security-admission/)
- [standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Enforce Pod Security Standards by Configuring the Built-in Admission Controller](https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-admission-controller/)
- [Enforce Pod Security Standards with Namespace Labels](https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-namespace-labels/)

## Pod Security Standards

The Pod Security Standards define three different policies to broadly cover the security spectrum. These policies are cumulative and range from highly-permissive to highly-restrictive. This guide outlines the requirements of each policy.

|Profile|Description|
|-------|-----------|
|Privileged|Unrestricted policy, providing the widest possible level of permissions. This policy allows for known privilege escalations.|
|Baseline|Minimally restrictive policy which prevents known privilege escalations. Allows the default (minimally specified) Pod configuration.|
|Restricted|Heavily restricted policy, following current Pod hardening best practices.|

## Policy Modes

Policies are applied using modes. Here is a list of modes:

- `enforce` Any Pods that violate the policy will be rejected
- `audit` Pods with violations will be allowed and an audit annotation will be added
- `warn` Pods that violate the policy will be allowed and a warning message will be sent back to the user.

## Applying Policy to a namespace

Policies are applied to a namespace via labels. These labels are as follows:

- REQUIRED: `pod-security.kubernetes.io/<MODE>: <LEVEL>`
- OPTIONAL: `pod-security.kubernetes.io/<MODE>-version: <VERSION>` (defaults to latest)

apply with imperative method

```bash
kubectl label --overwrite ns test-ns \
  pod-security.kubernetes.io/warn=baseline \
  pod-security.kubernetes.io/warn-version=v1.22
```

Test policy

```bash
kubectl label --dry-run=server --overwrite ns --all \
    pod-security.kubernetes.io/enforce=baseline
```

use [test.yml](./test.yml) for testing purposes. Check [guide](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) for step by step testing with `allowed` pod

## `securityContext` and PSS

The securityContext at the pod or container level defines security-related configurations for the workload, such as running as a non-root user or dropping Linux capabilities. However, the behavior of securityContext depends on the cluster's configuration and policies. If Pod Security Standards (PSS) or PodSecurityPolicies (PSP) (deprecated in Kubernetes 1.25) are not applied, the securityContext settings may not take effect for the following reasons:

1. Absence of Enforcement
Without PSS or PSP, Kubernetes does not enforce certain security settings across pods. The securityContext settings become recommendations rather than rules enforced at the cluster level.

Example:
If a securityContext specifies runAsNonRoot: true, Kubernetes won't block the pod from running as the root user unless a policy explicitly enforces it.
2. Cluster's Default Behavior
In clusters without enforced policies:

Kubernetes allows pods to run with default security settings, which often permit elevated privileges unless overridden by a Node Policy or the Container Runtime (e.g., Docker, containerd).
3. Pod-Level Configuration is Optional
The securityContext at the pod or container level applies only if explicitly set. Without policies like PSS, the following happens:

Pods with missing or partial securityContext configurations fall back to Kubernetes defaults, which might allow insecure configurations (e.g., running as root).
Example of Default Behavior Without Enforcement:
No securityContext defined.
The container runs with UID 0 (root user) and elevated capabilities.

4. Misconfiguration or Ignored Fields
If securityContext configurations are applied incorrectly, they may be ignored. Common issues include:

Setting incompatible securityContext options (e.g., combining runAsNonRoot with a runAsUser value of 0).
Using values that are not supported by the container runtime.

Example:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 0 # Conflicting configuration
```

This configuration results in a conflict, causing Kubernetes to ignore it or fail validation.

5. Runtime Constraints
Some container runtimes or underlying infrastructure may override the securityContext settings:

A container runtime might allow the workload to run as root despite runAsNonRoot: true if no policies enforce it.
Privileges like allowPrivilegeEscalation may default to true unless explicitly disabled.
6. Lack of Admission Controllers
Pod Security Standards or PodSecurityPolicies act as admission controllers, validating and enforcing security settings during pod creation. Without these:

Pods bypass any checks and are created with whatever configuration they specify, including insecure defaults.
How to Ensure SecurityContext Works Properly
Enable Pod Security Standards (PSS):

Kubernetes supports built-in standards for baseline, restricted, or privileged levels.
Use namespace labels to apply these:

```bash
kubectl label namespace <namespace> pod-security.kubernetes.io/enforce=restricted
```

Use Valid SecurityContext: Define a valid securityContext in the pod specification:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
```

Review Node Policies:

Ensure your cluster nodes don't override container runtime security settings.
Test Security Settings:

Validate that securityContext is respected by attempting to run insecure workloads and reviewing pod events/logs for enforcement errors.
Leverage Tools:

Use tools like OPA Gatekeeper or Kyverno for additional policy-based security enforcement.

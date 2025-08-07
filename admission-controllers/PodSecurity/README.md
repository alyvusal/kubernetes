# [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)

Enforce the [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/). Pod security restrictions are applied at the namespace level when pods are created

Kubernetes defines a set of labels (modes) that you can set to define which of the predefined Pod Security Standard levels you want to use for a namespace

- `enforce`: Policy violations will cause the pod to be rejected.
- `audit`: Policy violations will trigger the addition of an audit annotation to the event recorded in the audit log, but are otherwise allowed.
- `warn`: Policy violations will trigger a user-facing warning, but are otherwise allowed.

```yaml
# The per-mode level label indicates which policy level to apply for the mode.
#
# MODE must be one of `enforce`, `audit`, or `warn`.
# LEVEL must be one of `privileged`, `baseline`, or `restricted`.
pod-security.kubernetes.io/<MODE>: <LEVEL>

# Optional: per-mode version label that can be used to pin the policy to the
# version that shipped with a given Kubernetes minor version (for example v1.31).
#
# MODE must be one of `enforce`, `audit`, or `warn`.
# VERSION must be a valid Kubernetes minor version, or `latest`.
pod-security.kubernetes.io/<MODE>-version: <VERSION>
```

## [Enforce Pod Security Standards with Namespace Labels](https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-namespace-labels/)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-baseline-namespace
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/enforce-version: v1.31

    # We are setting these to our _desired_ `enforce` level.
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: v1.31
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: v1.31
```

## [Apply Pod Security Standards at the Cluster Level](https://kubernetes.io/docs/tutorials/security/cluster-level-pss/)

- [Enforce Pod Security Standards by Configuring the Built-in Admission Controller](https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-admission-controller/)

After cluster bootstrap if want to override defaults:

```bash
kubectl create ns testytest

kubectl label --overwrite namespace --all \
  pod-security.kubernetes.io/audit=baseline \
  pod-security.kubernetes.io/warn=baseline

kubectl label --overwrite namespace testytest\
  pod-security.kubernetes.io/audit=restricted\
  pod-security.kubernetes.io/warn=restricted

$ kubectl apply -f test-app.yaml
Warning: would violate PodSecurity "restricted:latest": privileged (container "nginxdeployment" must not set securityContext.privileged=true), allowPrivilegeEscalation != false (container "nginxdeployment" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "nginxdeployment" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "nginxdeployment" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "nginxdeployment" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
```

## REFERENCE

- [Migrate from PodSecurityPolicy to the Built-In PodSecurity Admission Controller](https://kubernetes.io/docs/tasks/configure-pod-container/migrate-from-psp/)
- [Enforcing Pod Security Standards](https://kubernetes.io/docs/setup/best-practices/enforcing-pod-security-standards/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

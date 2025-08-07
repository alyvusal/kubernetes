# Liveness, Readiness and Startup Probes

[back](../README.md)

- [tasks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

## Liveness

Many applications running for long periods of time eventually transition to broken states, and cannot recover except by being restarted. Kubernetes provides liveness probes to detect and remedy such situations.

## Startup

Sometimes, you have to deal with legacy applications that might require an additional startup time on their first initialization. In such cases, it can be tricky to set up liveness probe parameters without compromising the fast response to deadlocks that motivated such a probe. The trick is to set up a startup probe with the same command, HTTP or TCP check, with a `failureThreshold * periodSeconds` long enough to cover the worst case startup time.

Once the **startup probe** has succeeded once, the **liveness probe** takes over to provide a fast response to container deadlocks. If the startup probe never succeeds, the container is killed after `failureThreshold * periodSeconds` and subject to the pod's `restartPolicy`.

## Readiness

Sometimes, applications are temporarily unable to serve traffic. For example, an application might need to load large data or configuration files during startup, or depend on external services after startup. In such cases, you don't want to kill the application, but you don't want to send it requests either. Kubernetes provides readiness probes to detect and mitigate these situations. A pod with containers reporting that they are not ready does not receive traffic through Kubernetes Services.

**Note**: Readiness probes runs on the container during its whole lifecycle.

:exclamation: **Caution**: The readiness and liveness probes do not depend on each other to succeed. If you want to wait before executing a readiness probe, you should use `initialDelaySeconds` or a `startupProbe`.

![alt text](img/comparison.png)

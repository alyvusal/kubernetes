# Resource

## Limits and Requests

[back](../README.md)

- [concept](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Understanding Kubernetes Limits and Requests](https://sysdig.com/blog/kubernetes-limits-requests/)

**Kubernetes defines Limits as the maximum amount of a resource** to be used by a container. This means that the container can never consume more than the memory amount or CPU amount indicated.

**Requests, on the other hand, are the minimum guaranteed amount of a resource** that is reserved for a container.

Let’s say we are running a cluster with, for example, 4 cores and 16GB RAM nodes. We can extract a lot of information:

![Alt text](./img/image.png)

1. **Pod effective request** is 400 MiB of memory and 600 millicores of CPU. You need a node with enough free allocatable space to schedule the pod.
2. **CPU shares** for the redis container will be 512, and 102 for the busybox container. Kubernetes always assign 1024 shares to every core, so redis: `1024 * 0.5 cores ≅ 512` and busybox: `1024 * 0.1cores ≅ 102`
3. Redis container will be **OOM killed** if it tries to allocate more than 600MB of RAM, most likely making the pod fail.
4. Redis will suffer **CPU throttle** if it tries to use more than 100ms of CPU in every 100ms, (since we have 4 cores, available time would be 400ms every 100ms) causing performance degradation.
5. Busybox container will be **OOM killed** if it tries to allocate more than 200MB of RAM, resulting in a failed pod.
6. Busybox will suffer **CPU throttle** if it tries to use more than 30ms of CPU every 100ms, causing performance degradation.

When allocating Pods to a Node. If no requests are set, by default, Kubernetes will assign **requests = limits**

![Alt text](./img/throttle.png)

For **ResourceQuota** and **LimitRange** see [Validating Admission Controller](../admission-controllers/README.md)

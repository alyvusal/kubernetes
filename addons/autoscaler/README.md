# Cluster Autoscaler

[back](../README.md)

Check [EKS addons](../../../eks/addons/terraform/) also for deployments

Kubernetes offers the following autoscalers:

1. Cluster Autoscaler (CA): Autoscales nodes based on the required resources (CPU, memory, etc.) to run scheduled pods. At Pingpong, we use arpenter as an alternative to CA.
2. Horizontal Pod Autoscaler (HPA): Adjusts the number of pod replicas based on traffic. Each pod requires the same amount of resources.
3. Vertical Pod Autoscaler (VPA): Adjusts the resource requests and limits of individual pods based on traffic. VPA requires pod restarts when changing resources, and there are limitations to the resources (CPU, memory) that a single node can hold.

## Combining Autoscalers for Optimal Performance

In practice, HPA, VPA, and Cluster Autoscaler are often used in tandem to achieve both efficient resource utilization and responsive scaling. However, it’s crucial to understand their interactions:

1. HPA and VPA: Should be used with caution together as **they can conflict**; for example, HPA might try to add more pods when VPA recommends increasing resources to existing pods.
2. HPA and Cluster Autoscaler: Complement each other well, as HPA adjusts the number of pods and Cluster Autoscaler adjusts the number of nodes to accommodate the pods.
3. VPA and Cluster Autoscaler: Can be used together to ensure pods have enough resources and that nodes are added or removed based on overall demand.

## Deploy with KOWK for local test

To be able to use scaling of nodes on laptop we need to use [KWOK](../../kwok/README.md). We will use [KWOK provider](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/kwok) in autoscaling

## REFERENCE

- [autoscaler](https://github.com/kubernetes/autoscaler)
- [providers](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)

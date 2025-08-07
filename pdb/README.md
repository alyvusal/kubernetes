# PodDisruptionBudget

[back](../README.md)

- [concept](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
- [tasks](https://kubernetes.io/docs/tasks/run-application/configure-pdb/)

## What are Pod Disruption Budgets?

**PDBs** can be applied to a specific workload, such as a Deployment or StatefulSet, or to a group of workloads using a label selector. They can also be configured to tolerate different types of disruptions, such as maintenance events or node failures. PDBs are a powerful feature for ensuring high availability in a Kubernetes environment, and their use is strongly recommended in production environments.

**PDBs** specify a minimum availability for a particular type of pod, which is called the “target size”. This means that at least a certain number of replicas of a particular type of pod must be running at any given time. If the number of running replicas falls below the target size, Kubernetes will prevent further disruptions to the remaining replicas until the target size is met.

**PDB** configures the number of concurrent disruptions that application pod experiences when node is to be managed. Deployment, ReplicationController, ReplicaSet, StatefulSet can be bind by PodDisruptionBudget with `.spec.selector` label selector. The budget is specified by using either of two values:

**minAvailable**: This is the minimum number of pods that should be running for the label. For example, if we have 20 pods running and minAvailable is set to 10. If the node is to be drained for some reason or pods are to evicted, only 10 will start terminating and will gradually drain rest. But at least 10 of the pods will be ready state so that the application can serve request. The number should be decided based on the traffic or workload the pods should handle.

**maxUnavailable**: The number of pods that could terminate in case node has to be drained.

In both cases, we can specify both absolute number as well as percentage. Like, if we have 20 pods running and maxUnavailable is set to 50%, then 10 pods can be unavailable.

Watch for pods status in separate window

```bash
watch -n 1 kubectl get pods -o wide
```

Drain node

```bash
kubectl cordon kind-worker
kubectl drain kind-worker --ignore-daemonsets --delete-emptydir-data 
```

You will see at how pods created before evicting them from node.

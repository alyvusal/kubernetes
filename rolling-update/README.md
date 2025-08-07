# Rolling Update

[back](../README.md)

- [tutorial](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)

In your Deployment manifest, `spec.strategy.type` has two possible values:

- `RollingUpdate`: New pods are added gradually, and old pods are terminated gradually
- `Recreate`: All old pods are terminated before any new pods are added

`RollingUpdate` config params in `spec.strategy.rollingUpdate` has following options:

- `maxUnavailable`: The maximum number of pods that can be unavailable during the update. Value can be an absolute number (ex: 5) or a percentage of desired pods (ex: 10%). Absolute number is calculated from percentage by rounding down. This can not be 0 if MaxSurge is 0. Defaults to 25%. Example: when this is set to 30%, the old ReplicaSet can be scaled down to 70% of desired pods immediately when the rolling update starts. Once new pods are ready, old ReplicaSet can be scaled down further, followed by scaling up the new ReplicaSet, ensuring that the total number of pods available at all times during the update is at least 70% of desired pods.
- `maxSurge`: The maximum number of pods that can be scheduled above the desired number of pods. Value can be an absolute number (ex: 5) or a percentage of desired pods (ex: 10%). This can not be 0 if MaxUnavailable is 0. Absolute number is calculated from percentage by rounding up. Defaults to 25%. Example: when this is set to 30%, the new ReplicaSet can be scaled up immediately when the rolling update starts, such that the total number of old and new pods do not exceed 130% of desired pods. Once old pods have been killed, new ReplicaSet can be scaled up further, ensuring that total number of pods running at any time during the update is at most 130% of desired pods.

:exclamation: **Pods to be updated at the same time** = **Replicas** + **maxSurge** - **maxUnavailable**

```bash
# Update a deployment with a manifest file:
kubectl apply -f rollingUpdate.yaml

# update image of deployment
kubectl set image deployment/nginx-deployment nginx=nginx:1.9
# or Scale a deployment nginx-deployment to 5 replicas:
kubectl scale deploy/nginx-deployment --replicas=10

# Watch update status for deployment nginx-deployment:
kubectl rollout status deploy/nginx-deployment

# --record deprecated, instead use annotate
kubectl annotate deployment nnginx-deploymentginx kubernetes.io/change-cause="version change to 1.8 to 1.9" --overwrite=true

# Watch update status for deployment nginx-deployment:
kubectl rollout status deploy/nginx-deployment

# Watch update status for deployment nginx-deployment:
kubectl rollout status deploy/nginx-deployment

# Pause deployment on nginx-deployment:
kubectl rollout pause deploy/nginx-deployment

# Resume deployment on nginx-deployment:
kubectl rollout resume deploy/nginx-deployment

# View rollout history on nginx-deployment:
kubectl rollout history deploy/nginx-deployment

# Undo most recent update on nginx-deployment:
kubectl rollout undo deploy/nginx-deployment

# Rollback to specific revision on nginx-deployment:
kubectl rollout undo deploy/nginx-deployment --to-revision=1
```

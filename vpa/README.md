# VPA (VerticalPodAutoscaler)

[back](../README.md)

Kubernetes offers the following autoscalers:

1. Cluster Autoscaler (CA): Autoscales nodes based on the required resources (CPU, memory, etc.) to run scheduled pods. At Pingpong, we use arpenter as an alternative to CA.
2. Horizontal Pod Autoscaler (HPA): Adjusts the number of pod replicas based on traffic. Each pod requires the same amount of resources.
3. Vertical Pod Autoscaler (VPA): Adjusts the resource requests and limits of individual pods based on traffic. VPA requires pod restarts when changing resources, and there are limitations to the resources (CPU, memory) that a single node can hold.

- [blog](https://www.densify.com/kubernetes-autoscaling/kubernetes-vpa/)

## Limitations

- The minimum memory allocation the VPA can recommend is 250 MiB.
If your requests is smaller, it will be automatically increased to fit this minimum. This minimum value can be globally [configured](https://github.com/kubernetes/autoscaler/issues/2125#issuecomment-503987877) though. This setting basically guides you not to use vertical autoscaler for too small applications.
- The Vertical Pod Autoscaler cannot be used on individual pods which don’t have an owner (= they are not part of a Deployment, etc.).
- By default you do not have the Prometheus integration enabled, which allows to watch for OOM events and fetch more historical performance data.
Following the example above, we want to use VPA to scale Prometheus itself, so unless you have persistent storage configured for the metrics store of Prometheus, once it gets restarted, we would lose all the historical, useful data which VPA expects for making scaling decisions.
- The Service name must be vpa-webhook (and all the components must be deployed in kube-system if you generate the certs with the built-in scripts), due to some hardcoded things.
- VPA works with **at least 2 replica** in deployment, it does not recreate single pods
- You can only enable vertical scaling on components which have at least 2 healthy replicas running. In case you have some apps which are not able to run in parallel, yet you want to autosize them, there’s a nice trick you can do in the vpa-updater Deployment:

So when you get a scaling recommendation, it will respect and keep the same ratio you originally configured, and proportionally set the new values based on your original ratio.

Here’s an example:

Your pod’s default settings:

```yaml
requests:
  cpu: 50m
  memory: 100Mi
limits:
  cpu: 200m
  memory: 250Mi
```

The recommendation engine will determine that you need 120m CPU and 300Mi memory for your pod to work correctly. So it will come up with the following new settings:

```yaml
requests:
  cpu: 120m
  memory: 300Mi
limits:
  cpu: 480m
  memory: 750Mi
```

As mentioned above, this is proportional scaling: in your default manifest, you had the following requests to limits ratio:

- CPU: 50m → 200m: 1:4 ratio
- Memory: 100Mi → 250Mi: 1:2.5 ratio

So when you get a scaling recommendation, it will respect and keep the same ratio you originally configured, and proportionally set the new values based on your original ratio.

So if you want to ensure your memory limit never goes above 250Mi on your pod, here are some ideas:

- (always) configure minimum and maximum values for the request recommendation
- use 1:1 request-to-limit ratio, so even if you get the maximum request, the limit won’t go above either
- any combination of the above, play with the ratios

But don’t forget, your limits are almost irrelevant, as the scheduling decision (and therefore, resource contention) will be always done based on the requests. Limits are only useful when there's resource contention or when you want to avoid uncontrollable memory leaks.

    ```yaml
    [...]
        spec:
        containers:
        - name: updater
            args:
            # These 2 lines are default: https://github.com/kubernetes/autoscaler/blob/vertical-pod-autoscaler-0.6.3/vertical-pod-autoscaler/pkg/updater/Dockerfile#L22
            - --v=4
            - --stderrthreshold=info
            # Allow Deployments with only 1 replica to be restarted with new settings
            - --min-replicas=1
    [...]
    ```

- Something we learnt the hard way: once you deploy and enable the Vertical Pod Autoscaler in your cluster, everything goes through its webhook. Every single pod creation/restart/… event!
- 1 Mebibyte is equal to (220 / 106) Megabytes.
- 1 MiB = 1.048576 MB

So guess what happens when your VPA Admission Webhook deployment is down or extremely slow… None of your pods will be able to start, even if they don’t use vertical autoscaling at all! (This is not specific to VPA, it’s true for any Admission Webhooks.)

**Reminder**: the VPA minimum and maximum range settings are always for the requests parameter of your pod. It will respect and keep the same ratio you originally configured

## Monitoring

Grafana has some [dashboards](https://grafana.com/grafana/dashboards/?search=vpa) for VPA

## Installation

There are 3 Deployments running:

1. **VPA admission hook**
Every pod submitted to the cluster goes through this webhook automatically which checks whether a VerticalPodAutoscaler object is referencing this pod or one of its parents (a ReplicaSet, a Deployment, etc.)
2. **VPA recommender**
Connects to the metrics-server application in the cluster, fetches historical and current usage data (CPU and memory) for each VPA-enabled pod and generates recommendations for scaling up or down the requests and limits of these pods.
3. **VPA updater**
Runs every 1 minute. If a pod is not running in the calculated recommendation range, it evicts the currently running version of this pod, so it can restart and go through the VPA admission webhook which will change the CPU and memory settings for it, before it can start.

```bash
# Install VPA components
git clone https://github.com/kubernetes/autoscaler.git --depth=1 --branch=vertical-pod-autoscaler-1.2.1
cd autoscaler/vertical-pod-autoscaler
./hack/vpa-up.sh
kubectl get pods -A | grep vpa

# To print YAML manifests
./hack/vpa-process-yamls.sh print
# The output of that command won't include secret information generated by pkg/admission-controller/gencerts.sh script.

cd ../..
rm -rf autoscaler

# deploy test vpa deployment
kubectl apply -f examples/vpa-auto.yml

# during load pods will be recreated with new cpu/memory values
watch -n1 "kubectl describe pod -l app=vpa-auto-ubuntu-stress | grep Limits -A 5 && kubectl get vpa && kubectl top pods"
```

## Per container policy

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
  ...
spec:
  resourcePolicy:
    containerPolicies:
    - containerName: "configmap-reload"  # Exclude scaling for this container
      mode: "Off"
    - containerName: "prometheus"
      minAllowed:
        cpu: "300m"
        memory: "512Mi"
      maxAllowed:
        cpu: "1800m"
        memory: "3600Mi"
```

## Recommendation mode (dry run)

**TIP**: Use recommendation mode even if you don’t want autoscaling! It is not necessary to enable actual autoscaling, even if you keep collecting data and recommendations.

You need to define a new VPA object with `updateMode: off`, targeting your application

```bash
kubectl apply -f examples/vpa-off.yml
kubectl describe pod -l app=vpa-off-ubuntu-stress | grep Limits -A 5 && kubectl get vpa && kubectl top pods

# After 2–3 minutes, get recommendation
$ kubectl describe vpa vpa-off-ubuntu-stress
    ...
    Status:
    Conditions:
        Last Transition Time:  2024-10-09T16:27:38Z
        Status:                True
        Type:                  RecommendationProvided
    Recommendation:
        Container Recommendations:
        Container Name:  vpa-off-ubuntu-stress
        Lower Bound:
            Cpu:     55m
            Memory:  262144k
        Target:
            Cpu:     126m
            Memory:  262144k
        Uncapped Target:
            Cpu:     126m
            Memory:  262144k
        Upper Bound:
            Cpu:     64542m
            Memory:  104343460797
```

You will see the following blocks:

- `Uncapped Target`: what would be the resource request configured on your pod if you didn’t configure upper limits in the VPA definition.
- `Target`: this will be the actual amount configured at the next execution of the admission webhook. (If it already has this config, no changes will happen (your pod won’t be in a restart/evict loop). Otherwise, the pod will be evicted and restarted using this target setting.)
- `Lower Bound`: when your pod goes below this usage, it will be evicted and downscaled.
- `Upper Bound`: when your pod goes above this usage, it will be evicted and upscaled.

## Tips

- For `CronJob` first use Recommandation mode then use Initial mode, no evictions or disruptions will happen

## REFERENCE

- [autoscaler](../autoscaler/README.md)
- [autoscaler/vpa](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
- [Vertical Pod Autoscaler deep dive, limitations and real-world examples](https://medium.com/infrastructure-adventures/vertical-pod-autoscaler-deep-dive-limitations-and-real-world-examples-9195f8422724)
- [Vertical Pod Autoscaling: The Definitive Guide](https://povilasv.me/vertical-pod-autoscaling-the-definitive-guide/)

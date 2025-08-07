# HPA (HorizontalPodAutoscaler)

[back](../README.md)

Kubernetes offers the following autoscalers:

1. Cluster Autoscaler (CA): Autoscales nodes based on the required resources (CPU, memory, etc.) to run scheduled pods. At Pingpong, we use arpenter as an alternative to CA.
2. Horizontal Pod Autoscaler (HPA): Adjusts the number of pod replicas based on traffic. Each pod requires the same amount of resources.
3. Vertical Pod Autoscaler (VPA): Adjusts the resource requests and limits of individual pods based on traffic. VPA requires pod restarts when changing resources, and there are limitations to the resources (CPU, memory) that a single node can hold.

requires [metrics-server](../metrics-server/Readme.md) to operate

- [tasks](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [tasks](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)
- [Kubernetes 1.27: HorizontalPodAutoscaler ContainerResource type metric moves to beta](https://kubernetes.io/blog/2023/05/02/hpa-container-resource-metric/)
- [blog](https://komodor.com/learn/horizontal-pod-autoscaler/)

auto scale

```bash
# imperative
kubectl autoscale deployment hpa-nginx --cpu-percent=50 --min=1 --max=10

# declarative
kubectl apply -f examples/hpa.yaml
```

## Test HPA

Run this in a separate terminal, so that the load generation continues and you can carry on with the rest of the steps

```bash
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://hpa-nginx; done"

# wait some minutes
kubectl get pods
kubectl get hpa
```

![Alt text](./img/hpa-v1-vs-v2.png)

## [API](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#api-object)

The Horizontal Pod Autoscaler is an API resource in the Kubernetes autoscaling API group. The current stable version can be found in the `autoscaling/v2` API version which includes support for scaling on memory and custom metrics. The new fields introduced in `autoscaling/v2` are preserved as annotations when working with `autoscaling/v1`.

## Custom Metrics

Adapter converts external metrics (like from Prometheus) to k8s understadable format for HPA

![Custom Metrics in HPA](img/hpa-custom-metrics.png)

To use custom metrics in HPA, you need to:

1. Remove [metrics-sever](../../kubernetes/metrics-server/Readme.md) if installed, it conflicts when used custom rules
2. [Deploy a custom metrics API server](../../prometheus-grafana/README.md#setup-custom-and-external-metrics-api-server) and monitoring tool, such as [Prometheus](../../prometheus-grafana/README.md).
3. Define custom metrics in your application code, if needed, and expose them through an appropriate endpoint.
4. Configure HPA to use the custom metrics by specifying them in the HPA manifest.

```bash
kubectl apply -f examples/hpa-custom-metrics.yaml

kubectl -n monitoring get --raw "/apis/custom.metrics.k8s.io/v1beta1/" | jq | grep http_requests_per_second

# Test
kubectl run -i --tty load-generator-custom --rm --image=curlimages/curl --restart=Never -- /bin/sh -c "while sleep 0.01; do curl http://hpa-nginx-custom-metrics/fibonacci \
    -H 'Content-Type: application/json' \
    -d '{\"number\": 10}'; done"

kubectl get hpa
```

## External Metrics

To use custom metrics in HPA, you need to:

1. Remove [metrics-sever](../addons/metrics-server/README.md#) if installed, it conflicts when used custom rules
2. [Deploy a custom metrics API server](../../prometheus-grafana/README.md#setup-custom-and-external-metrics-api-server) and monitoring tool, such as [Prometheus](../../prometheus-grafana/README.md).
3. Define custom metrics in your application code, if needed, and expose them through an appropriate endpoint.
4. Configure HPA to use the custom metrics by specifying them in the HPA manifest.

- [Prometheus Adapter External Metrics](https://github.com/kubernetes-sigs/prometheus-adapter/blob/master/docs/externalmetrics.md)
- [Kubernetes HPA Autoscaling with External metrics — Part 1](https://medium.com/@matteo.candido/kubernetes-hpa-autoscaling-with-external-metrics-b225289b9206)
- [Kubernetes HPA Autoscaling with External metrics — Part 2](https://medium.com/@matteo.candido/kubernetes-hpa-autoscaling-with-external-metrics-part-2-dffac36a1f4e)

```bash
kubectl apply -f examples/hpa-external-metrics.yaml

kubectl -n monitoring get --raw "/apis/external.metrics.k8s.io/v1beta1/" | jq | grep memory_usage_percentage
kubectl -n monitoring get --raw "/apis/external.metrics.k8s.io/v1beta1/" | jq | grep cpu_usage_percentage

# Test
kubectl run -i --tty load-generator-external --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://hpa-nginx-external-metrics; done"

kubectl get hpa
```

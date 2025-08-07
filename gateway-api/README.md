# Gateway API

## Architecture

**Gateway ➙ HTTP/TLS/GRPC Routes ➙ Endpoints.**

Gateway API has 3 primary API resources:

- `GatewayClass` defines a set of gateways with a common configuration and behavior.
- `Gateway` requests a point where traffic can be translated to Services within the cluster.
- `Routes` describe how traffic coming via the Gateway maps to the Services.
- [`ReferenceGrant`](https://gateway-api.sigs.k8s.io/api-types/referencegrant/): enable cross namespace references within Gateway API. In particular, Routes may forward traffic to backends in other namespaces, or Gateways may refer to Secrets in another namespace

**API Gateway** requries to install [GatewayClassController](https://gateway-api.sigs.k8s.io/implementations/) to be installed like istio etc. Below installations is just CRDs for GatewayClassControllers

## Install

The latest supported version is v1 as released by the v1.2.0 release of this project.

This version of the API is has GA level support for the following resources:

- `v1.GatewayClass`
- `v1.Gateway`
- `v1.HTTPRoute`
- `v1.GRPCRoute`

```bash
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml; }
# or
kubectl apply -k "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.2.0"
```

Install Experimental Channel

```bash
kubectl apply -k "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v1.2.0"

# to check exp features
$ meld https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/refs/heads/main/config/crd/kustomization.yaml https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/refs/heads/main/config/crd/experimental/kustomization.yaml
- gateway.networking.k8s.io_udproutes.yaml
- gateway.networking.k8s.io_tcproutes.yaml
- gateway.networking.k8s.io_tlsroutes.yaml
- gateway.networking.k8s.io_backendtlspolicies.yaml
- gateway.networking.k8s.io_backendlbpolicies.yaml
```

Install [nginx gateway cotnroller](https://gateway-api.sigs.k8s.io/implementations/#nginx-gateway-fabric)

```bash
helm install ngf oci://ghcr.io/nginxinc/charts/nginx-gateway-fabric --create-namespace -n nginx-gateway
kubectl get gatewayclasses
```

## Test App

- [Bookinfo](https://istio.io/latest/docs/examples/bookinfo/)

```bash
# deploy bookinfo withh al review versions
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.24/samples/bookinfo/platform/kube/bookinfo.yaml
```

## REFERENCE

- [Home](https://gateway-api.sigs.k8s.io/)
- [Github](https://github.com/kubernetes-sigs/gateway-api)
- [k8s](https://kubernetes.io/docs/concepts/services-networking/gateway/)
- [Example tasks from istio](https://istio.io/latest/docs/tasks/traffic-management/)

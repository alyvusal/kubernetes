# Service

[back](../README.md)

## [ExternalName](https://kubernetes.io/docs/concepts/services-networking/service/#externalname)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: externalname
spec:
  type: ExternalName
  externalName: testingmcafeesites.com
```

## externalIPs

```yaml
apiVersion: v1
kind: Service
metadata:
  name: externalips
spec:
  type: ExternalName
  externalIPs:
  - 8.8.8.8
```

# headless service

[back](../README.md)

A headless service is a service with a service IP but instead of load-balancing it will return the IPs of our associated Pods. This allows us to interact directly with the Pods instead of a proxy. It's as simple as specifying `None` for `.spec.clusterIP` and can be utilized with or without selectors

```bash
$ kubectl run --rm utils -it --image eddiehale/utils bash
root@utils:/# nslookup normal-service
root@utils:/# nslookup headless-service
```

# [Static pod](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)

[back](../README.md)

Static Pods are managed directly by the kubelet daemon on a specific node, without the API server observing them. Unlike Pods that are managed by the control plane (for example, a Deployment); instead, the kubelet watches each static Pod (and restarts it if it fails).

Static Pods are always bound to one Kubelet on a specific node.

The kubelet automatically tries to create a [mirror Pod](https://kubernetes.io/docs/reference/glossary/?all=true#term-mirror-pod) (*A pod object that a kubelet uses to represent a static pod*) on the Kubernetes API server for each static Pod. This means that the Pods running on a node are visible on the API server, but cannot be controlled from there. The Pod names will be suffixed with the node hostname with a leading hyphen.

```bash
# Run this command on the node where kubelet is running
ssh my-node1

mkdir -p /etc/kubernetes/manifests/
cat <<EOF >/etc/kubernetes/manifests/static-web.yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-web
  labels:
    role: myrole
spec:
  containers:
    - name: web
      image: nginx
      ports:
        - name: web
          containerPort: 80
          protocol: TCP
EOF

# Configure the kubelet on that node to set a staticPodPath value in the kubelet configuration file (/var/lib/kubelet/config.yaml).
# Default: staticPodPath: /etc/kubernetes/manifests

systemctl restart kubelet
```

The running kubelet periodically scans the configured directory (/etc/kubernetes/manifests in our example) for changes and adds/removes Pods as files appear/disappear in this directory.

An alternative and deprecated method is to configure the kubelet on that node to look for static Pod manifests locally, using a command line argument. To use the deprecated approach, start the kubelet with the
`--pod-manifest-path=/etc/kubernetes/manifests/` argument.

## REFERENCE

- [Kubelet config file: /var/lib/kubelet/config.yaml](https://kubernetes.io/docs/tasks/administer-cluster/kubelet-config-file/)
- [Kubelet config reference](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/)

# kubernetes exam questions

[back](../README.md)

## 1. Write pods_asc.sh script to list pods by ascending AGE order

```bash
echo 'kubectl get pods -A --sort-by .metadata.creationTimestamp | tac' > pods_asc.sh
```

## 2. Write static pod with nginx image in node01 and make sure will restart/recreate when fails

```bash
# note pod manifest file
kubectl run --image nginx -o yaml --dry-run=client nginx

# get node name and ssh to it
kubectl get nodes
ssh node-01

# find config file
ps aux | grep kubelet  # note config file
cat <config file> | grep staticPodPath  # most probably will be /etc/kubernetes/manifests#

# create static pod
cd <staticPodPath>
# if forget what was pod manifest definition:0
# * use previously noted pod manifest from yaml output
# * cat any file in <staticPodPath> to see example
# * try: kubectl run --image nginx -o yaml --dry-run=client nginx
cat etcd.yaml

nano nginx-static.yaml
 ...

# check result, try delete pod. it must recreate
$ kubectl get pods
```

## 3. Write multi pod manifest. One of it will be nginx,a nother one will be busybox with command 'sleep 4800'

```bash
kubectl run --image nginx -o yaml --dry-run=client multi > multi_pod.yaml
nano multi_pod.yaml
```

multi_pod.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: multi
  name: multi
spec:
  containers:
  - image: nginx
    name: multi
  - name: busybox
    image: busybox
    command: ["sleep", "4800"]
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

## 4. Create delta-pod in defense namespace, with image nginx:1.8 and labels env=dev, tier=front

```bash
kubectl create ns defense
kubectl run delta-pod --image=nginx:1.8 -n defence --labels env=dev,tier=front
kubectl -n defence get pods --show-labels
kubectl -n defence describe pod delta-pod | grep -i image
```

## 5. Create admin-pod with busybox image. Allow pod set system_time and sleep 3200

```bash
kubectl run admin-pod --image busybox --command sleep 3200 -o yaml --dry-run=client > admin-pod.yaml
```

 go to [Set capabilities for a Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-containercontext/)

find & add below to pod manifest

```yaml
    securityContext:
      capabilities:
        add: ["SYS_TIME"]
```

## 6. Troubleshoot and fix kubeconfig file in /tmp folder

Compare with current used kubeconfig file. Check server url. Useful commands

```bash
kubectl config view
```

## 7. Create deployment with image nginx:1.16, 1 replica. Then upgrade to nginx:1.17 with rollingUpdate. Record upgrade in annotation

```bash
kubectl create deployment nginx --image nginx:1.16

# get container name
kubectl describe deploy nginx

kubectl set image deployment/nginx nginx=nginx:1.17 --record

# check if record written
kubectl rollout history deployment nginx
```

## 8. Create web-pod with image nginx, expose it with service web-pod-svc. With busybox:1.28 do dns lookup for service and pod and write result to web-pod-svc.svc and web-pod.pod

```bash
$ kubectl run web-pod --image nginx
$ kubectl expose pod web-pod --name web-pod-svc --port 80
$ kubectl run test --image busybox:1.28 --command sleep 3200

# check svc dns
$ kubectl exec -ti test -- nslookup webpod-svc
$ kubectl describe svc webpod-svc

# check pod dns
# ! remember: POD can not be queried with name, only with ip
# kubectl exec -ti test -- nslookup <ip-with-dash>.<namespace>.pod
$ kubectl get pods -o wide
NAME      READY   STATUS    RESTARTS   AGE     IP           NODE           NOMINATED NODE   READINESS GATES
web-pod   1/1     Running   0          3m31s   10.244.1.2   kind-worker    <none>           <none>

$ kubectl exec -ti test -- nslookup 10-244-1-2.default.pod
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      10-244-1-2.default.pod
Address 1: 10.244.1.2 10-244-1-2.webpod-svc.default.svc.cluster.local

$ kubectl exec -ti test -- nslookup 10.244.1.2
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      10.244.1.2
Address 1: 10.244.1.2 10-244-1-2.webpod-svc.default.svc.cluster.local
```

## 9. Use JSON path to retrieve `osImage` of all nodes. `osImage` are under the `nodeInfo` section under status of each node

```bash
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.osImage}'
```

## 10. Create volume with namepv-rnd, 100Mi size, access mode ReadWriteMany, host path /pv/host_data_rnd

go to [docs](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath-configuration-example)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: namepv-rnd
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: /pv/host_data_rnd
```

## 11. kubernetes node is not responding, check it

```bash
ssh node01
systemctl status kubelet
```

## 12. List `InternalIP` of all nodes in cluster. Write to file in format '< InternalIP of 1st node > < InternalIP of 2nd node ... >' in single line

go to  [cheet sheet](https://kubernetes.io/docs/reference/kubectl/quick-reference/?ref=faun)

```bash
# find below:
# Get ExternalIPs of all nodes
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}'

# now write it for InternalIP
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'
```

## 13. Move static pod running on control plane to worker node

You can use method from [2nd question](#2-write-static-pod-with-nginx-image-in-node01-and-make-sure-will-restartrecreate-when-fails) to get pod details and create on worker node

## 14. Create new deployment web-003. Scale deployment to 3 and make sure desired number od pod always running. (In exam pod will not start, needs tshoot)

```bash
$ kubectl create deployment web-003 --image nginx --replicas 3
$ kubectl -n kube-system logs kube-controller-manager-kind-control-plane
$ kubectl -n kube-system describe pod kube-controller-manager-kind-control-plane
...
kube-controller-man not found ...
...

# go to controller manager, edit manifest
ssh controller-node
cd /etc/kubernetes/manifests
nano kube-controller-manager.yaml
```

wrong: ~~kube-controller-man~~  
correct: kube-controller-manager

## 15. Upgrade cluster from 1.18 o 1.19. Make sure drain nodes before upgrade

upgrade master nodes, see [docs](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)

```bash
kubectl get nodes
kubectl drain kind-control-plane --ignore-daemonsets

kubeadm upgrade plan

apt upgrade kubeadm-1.27.9
kubeadm apply v1.27.9
# for other control planes nodes use below instead of apply
# kubeadm upgrade node

apt upgrade kubelet-1.27.9
systemctl restart kubelet

kubectl get nodes
kubectl uncordon kind-control-plane
```

proceed with same step for worker nodes

## 16. get `osImage` of of worker nodes with jsonpath

same as [question 9](#9-use-json-path-to-retrieve-osimage-of-all-nodes-osimage-are-under-the-nodeinfo-section-under-status-of-each-node)

## 17. deploy pod with label

use [question 4](#4-create-delta-pod-in-defense-namespace-with-image-nginx18-and-labels-envdev-tierfront)

## 18. create pod write 'binaries downlaoded successfully' to file helper.log and exit. pod should be delete when it completed

```bash
kubectl run helper --restart=Never --image busybox --rm -it -- sh -c 'echo binaries downlaoded successfully' > helper.log
```

## 19. Check how many nodes are in `Ready` state and write information bout nodes tainted with `NoShcedule`

At least one nodes' tains information should be logged in a file with below format

```json
{ "name": "<<node_value>>",
  "taints": "<<value>>"
}
{ "name": "<<node_value>>",
  "taints": "<<value>>"
}
```

```bash
# create taint to see where it locates in json
$ kubectl taint node kind-worker cpu=high:NoSchedule

# get output
$ kubectl get nodes -o json | jq '.items[]|{name:.metadata.name, taints:.spec.taints}'

{
  "name": "kind-control-plane",
  "taints": [
    {
      "effect": "NoSchedule",
      "key": "node-role.kubernetes.io/control-plane"
    }
  ]
}
{
  "name": "kind-worker",
  "taints": [
    {
      "effect": "NoSchedule",
      "key": "cpu",
      "value": "high"
    }
  ]
}
{
  "name": "kind-worker2",
  "taints": null
}
{
  "name": "kind-worker3",
  "taints": null
}
```

## 20. Create namespace airfusion, create network polic my-net-pol in airfusion namespace

Requriements:

- allow pods conect each other on port 80 only
- no pod outside of airfusion namespace should be able to connect to any pod inside this namespace

get sample from [doc](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

```bash
kubectl create ns airfusion
kubectl run nginx --image nginx --namespace airfusion
```

network policy

```yaml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-port-80-internally
  namespace: airfusion
spec:
  policyTypes:
  - Ingress
  ingress:
  - ports:
    - protocol: TCP
      port: 80
```

## 21. Pod listens on port 8080, expose it on node port 30002

```bash
kubectl get pods
kubectl describe pod nginx

kubectl expose pod nginx --name nginx-svc --type NodePort --dry-run=client -o yaml > svc.yaml

nano svc.yaml
```

add `nodePort` syntax under `port``

```yaml
spec:
- port: 8080
  protocol: TCP
  targetPort: 8080
  nodePort: 30002
```

```bash
kubectl apply -f svc.yaml
```

## 22. Taint worker node with tains details below. Create dev-pod nginx and make sure will not shcedule on worker node. Create another pod prod-pod with tolerations to shcedle on worker node

Details:

- key: env_type
- value: prod
- operator: equal
- effect: no schedule

Taint node

```bash
kubectl taint node kind-worker env_type=prod:NoSchedule
kubectl describe node kind-worker | grep -i taint

# to delete taint
kubectl taint node kind-worker env_type-
```

Create deployment and check on which nodes pods are running

```bash
kubectl create deployment nginx --image nginx --replicas 3
kubectl get pods -o wide
```

Now create enw deployment with taint. See [docs](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)

```bash
kubectl create deployment nginx-prod --image nginx --replicas 3 --dry-run=client -o yaml > prod.yaml

nano prod.yaml
```

add following syntax

```yaml
spec:
  template:
    spec:
      tolerations:
      - key: "env_type"
        value: "prod"
        operator: "Equal"
        effect: "NoSchedule"
```

```bash
kubectl apply -f prod.yaml
kubectl get pdos -o wide
```

## 23. Create pod with image redis and with security context (runAsUSer: 1000, fsGroup: 2000)

see [doc](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

```bash
kubectl run mypod --image redis --dry-run=client -o yaml > pod.yaml
nano pod.yaml
```

add below

```yaml
spec:
  securityContext:
    runAsUser: 1000
    fsGroup: 2000
```

```bash
$ kubectl exec mypod -- whoami
whoami: cannot find name for user ID 1000
command terminated with exit code 1
```

## 24. Get worker node info in json format

```bash
kubectl get node kind-worker -o json
```

## 25. Take backup of etcd database

```bash
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kuebrnetes/pki/etcd/ca.crt \
  --cert=/etc/kuebrnetes/pki/etcd/server.crt \
  --key=/etc/kuebrnetes/pki/etcd/server.key \
  snapshot save backup.bak
```

## 26. Pod has issue, identify it. No config change allowed. You can delete, fix command and recreate it if needed

## 27. Create user john, grant him access to the cluster. Give permissions to create, list, get, update, delete pods in the namespace

Private key exists in /root/john.key and csr at /root/john.csr

see [doc](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#create-certificatessigningrequest)

get abse64 encoded CSR and replace in above CertificateSigningRequest

```bash
# below two command is just fpr local test
openssl genrsa -out john.key 2048
openssl req -new -key john.key -out myuser.csr -subj "/CN=john"

CSR=(cat /root/john.csr | base64 | tr -d "\n")
```

```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: john
spec:
  request: $CSR
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
```

approve csr

```bash
kubectl get csr
kubectl certificate approve john
```

Export the issued certificate from the CertificateSigningRequest.

```bash
kubectl get csr john -o jsonpath='{.status.certificate}'| base64 -d > /root/john.crt
```

Create Role and RoleBinding

```bash
kubectl create role john --verb=create --verb=get --verb=list --verb=update --verb=delete --resource=pods
kubectl create rolebinding developer-binding-john --role=john --user=john
```

Add to kubeconfig

```bash
kubectl run nginx --image nginx --as john
kubectl get pod --as john
kubectl delete pod nginx --as john
#or
kubectl config set-credentials john --client-key=/root/john.key --client-certificate=/root/john.crt --embed-certs=true
kubectl config set-context john --cluster=kubernetes --user=john
kubectl config use-context john
```

## 28. Create pv, pvc and pods with following specs

![Question 27](img/q27.png)

see [doc](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

pv

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mypvlog
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /pv/log
```

pvc

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pv-claim-log
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Mi
```

pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
    - name: myfrontend
      image: nginx
      volumeMounts:
      - mountPath: "/log"
        name: mypd
  volumes:
    - name: mypd
      persistentVolumeClaim:
        claimName: my-pv-claim
```

## 29. Worker node not responding, fix it

Most probably cert file is wrong in /var/lib/kubelet/config.yaml

## 30. Pod is not running, fix it

Remove pvc, fix hostPath in pv, recreate pvc and pod. pvc was on wrong namespace

## 31. Create multi contaienr pod with nginx and redis

```bash
kubectl run multi-pod --image nginx dry-run=client -o yaml > multi-pod.yaml
nano multi-pod.yaml
```

add redis also to yaml

```yaml
spec:
  containers:
    - name: multi-pod
      image: nginx
    - name: redis
      image: redis
```

## 32. pod is not running, fix it

Check taints of node, add toleration to pod

## 33. Create deployment nginx iwth 8 replica and make sure pods will not run on worker-2 and worker-3

```bash
kubectl cordon worker-2
kubectl cordon worker-3
kubectl create deploy nginx --image=nginx --replicas 8

kubectl uncordon worker-2
kubectl uncordon worker-3
```

## 34. Create replicaset web-pod with 3 pod, but also there is a pod running already. Make sure max 3 pod will run

```bash
$ kubectl get pod --show-labels 
NAME       READY   STATUS    RESTARTS   AGE   LABELS
demo-pod   1/1     Running   0          10s   app=web

$ kubectl -n kube-system get rs
NAME                 DESIRED   CURRENT   READY   AGE
coredns-5d78c9869d   2         2         2       6h21m

$ kubectl -n kube-system get rs coredns-5d78c9869d -o yaml > rs.yaml
```

result replicaset will be like:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  labels:
    app: web
  name: web-pod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx
```

## 35. There are 3 node in the cluster. Create daemonset my-pod, image nginx on each node except worker-3

```bash
$ kubectl -n kube-system get ds
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kindnet      4         4         4       4            4           kubernetes.io/os=linux   6h29m
kube-proxy   4         4         4       4            4           kubernetes.io/os=linux   6h29m

$ kubectl taint node kind-worker3 env=qa:NoSchedule
$ kubectl -n kube-system get ds kube-proxy -o yaml > ds.yaml
# remove toleration from yaml
```

daemonset will be like

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: my-pod
spec:
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - image: nginx
        name: nginx
```

# Storage and Volumes

[back](../README.md)

- [concept](https://kubernetes.io/docs/concepts/storage/)
- [tasks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/)
- [volumes](https://kubernetes.io/docs/concepts/storage/volumes)

## Theory

- Volume: Resides inside pod
- Persistent volume: is a separate kubernetes object like a pod

## [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)

- [configMap](https://kubernetes.io/docs/concepts/storage/volumes/#configmap) ([sample](./volumes/configMap.yml))
- [secret](https://kubernetes.io/docs/concepts/storage/volumes/#secret)
- [downwardAPI](https://kubernetes.io/docs/concepts/storage/volumes/#downwardapi) ([sample](./volumes/downwardAPI.yml))
  - About [Downward API](https://kubernetes.io/docs/concepts/workloads/pods/downward-api/)
  - [task](https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/)
- [emptyDir](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir) ([sample](./volumes/emptyDir.yml))
- [hostPath](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath-volume-types) ([sample](./volumes/hostPath.yml))
  - [Using subpath](https://kubernetes.io/docs/concepts/storage/volumes/#using-subpath) ([sample](./volumes/subPath.yml))
  - [Using subPath with expanded environment variables](https://kubernetes.io/docs/concepts/storage/volumes/#using-subpath-expanded-environment) ([sample](./volumes/subPathExpr.yml))
- [iscsi](https://kubernetes.io/docs/concepts/storage/volumes/#iscsi)
- [local](https://kubernetes.io/docs/concepts/storage/volumes/#local) ([sample volume](./volumes/local.yml) and related [sc](./storage/local.yml))
- [nfs](https://kubernetes.io/docs/concepts/storage/volumes/#nfs) ([sample](./volumes/nfs.yml))
- [projected](https://kubernetes.io/docs/concepts/storage/volumes/#projected)
- [csi](https://kubernetes.io/docs/concepts/storage/volumes/#csi)

Setting accessModes in a PV tells Kubernetes how this storage resource can be used, based on its capabilities.

### [Projected Volumes](https://kubernetes.io/docs/concepts/storage/projected-volumes/)

A projected volume is a composite volume — it lets you combine multiple volume sources (e.g., secrets, configMaps, serviceAccountToken, downwardAPI) into a single volume mount point.

Currently, the following types of volume sources can be projected:

- [secret](https://kubernetes.io/docs/concepts/storage/volumes/#secret)
- [downwardAPI](https://kubernetes.io/docs/concepts/storage/volumes/#downwardapi)
- [configMap](https://kubernetes.io/docs/concepts/storage/volumes/#configmap)
- [serviceAccountToken](https://kubernetes.io/docs/concepts/storage/projected-volumes/#serviceaccounttoken)
- [clusterTrustBundle](https://kubernetes.io/docs/concepts/storage/projected-volumes/#clustertrustbundle)

DevSecOps & Security Notes:

- projected.serviceAccountToken is not the same as the Pod’s default token.
- It allows you to project a short-lived (rotatable) token for finer-grained access control.
- Useful for workload identity and least privilege design.
- Keeps mount directories clean (e.g., /etc/config instead of multiple submounts).

Before projected volumes introduced serviceAccountToken projection:

- Every Pod automatically got a long-lived token (until Pod deletion)
- The token had cluster-wide permissions for that ServiceAccount
- Tokens weren’t auto-rotated, posing security risks

The projected.serviceAccountToken solved this:

```yaml
serviceAccountToken:
  path: token
  expirationSeconds: 3600
  audience: "vault"
```

✅ Benefits:

- Token is short-lived and auto-rotated
- Scoped to a specific audience (Vault, external service, etc.)
- No default mounting — you explicitly opt in

This was a huge security improvement that required the projected mechanism (couldn’t be done with old secret or configMap volume types).

```bash
host $ kubectl exec -it projected-volume-test -- sh
$ ls -l /projected-volume/
total 0
lrwxrwxrwx    1 root     root            18 Feb 27 11:42 annotations -> ..data/annotations
lrwxrwxrwx    1 root     root            16 Feb 27 11:42 cpu_limit -> ..data/cpu_limit
lrwxrwxrwx    1 root     root            13 Feb 27 11:42 labels -> ..data/labels
lrwxrwxrwx    1 root     root            15 Feb 27 11:42 my-group -> ..data/my-group
lrwxrwxrwx    1 root     root            12 Feb 27 11:42 token -> ..data/token
$ cat /projected-volume/annotations
kubectl.kubernetes.io/last-applied-configuration="{\"apiVersion\":\"v1\",\"kind\":\"Pod\",\"metadata\":{\"annotations\":{},...
$ cat /projected-volume/cpu_limit
8
$ cat /projected-volume/labels
volume="projected"
$ ls /projected-volume/my-group
my-config    my-username
$ cat /projected-volume/my-group/my-config
My configuration
$ cat /projected-volume/my-group/my-username
Vusal Aliyev
$ cat /projected-volume/token
eyJhbGciOiJSUzI1NiIs.....
```

### [Ephemeral Volumes](https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/)

### [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)

- If storageClassName"", then it is static provisioning
- If storageClassName is not specified, then the default storage class will be used.
- If storageClassName is set to a specific value, then the matching storageClassName will be considered. If no corresponding storage class exists, the PVC will fail.

provisioning:

- In static provisioning, PV needs to be declared explicitly and SC is not needed
- In dynamic provisioning, SC is required so we can specify provisioner and the parameters needed by the provisioner. PV doesn’t need to be explicitly declared, even though it exists in the interaction.

[Kubernetes Storage Explained – from in-tree plugin to CSI](https://www.digihunch.com/2021/06/kubernetes-storage-explained/)

## [Persistent Volume & Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

AccessModes in a PVC specify what access mode the Pod requires for its storage.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: foo-pvc
  namespace: foo
spec:
  storageClassName: "" # Empty string must be explicitly set otherwise default StorageClass will be set
  volumeName: foo-pv  # which PV to bind
  ...
```

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: foo-pv
spec:
  storageClassName: ""
  claimRef:
    name: foo-pvc  # which PVC to allow for binding to this PV
    namespace: foo
```

## Persistent Volume Claim

## [Volume Snapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/)

So the correct ordering should be:

1. [Install the Volume Snapshot Custom Resource Definitions (CRDs) and Volume Snapshot controller](#install-snapshot-crds)
2. Install the CSI Driver
3. create a Volume Snapshot Class and Volume Snapshot

A `VolumeSnapshotClass` defines a class of storage associated with a snapshot. This is similar to a `StorageClass` for a `PersistentVolumeClaim`. A `VolumeSnapshotClass` allows an administrator to define the level of service that a particular snapshot will receive on the underlying storage.

A `VolumeSnapshot` is a request to take a snapshot, and it is similar to a `PersistentVolumeClaim`. CSI controllers watch for the creation of a VolumeSnapshot, and they fulfill the request by interacting with the underlying storage to take a snapshot.

A `VolumeSnapshotContent` represents the fulfilled claim for a `VolumeSnapshot` on the underlying storage. It contains information about the snapshot on the storage, such as a snapshot ID or a path. This is analogous to a `PersistentVolume`.

![alt text](img/snapshot.png)

### [Test snapshot in kind cluster with hostPath CSI](https://medium.com/linux-shots/point-in-time-snapshot-of-persistent-volume-data-with-kubernetes-volume-snapshots-abfafc210802)

- [external-snapshotter](https://github.com/kubernetes-csi/external-snapshotter)
- [install](https://github.com/kubernetes-csi/csi-driver-host-path/blob/master/docs/deploy-1.17-and-later.md)

```bash
./deploy-hostpath-csi.sh install
```

[examples](https://github.com/kubernetes-csi/csi-driver-host-path/tree/release-1.15/examples)

```bash
# Deploy storage class using below command
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-hostpath-sc
provisioner: hostpath.csi.k8s.io
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: csi-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: csi-hostpath-sc
EOF

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-csi-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-csi-app
  template:
    metadata:
      labels:
        app: my-csi-app
    spec:
      containers:
        - name: my-frontend
          image: busybox
          volumeMounts:
          - mountPath: "/data"
            name: my-csi-volume
          command: [ "sleep", "1000000" ]
      volumes:
        - name: my-csi-volume
          persistentVolumeClaim:
            claimName: csi-pvc
EOF

kubectl exec -it <pod-name-of-app> -- sh
echo "This is version 1" > /data/version.txt

cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: csi-hostpath-sc
driver: hostpath.csi.k8s.io
deletionPolicy: Delete
EOF

cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: new-snapshot-demo
spec:
  volumeSnapshotClassName: csi-hostpath-sc
  source:
    persistentVolumeClaimName: csi-pvc
EOF

kubectl get VolumeSnapshot new-snapshot-demo
kubectl get VolumeSnapshotContent

kubectl exec -it <pod-name-of-app> -- sh
echo "This is version 2" > /data/version.txt

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: csi-pvc-restored
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: csi-hostpath-sc
  dataSource:
    name: new-snapshot-demo
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
EOF

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-csi-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-csi-app
  template:
    metadata:
      labels:
        app: my-csi-app
    spec:
      containers:
        - name: my-frontend
          image: busybox
          volumeMounts:
          - mountPath: "/data"
            name: my-csi-volume
          command: [ "sleep", "1000000" ]
      volumes:
        - name: my-csi-volume
          persistentVolumeClaim:
            claimName: csi-pvc-restored
EOF

kubectl exec -it <pod-name> -- cat /data/version.txt

# Create clone of a PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: csi-pvc-clone
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: csi-hostpath-sc
  dataSource:
    name: csi-pvc
    kind: PersistentVolumeClaim
EOF
```

### [Install snapshot CRDs](https://github.com/kubernetes-csi/external-snapshotter)

```bash
git clone https://github.com/kubernetes-csi/external-snapshotter.git

# Install Snapshot and Volume Group Snapshot CRDs
kubectl kustomize external-snapshotter/client/config/crd | kubectl create -f -
# or
kubectl apply -n kube-system -k https://github.com/kubernetes-csi/external-snapshotter/client/config/crd

# Install Common Snapshot Controller
kubectl -n kube-system kustomize external-snapshotter/deploy/kubernetes/snapshot-controller | kubectl create -f -
# or
kubectl apply -n kube-system -k https://github.com/kubernetes-csi/external-snapshotter/deploy/kubernetes/snapshot-controller

# Install CSI Driver
# Follow instructions provided by your CSI Driver vendor.
# Here is an example to install the sample hostpath CSI driver (not neede for AWS, it is just buggy example not for production usage)
kubectl kustomize external-snapshotter/deploy/kubernetes/csi-snapshotter | kubectl create -f -
# or
kubectl apply -k https://github.com/kubernetes-csi/external-snapshotter/deploy/kubernetes/csi-snapshotter
```

or

```bash
# Install Snapshot and Volume Group Snapshot CRDs
kubectl apply -k 'github.com/kubernetes-csi/external-snapshotter/client/config/crd?ref=v8.1.0'

# Install Common Snapshot Controller
kubectl -n kube-system apply -k 'github.com/kubernetes-csi/external-snapshotter/deploy/kubernetes/snapshot-controller?ref=v8.1.0'

# Install CSI Driver
# Follow instructions provided by your CSI Driver vendor.
# Here is an example to install the sample hostpath CSI driver (not neede for AWS, it is jus example)
kubectl apply -k 'github.com/kubernetes-csi/external-snapshotter/deploy/kubernetes/csi-snapshotter?ref=v8.1.0'
```

Do this once per cluster

### CSI driver

- [Script to verify CSI configuration](https://docs.cloudcasa.io/help/kbs/kb-csi-checker.html)
- [Manually verifying CSI configuration](https://docs.cloudcasa.io/help/kbs/kb-csi-checker-manual.html)

if not installed with teraform then install it also

```bash
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=v1.36.0"
```

```bash
kubectl get pvc
kubectl get pv

kubectl get volumesnapshot # or vs
kubectl get volumesnapshotcontent # or vsc
```

Now you are ready to use this volumesnapshot resource to restore the data to new PVC resource. To do that apply resource definition in the below.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: <new-pvc-name>
  namespace: <namespace-name>
spec:
  storageClassName: <storageclass-name>
  dataSource:
    name: <VolumeSnapshotName>
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi # Be careful, it must be same size of volumesnapshot
```

### REFERENCE

- https://itnext.io/understanding-kubernetes-volume-snapshots-965de50870eb

## Storage

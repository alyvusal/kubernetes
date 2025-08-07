#!/bin/bash

echo "Pulling csi-driver-host-path.git ..."
cd ~/test
if [ -d csi-driver-host-path ]; then
  cd csi-driver-host-path
  git pull
else
  git clone https://github.com/kubernetes-csi/csi-driver-host-path.git
  cd csi-driver-host-path
fi

case "$1" in
install|i)
  echo "Install VolumeSnapshot CRDs and snapshot controller (external-snapshotter)"
  # Change to the latest supported snapshotter release branch
  SNAPSHOTTER_BRANCH=release-8.2
  # Apply VolumeSnapshot CRDs
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_BRANCH}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_BRANCH}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_BRANCH}/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml

  SNAPSHOTTER_VERSION=v8.2.0
  # Create snapshot controller
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
  kubectl get volumesnapshotclasses.snapshot.storage.k8s.io

  echo "Deploy hostPath CSI driver and SC"
  deploy/kubernetes-latest/deploy.sh
  HOSTPATH_BRANCH=release-1.15
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-host-path/${HOSTPATH_BRANCH}/examples/csi-storageclass.yaml
  kubectl get sc
  ;;
remove|r)
  kubectl delete sc csi-hostpath-sc
  deploy/kubernetes-latest/destroy.sh
  ;;
*)
esac

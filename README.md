# nfs-subdir-external-provisioner-exporter

Prometheus exporter for the [nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner).

🐋 Docker Hub: [weibeld/nfs-subdir-external-provisioner-exporter](https://hub.docker.com/r/weibeld/nfs-subdir-external-provisioner-exporter)

## Description

Exports storage usage metrics about the NFS share managed by the nfs-subdir-external-provisioner.

## Usage in Kubernetes

### Setup

- Run as a sidecar container in the nfs-subdir-external-provisioner Pod
- Set the following environment variables:
  - `NFS_SERVER`: same value as for the nfs-subdir-external-provisioner container (required)
  - `NFS_PATH`: same value as for the nfs-subdir-external-provisioner container (required)
  - `INTERVAL`: metric refresh interval in seconds (default 15 sec)
- Mount the node root file system at any location in the container

### Example

Add the following to your [Pod spec](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.22/#podspec-v1-core):

```yaml
spec:
  containers:
    - ...
    - name: nfs-subdir-external-provisioner-exporter
      image: weibeld/nfs-subdir-external-provisioner-exporter:0.0.1
      env:
        - name: NFS_SERVER
          value: <nfs-server-hostname>
        - name: NFS_PATH
          value: <nfs-share-path>
        - name: INTERVAL
          value: 30
      ports:
        - containerPort: 9867
          name: metrics
      volumeMounts:
        - name: host
          mountPath: /host
          readOnly: true
  volumes:
    - name: host
      hostPath:
        path: /
```

### Result

Metrics are exposed over HTTP on port 9867 at the `/metrics` path.

## Metrics

The exporter currently exports the following metrics:

| Metric | Description |
|--------|-------------|
| `nfs_size_bytes` | Total size of the NFS share |
| `nfs_used_bytes` | Space on the NFS share that is currently used |
| `nfs_available_bytes` | Space on the NFS share that is available to ordinary users |

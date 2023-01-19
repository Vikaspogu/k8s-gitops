# Cluster Notes

## etcd de-fragmentation

On one of your master nodes create `etcdctl-install.sh`:

```bash
#!/usr/bin/env bash

set -eux

etcd_version=v3.5.3

case "$(uname -m)" in
    aarch64) arch="arm64" ;;
    x86_64) arch="amd64" ;;
esac;

etcd_name="etcd-${etcd_version}-linux-${arch}"

curl -sSfL "https://github.com/etcd-io/etcd/releases/download/${etcd_version}/${etcd_name}.tar.gz" \
    | tar xzvf - -C /usr/local/bin --strip-components=1 "${etcd_name}/etcdctl"

etcdctl version
```

and then:

```bash
chmod +x etcdctl-install.sh
./etcdctl-install.sh
```

and then:

```bash
export ETCDCTL_ENDPOINTS="https://127.0.0.1:2379"
export ETCDCTL_CACERT="/var/lib/rancher/k3s/server/tls/etcd/server-ca.crt"
export ETCDCTL_CERT="/var/lib/rancher/k3s/server/tls/etcd/server-client.crt"
export ETCDCTL_KEY="/var/lib/rancher/k3s/server/tls/etcd/server-client.key"
export ETCDCTL_API=3
etcdctl defrag --cluster
# Finished defragmenting etcd member[https://192.168.42.10:2379]
# Finished defragmenting etcd member[https://192.168.42.12:2379]
# Finished defragmenting etcd member[https://192.168.42.11:2379]
```

### Ceph crash alerts

```bash
ceph health detail
ceph crash ls-new
ceph crash archive-all
```

### Increase size

```bash
sudo vgs
sudo lvextend -l +100%FREE  /dev/mapper/fedora-root
sudo xfs_growfs /dev/mapper/fedora-root
```

## Rook Manual Data Backup

### Create the toolbox container

!!! info "Ran from your workstation"

```sh
kubectl -n rook-ceph exec -it (kubectl -n rook-ceph get pod -l "app=rook-direct-mount" -o jsonpath='{.items[0].metadata.name}') bash
```

!!! info "Ran from the `rook-ceph-toolbox`"

```sh
mkdir -p /mnt/nfsdata
mkdir -p /mnt/data
mount -t nfs -o "hard" ${NAS_ADDRESS}:/volume1/media /mnt/nfsdata
```

### Backup data to a NFS share

!!! info "Ran from your workstation"

- Pause the Flux Helm Release

```sh
flux suspend hr home-assistant -n home
```

- Scale the application down to zero pods

```sh
kubectl scale deploy/home-assistant --replicas 0 -n home
```

- Get the `csi-vol-*` string

```sh
kubectl get pv/(kubectl get pv | grep home-assistant-config-v1 | awk -F' ' '{print $1}') -n home -o json | jq -r '.spec.csi.volumeAttributes.imageName'
```

!!! info "Ran from the `rook-ceph-toolbox`"

```sh
rbd map -p ceph-blockpool csi-vol-ce119f59-7a03-11ec-8b4d-aad55160f32f | xargs -I{} mount {} /mnt/data
tar czvf /mnt/nfsdata/k8s-data/rook/Backups/readarr.tar.gz -C /mnt/data/ .
umount /mnt/data
rbd unmap -p ceph-blockpool csi-vol-ce119f59-7a03-11ec-8b4d-aad55160f32f
```

## Manual Data Restore

Create the toolbox container

### Restore data from a NFS share

!!! info "Ran from your workstation"

- Apply the PVC

```sh
kubectl apply -f cluster/apps/home/home-assistant/config-pvc.yaml
```

- Get the `csi-vol-*` string

```sh
kubectl get pv/(kubectl get pv | grep home-assistant-config-v1 | awk -F' ' '{print $1}') -n home -o json | jq -r '.spec.csi.volumeAttributes.imageName'
```

!!! info "Ran from the `rook-ceph-toolbox`"

```sh
rbd map -p ceph-blockpool csi-vol-11808e37-847f-11ec-ae2a-ae8a10a2dbb1 \
    | xargs -I{} sh -c 'mkfs.ext4 {}'
rbd map -p ceph-blockpool csi-vol-11808e37-847f-11ec-ae2a-ae8a10a2dbb1 \
    | xargs -I{} mount {} /mnt/data
tar xvf /mnt/nfsdata/k8s-data/rook/Backups/readarr.tar.gz -C /mnt/data
umount /mnt/data
rbd unmap -p ceph-blockpool csi-vol-11808e37-847f-11ec-ae2a-ae8a10a2dbb1
rbd unmap -p ceph-blockpool csi-vol-11808e37-847f-11ec-ae2a-ae8a10a2dbb1
```

## loki

Enable syslog, do this on each host and replace `target` IP (and maybe `port`) with you syslog `externalIP` that is defined [here](../archive/loki/helm-release.yaml)

Create file `/etc/rsyslog.d/50-promtail.conf` with the following content:

```bash
module(load="omprog")
module(load="mmutf8fix")
action(type="mmutf8fix" replacementChar="?")
action(type="omfwd" protocol="tcp" target="192.168.42.155" port="1514" Template="RSYSLOG_SyslogProtocol23Format" TCP_Framing="octet-counted" KeepAlive="on")
```

Restart rsyslog and view status

```bash
sudo systemctl restart rsyslog
sudo systemctl status rsyslog
```

In Grafana, on the explore tab, you should now be able to view you hosts logs, e.g. this query `{host="k3s-master"}`

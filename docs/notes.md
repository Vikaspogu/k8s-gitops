# Notes

1. [Operating System](#os)
2. [Etcd](#etcd)
3. [Ceph](#ceph)

## OS

### Resize

```bash
sudo vgs
sudo lvextend -l +100%FREE  /dev/mapper/fedora-root
sudo xfs_growfs /dev/mapper/fedora-root
```

```bash
resize2fs /dev/sda2 #Debian
```

```bash
sudo growpart /dev/mmcblk0 3
sudo xfs_growfs -d /
```

### Remove old kernel

```bash
sudo dnf remove --oldinstallonly --setopt installonly_limit=2 kernel -y
```

### Networking (Fedora)

```bash
vi /etc/default/grub
GRUB_CMDLINE_LINUX line append "net.ifnames=0 biosdevname=0"
grub2-mkconfig -o /boot/grub2/grub.cfg
```

```bash
cat /etc/sysconfig/network-scripts/ifcfg-eno1
<< EOF
DEVICE="eno1"
BOOTPROTO="static"
HWADDR=""
IPADDR=
NETMASK=255.255.255.0
ONBOOT="yes"
EOF
```

```bash
cat /etc/udev/rules.d/60-net.rules
<< EOF
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="$(cat /sys/class/net/enp3s0/address)", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eno1"
EOF
```

Reboot

```bash
reboot
```

### Ubuntu Raspberry Pi using Flash

> All these commands are run from your computer, not the RPi.

### Downloads the Flash tool

```bash
curl -LO https://github.com/hypriot/flash/releases/download/2.7.2/flash
chmod +x flash
sudo mv flash /usr/local/bin/flash
```

### Download and extract the image

```bash
cd ~/Downloads
curl -L "https://cdimage.ubuntu.com/releases/20.04.5/release/ubuntu-20.04.5-preinstalled-server-arm64+raspi.img.xz" -o ubuntu-20.04.5-preinstalled-server-arm64+raspi.img.xz
unxz -T 0 ~/Downloads/ubuntu-20.04.5-preinstalled-server-arm64+raspi.img.xz
```

### Configure

Update cloud-config.example.yml as you see fit.

### Flash

```bash
flash --userdata setup/cloud-config.yml \
    ~/Downloads/ubuntu-20.04.5-preinstalled-server-arm64+raspi.img
```

### Boot

Place the SD Card in your RPi and give the system 5 minutes to boot before trying to SSH in.

### Enable cgroup to boot cmdline

```bash
sudo vim /boot/firmware/cmdline.txt
  cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory
```

## Raspberry Pi Manual Setup

Flash and setup SD card

```bash
sudo touch /Volumes/boot/ssh
sudo vim /Volumes/boot/cmdline.txt
    cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory
sudo vim /Volumes/boot/wpa_supplicant.conf
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid=""
    psk=""
}
```

### Network setup on Ubuntu

Usually, the file is named either `01-netcfg.yaml` or `50-cloud-init.yaml`

```yaml
sudoedit /etc/netplan/50-cloud-init.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens3:
      dhcp4: no
      addresses:
        - 10.0.1.11/24
      gateway4: 10.0.1.1
      nameservers:
          addresses: [10.0.1.1]
```

```yaml
network:
  version: 2
  renderer: networkd
  wifis:
    wlan0:
      access-points:
        "<wifi-name>":
          password: <password>
      dhcp4: no
      addresses:
        - 10.0.1.13/24
      gateway4: 10.0.1.1
      nameservers:
        addresses: [10.0.1.1]
      optional: true
```

Apply network changes

```bash
sudo netplan apply
```

## ETCD

### de-fragmentation

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

## Ceph

### crash alerts

```bash
ceph health detail
ceph crash ls-new
ceph crash archive-all
```

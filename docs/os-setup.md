# OS Setup

## Change network interface name on Fedora

```bash
vi /etc/default/grub
GRUB_CMDLINE_LINUX line append "net.ifnames=0 biosdevname=0"
grub2-mkconfig -o /boot/grub2/grub.cfg

cat /etc/sysconfig/network-scripts/ifcfg-eno1
<< EOF
DEVICE="eno1"
BOOTPROTO="static"
HWADDR=""
IPADDR=
NETMASK=255.255.255.0
ONBOOT="yes"
EOF

cat /etc/udev/rules.d/60-net.rules
<< EOF
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="$(cat /sys/class/net/enp3s0/address)", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eno1"
EOF

reboot
```

## Ubuntu Raspberry Pi using Flash

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
curl -L "https://download.fedoraproject.org/pub/fedora/linux/releases/36/Server/armhfp/images/Fedora-Server-36-1.5.armhfp.raw.xz" -o Fedora-Server-36.1.5-arm64+raspi.img.xz
unxz -T 0 ~/Downloads/Fedora-Server-36.1.5-arm64+raspi.img.xz
```

### Configure

Update [cloud-config.example.yml](../provision/cloud-config/k8s-5-pi4-garage.yml) as you see fit.

### Flash

```bash
flash --userdata setup/cloud-config.yml \
    ~/Downloads/Fedora-Server-36.1.5-arm64+raspi.img
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

## Misc Commands

### Copy between devices

```bash
tar -c <file_name> | ssh vikaspogu@10.0.1.87 'tar -xvf - -C /Users/vikaspogu/Downloads'
```

### Passwordless sudo user

vim /etc/sudoers.d/{username}-user

{username} ALL=(ALL) NOPASSWD:ALL

### Enable Bluetooth Device

```bash
hciattach /dev/ttyAMA0 bcm43xx 921600 noflow -
```

### Network setup on Ubuntu

Usually, the file is named either 01-netcfg.yaml or 50-cloud-init.yaml

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

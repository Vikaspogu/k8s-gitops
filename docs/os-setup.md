# OS Setup

## Ubuntu Raspberry Pi using Flash

> All these commands are run from your computer, not the RPi.

### Downloads the Flash tool

```bash
sudo curl -L "https://github.com/hypriot/flash/releases/download/2.7.2/flash" -o /usr/local/bin/flash
sudo chmod +x /usr/local/bin/flash
```

### Download and extract the image

```bash
cd ~/Downloads
curl -L "https://cdimage.ubuntu.com/releases/20.04.2/release/ubuntu-20.04.2-preinstalled-server-arm64+raspi.img.xz" -o ubuntu-20.04.2-preinstalled-server-arm64+raspi.img.xz
unxz -T 0 ~/Downloads/ubuntu-20.04.2-preinstalled-server-arm64+raspi.img.xz
```

### Configure

Update [cloud-config.example.yml](../setup/cloud-config.yml) as you see fit.

### Flash

```bash
flash --userdata setup/cloud-config.yml \
    ~/Downloads/ubuntu-20.04.1-preinstalled-server-arm64+raspi.img
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

terraform {

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.14"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.2"
    }
  }
}

data "sops_file" "proxmox_secrets" {
  source_file = "../../secret.sops.yaml"
}

provider "proxmox" {
  pm_api_url      = data.sops_file.proxmox_secrets.data["pm_api_url"]
  pm_user         = data.sops_file.proxmox_secrets.data["pm_username"]
  pm_password     = data.sops_file.proxmox_secrets.data["pm_password"]
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "k8s-7-proxmox-node" {
  count       = var.vm_count
  name        = "k8s-7-proxmox-node"
  target_node = var.pm_node

  clone = "fedora-37-1.7-cloudinit-template"

  os_type  = "cloud-init"
  cores    = 4
  sockets  = "1"
  cpu      = "host"
  memory   = 8102
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"
  onboot   = true

  disk {
    size    = "1000G"
    type    = "scsi"
    storage = "lvm-hhd"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # cloud-init settings
  # adjust the ip and gateway addresses as needed
  ipconfig0 = "ip=${data.sops_file.proxmox_secrets.data["k8s_7_ip"]}/24,gw=${data.sops_file.proxmox_secrets.data["gw_ip"]}"
  ssh_user  = data.sops_file.proxmox_secrets.data["ssh_user"]
  sshkeys   = file(var.ssh_keys["pub"])
  ciuser    = data.sops_file.proxmox_secrets.data["ssh_user"]

  # defines ssh connection to check when the VM is ready
  connection {
    host        = data.sops_file.proxmox_secrets.data["k8s_7_ip"]
    user        = data.sops_file.proxmox_secrets.data["ssh_user"]
    private_key = file(var.ssh_keys["priv"])
    agent       = false
    timeout     = "3m"
  }

  provisioner "remote-exec" {
    inline = ["echo 'VM is ready...'"]
  }
}

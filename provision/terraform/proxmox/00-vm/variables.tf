variable "pm_node" {
  default = "proxmox-0"
}

variable "ssh_key_file" {
  default = "~/.ssh/id_rsa.pub"
}

variable "ssh_keys" {
    type = map
     default = {
       pub  = "~/.ssh/id_rsa.pub"
       priv = "~/.ssh/id_rsa"
     }
}

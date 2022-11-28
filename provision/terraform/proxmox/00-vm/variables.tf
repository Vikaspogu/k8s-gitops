variable "pm_node" {
  default     = "proxmox-0"
  description = "Proxomox node name"
  type        = string
}

variable "vm_count" {
  description = "VM count"
  type        = number
}

variable "ssh_keys" {
  type = map(any)
  default = {
    pub  = "~/.ssh/id_rsa.pub"
    priv = "~/.ssh/id_rsa"
  }
}

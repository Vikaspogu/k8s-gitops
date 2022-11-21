variable "pm_node" {
  default     = "proxmox-0"
  type        = string
  description = "Proxmox node name"
}

variable "ssh_keys" {
  type        = map(any)
  description = "SSH key map public, private location"
  default = {
    pub  = "~/.ssh/id_rsa.pub"
    priv = "~/.ssh/id_rsa"
  }
}

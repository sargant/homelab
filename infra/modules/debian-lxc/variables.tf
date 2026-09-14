variable "host" {
  type = object({
    hostname     = string
    display_name = string
    mac          = string
    ip           = string
    dns          = string
    vm_id        = number
  })
}

variable "debian_template_id" {
  type = string
}

variable "cores" {
  type = number
}

variable "memory" {
  type = number
}

variable "swap" {
  type = number
}

variable "disk_size" {
  type = number
}

variable "device_passthrough" {
  type    = list(string)
  default = []
}

variable "bind_mounts" {
  type = list(object({
    source = string
    path   = string
  }))
  default = []
}

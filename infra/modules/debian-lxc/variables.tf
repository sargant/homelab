variable "host" {
  type = object({
    hostname = string
    mac      = string
    ip       = string
    dns      = string
  })
}

variable "display_name" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "template_file_id" {
  type = string
}

variable "cores" {
  type    = number
  default = 1
}

variable "memory" {
  type    = number
  default = 256
}

variable "swap" {
  type    = number
  default = 256
}

variable "disk_size" {
  type    = number
  default = 8
}

variable "ipv6_address" {
  type    = string
  default = "dhcp"
}

variable "device_passthrough" {
  type    = list(string)
  default = []
}

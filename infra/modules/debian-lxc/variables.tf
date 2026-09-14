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

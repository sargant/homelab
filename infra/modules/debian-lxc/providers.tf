terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }

    time = {
      source = "hashicorp/time"
    }

    unifi = {
      source = "ubiquiti-community/unifi"
    }
  }
}

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.1"
    }

    unifi = {
      source  = "ubiquiti-community/unifi"
      version = "0.55.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://127.0.0.1:8006/"
  insecure = true
}

provider "unifi" {}

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.1"
    }

    time = {
      source  = "hashicorp/time"
      version = "0.14.1"
    }

    unifi = {
      source  = "ubiquiti-community/unifi"
      version = "0.55.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://localhost:8006/"
  insecure = true
}

provider "unifi" {}

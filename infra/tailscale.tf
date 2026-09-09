resource "proxmox_virtual_environment_container" "tailscale" {
  node_name = "vm-host"
  vm_id     = 1021

  architecture = "amd64"
  cores        = 1

  memory {
    dedicated = 256
    swap      = 256
  }

  disk {
    datastore_id = "local-lvm"
    size         = 8
  }

  features {
    nesting = true
  }

  device_passthrough {
    path = "/dev/net/tun"
  }

  initialization {
    hostname = "tailscale"

    user_account {
      keys = [
        trimspace(file("/root/.ssh/ansible-bootstrap.pub"))
      ]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }

      ipv6 {
        address = "auto"
      }
    }
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    firewall    = true
    mac_address = "02:EE:88:40:BC:33"
  }

  operating_system {
    template_file_id = proxmox_download_file.debian_13.id
    type             = "debian"
  }

  start_on_boot = true
  started       = true
  unprivileged  = true
}

resource "unifi_dns_record" "tailscale" {
  name        = "tailscale.home.arpa"
  record_type = "A"
  value       = "192.168.37.21"
}

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

    ip_config {
      ipv4 {
        address = "dhcp"
      }

      ipv6 {
        address = "dhcp"
      }
    }
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    firewall    = true
    mac_address = "BC:24:11:CC:27:7F"
  }

  operating_system {
    template_file_id = "local:vztmpl/debian-13-standard_13.6-1_amd64.tar.zst"
    type             = "debian"
  }

  start_on_boot = true
  started       = true
  unprivileged  = true
}

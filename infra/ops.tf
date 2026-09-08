resource "proxmox_virtual_environment_container" "ops" {
  node_name = "vm-host"
  vm_id     = 1000

  description = "Homelab management entrypoint; bootstrapped outside OpenTofu."

  architecture = "amd64"
  cores        = 1

  memory {
    dedicated = 512
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 8
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "ops"

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
    mac_address = "02:97:82:31:80:54"
  }

  operating_system {
    template_file_id = "local:vztmpl/debian-13-standard_13.6-1_amd64.tar.zst"
    type             = "debian"
  }

  start_on_boot = true
  started       = true
  unprivileged  = true

  startup {
    order = 1
  }

  tags = ["bootstrap", "ops"]
}

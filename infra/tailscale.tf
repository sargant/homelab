resource "unifi_client" "tailscale" {
  mac              = "02:EE:88:40:BC:33"
  name             = "Tailscale Gateway"
  fixed_ip         = "192.168.37.21"
  local_dns_record = "tailscale.home.arpa"

  allow_existing         = true
  skip_forget_on_destroy = true
}

resource "time_sleep" "tailscale_dhcp" {
  create_duration = "10s"

  triggers = {
    client_id        = unifi_client.tailscale.id
    mac              = unifi_client.tailscale.mac
    fixed_ip         = unifi_client.tailscale.fixed_ip
    local_dns_record = unifi_client.tailscale.local_dns_record
  }
}

resource "proxmox_virtual_environment_container" "tailscale" {
  node_name = "vm-host"
  vm_id     = 1021

  cpu {
    architecture = "amd64"
    cores        = 1
  }

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
        trimspace(file("/root/.ssh/ansible.pub"))
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

  depends_on = [time_sleep.tailscale_dhcp]
}

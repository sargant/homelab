resource "unifi_client" "this" {
  mac              = var.host.mac
  name             = var.display_name
  fixed_ip         = var.host.ip
  local_dns_record = var.host.dns
}

resource "time_sleep" "dhcp" {
  create_duration = "10s"

  triggers = {
    client_id        = unifi_client.this.id
    mac              = unifi_client.this.mac
    fixed_ip         = unifi_client.this.fixed_ip
    local_dns_record = unifi_client.this.local_dns_record
  }
}

resource "proxmox_virtual_environment_container" "this" {
  node_name = "vm-host"
  vm_id     = var.host.vm_id

  cpu {
    architecture = "amd64"
    cores        = var.cores
  }

  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  disk {
    datastore_id = "local-lvm"
    size         = var.disk_size
  }

  features {
    nesting = true
  }

  dynamic "device_passthrough" {
    for_each = toset(var.device_passthrough)

    content {
      path = device_passthrough.value
    }
  }

  initialization {
    hostname = var.host.hostname

    user_account {
      keys = [
        trimspace(file("/root/.ssh/vm-management.pub"))
      ]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }

      ipv6 {
        # Proxmox uses "auto" for SLAAC.
        address = "auto"
      }
    }
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    firewall    = true
    mac_address = var.host.mac
  }

  operating_system {
    template_file_id = var.debian_template_id
    type             = "debian"
  }

  start_on_boot = true
  started       = true
  unprivileged  = true

  depends_on = [time_sleep.dhcp]
}

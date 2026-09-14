resource "unifi_client" "git" {
  mac              = local.hosts.git.mac
  name             = "Git server"
  fixed_ip         = local.hosts.git.ip
  local_dns_record = local.hosts.git.dns
}

resource "time_sleep" "git_dhcp" {
  create_duration = "10s"

  triggers = {
    client_id        = unifi_client.git.id
    mac              = unifi_client.git.mac
    fixed_ip         = unifi_client.git.fixed_ip
    local_dns_record = unifi_client.git.local_dns_record
  }
}

resource "proxmox_virtual_environment_container" "git" {
  node_name = "vm-host"
  vm_id     = 1046

  cpu {
    architecture = "amd64"
    cores        = 1
  }

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
    hostname = "git"

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
        address = "dhcp"
      }
    }
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    firewall    = true
    mac_address = local.hosts.git.mac
  }

  operating_system {
    template_file_id = proxmox_download_file.debian_13.id
    type             = "debian"
  }

  start_on_boot = true
  started       = true
  unprivileged  = true

  depends_on = [time_sleep.git_dhcp]
}

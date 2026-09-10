resource "unifi_client" "print_server" {
  mac              = "02:7A:41:C3:8D:52"
  name             = "print-server"
  fixed_ip         = "192.168.37.41"
  local_dns_record = "print-server.home.arpa"

  allow_existing         = true
  skip_forget_on_destroy = true
}

resource "time_sleep" "print_server_dhcp" {
  create_duration = "10s"

  triggers = {
    client_id        = unifi_client.print_server.id
    mac              = unifi_client.print_server.mac
    fixed_ip         = unifi_client.print_server.fixed_ip
    local_dns_record = unifi_client.print_server.local_dns_record
  }
}

resource "proxmox_virtual_environment_container" "print_server" {
  node_name = "vm-host"
  vm_id     = 1041

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

  initialization {
    hostname = "print-server"

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
        address = "dhcp"
      }
    }
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    firewall    = true
    mac_address = "02:7A:41:C3:8D:52"
  }

  operating_system {
    template_file_id = proxmox_download_file.debian_13.id
    type             = "debian"
  }

  start_on_boot = true
  started       = true
  unprivileged  = true

  depends_on = [time_sleep.print_server_dhcp]
}

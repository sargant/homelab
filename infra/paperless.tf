resource "unifi_client" "paperless" {
  mac              = local.hosts.paperless.mac
  name             = "Paperless"
  fixed_ip         = local.hosts.paperless.ip
  local_dns_record = local.hosts.paperless.dns
}

resource "time_sleep" "paperless_dhcp" {
  create_duration = "10s"

  triggers = {
    client_id        = unifi_client.paperless.id
    mac              = unifi_client.paperless.mac
    fixed_ip         = unifi_client.paperless.fixed_ip
    local_dns_record = unifi_client.paperless.local_dns_record
  }
}

resource "proxmox_virtual_environment_file" "paperless_cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "vm-host"

  source_raw {
    data = <<-EOF
      #cloud-config
      hostname: paperless
      disable_root: false
      ssh_pwauth: false

      users:
        - name: root
          lock_passwd: true
          shell: /bin/bash
          ssh_authorized_keys:
            - ${trimspace(file("/root/.ssh/ansible.pub"))}

      package_update: true
      packages:
        - qemu-guest-agent

      runcmd:
        - systemctl enable --now qemu-guest-agent
    EOF

    file_name = "paperless-cloud-init.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "paperless" {
  name        = "paperless"
  description = "Paperless application host"
  node_name   = "vm-host"
  vm_id       = 1044

  boot_order      = ["scsi0"]
  on_boot         = true
  started         = true
  stop_on_destroy = true
  scsi_hardware   = "virtio-scsi-single"
  keyboard_layout = "en-gb"

  agent {
    enabled = true
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_download_file.debian_13_cloud.id
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    size         = 32
    ssd          = true
  }

  initialization {
    datastore_id      = "local-lvm"
    upgrade           = false
    user_data_file_id = proxmox_virtual_environment_file.paperless_cloud_init.id

    ip_config {
      ipv4 {
        address = "dhcp"
      }

      ipv6 {
        address = "auto"
      }
    }
  }

  network_device {
    bridge      = "vmbr0"
    firewall    = true
    mac_address = local.hosts.paperless.mac
  }

  operating_system {
    type = "l26"
  }

  serial_device {
    device = "socket"
  }

  depends_on = [time_sleep.paperless_dhcp]
}

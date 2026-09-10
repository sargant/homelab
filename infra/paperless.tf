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
    datastore_id = "local-lvm"
    upgrade      = false

    user_account {
      username = "debian"
      keys = [
        trimspace(file("/root/.ssh/ansible.pub"))
      ]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_device {
    bridge      = "vmbr0"
    firewall    = true
    mac_address = "02:9D:44:7C:A1:B6"
  }

  operating_system {
    type = "l26"
  }

  serial_device {
    device = "socket"
  }
}

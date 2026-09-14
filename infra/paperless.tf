resource "proxmox_virtual_environment_file" "paperless_cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "vm-host"

  source_raw {
    data = templatefile("${path.module}/debian-vm.yaml.tftpl", {
      hostname           = local.hosts.paperless.hostname
      ssh_authorized_key = trimspace(file("/root/.ssh/vm-management.pub"))
    })

    file_name = "${local.hosts.paperless.hostname}-cloud-init.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "paperless" {
  name        = local.hosts.paperless.hostname
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

  # Required by the provider when resizing imported Debian cloud-image disks.
  serial_device {
    device = "socket"
  }
}

# UniFi Network 10.x can observe a DHCP client before it creates the legacy
# rest/user record that the provider expects when taking over a MAC. Bootstrap
# that record after first boot, then let unifi_client own it normally.
resource "terraform_data" "paperless_unifi_bootstrap" {
  triggers_replace = [
    proxmox_virtual_environment_vm.paperless.id,
    local.hosts.paperless.mac,
    local.hosts.paperless.ip,
    local.hosts.paperless.dns,
  ]

  provisioner "local-exec" {
    command = "python3 ${path.module}/scripts/bootstrap-unifi-client.py"

    environment = {
      UNIFI_CLIENT_MAC  = local.hosts.paperless.mac
      UNIFI_CLIENT_IP   = local.hosts.paperless.ip
      UNIFI_CLIENT_DNS  = local.hosts.paperless.dns
      UNIFI_CLIENT_NAME = "Paperless"
    }
  }
}

resource "unifi_client" "paperless" {
  mac              = local.hosts.paperless.mac
  name             = "Paperless"
  fixed_ip         = local.hosts.paperless.ip
  local_dns_record = local.hosts.paperless.dns

  depends_on = [terraform_data.paperless_unifi_bootstrap]
}

# The first boot receives an ordinary DHCP lease before the reservation exists.
# Reboot once UniFi owns the fixed lease so the guest comes back on its final IP.
resource "terraform_data" "paperless_dhcp_refresh" {
  triggers_replace = [
    proxmox_virtual_environment_vm.paperless.id,
    unifi_client.paperless.id,
    local.hosts.paperless.ip,
  ]

  provisioner "local-exec" {
    command = "qm reboot ${proxmox_virtual_environment_vm.paperless.vm_id}"
  }
}

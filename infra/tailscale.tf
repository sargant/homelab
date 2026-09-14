module "tailscale" {
  source = "./modules/debian-lxc"

  host               = local.hosts.tailscale
  debian_template_id = proxmox_download_file.debian_13.id

  cores     = 1
  memory    = 256
  swap      = 256
  disk_size = 8

  device_passthrough = ["/dev/net/tun"]
}

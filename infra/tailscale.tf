module "tailscale" {
  source = "./modules/debian-lxc"

  host         = local.hosts.tailscale
  display_name = "Tailscale Gateway"
  vm_id        = 1021

  cores     = 1
  memory    = 256
  swap      = 256
  disk_size = 8

  device_passthrough = ["/dev/net/tun"]

  depends_on = [proxmox_download_file.debian_13]
}

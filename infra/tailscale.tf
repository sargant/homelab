module "tailscale" {
  source = "./modules/debian-lxc"

  host             = local.hosts.tailscale
  display_name     = "Tailscale Gateway"
  vm_id            = 1021
  template_file_id = proxmox_download_file.debian_13.id

  ipv6_address      = "auto"
  device_passthrough = ["/dev/net/tun"]
}

module "print_server" {
  source = "./modules/debian-lxc"

  host             = local.hosts.print_server
  display_name     = "Print server"
  vm_id            = 1041
  template_file_id = proxmox_download_file.debian_13.id

  cores     = 1
  memory    = 256
  swap      = 256
  disk_size = 8
}

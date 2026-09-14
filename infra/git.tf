module "git" {
  source = "./modules/debian-lxc"

  host               = local.hosts.git
  debian_template_id = proxmox_download_file.debian_13.id

  cores     = 1
  memory    = 512
  swap      = 512
  disk_size = 8

  bind_mounts = [
    {
      source = "/mnt/nas-backup/gogs"
      path   = "/mnt/backup"
    }
  ]
}

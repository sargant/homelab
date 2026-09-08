resource "proxmox_download_file" "debian_13" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "vm-host"
  url          = "https://download.proxmox.com/images/system/debian-13-standard_13.6-1_amd64.tar.zst"
}

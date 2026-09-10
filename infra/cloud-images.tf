resource "proxmox_download_file" "debian_13_cloud" {
  content_type = "import"
  datastore_id = "local"
  node_name    = "vm-host"
  url          = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
  file_name    = "debian-13-generic-amd64.qcow2"
  overwrite    = false
}

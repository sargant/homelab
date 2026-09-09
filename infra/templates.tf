resource "proxmox_download_file" "debian_13" {
  content_type        = "vztmpl"
  datastore_id        = "local"
  node_name           = "vm-host"
  url                 = "http://download.proxmox.com/images/system/debian-13-standard_13.6-1_amd64.tar.zst"
  overwrite_unmanaged = true
  checksum_algorithm  = "sha512"
  checksum            = "4c0c27ca6ceab5ef0b84db57825a00f26157ef1854bafe97297813e1cbe8ecb8cc9c453cab6b3b0efe1ba193a50c47ece1e41d950e411b8730b835b71e9e754b"
}

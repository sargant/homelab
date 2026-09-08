resource "unifi_dns_record" "tailscale" {
  name        = "tailscale.home.arpa"
  record_type = "A"
  value       = "192.168.37.21"
}

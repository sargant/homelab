moved {
  from = unifi_client.print_server
  to   = module.print_server.unifi_client.this
}

moved {
  from = time_sleep.print_server_dhcp
  to   = module.print_server.time_sleep.dhcp
}

moved {
  from = proxmox_virtual_environment_container.print_server
  to   = module.print_server.proxmox_virtual_environment_container.this
}

moved {
  from = unifi_client.tailscale
  to   = module.tailscale.unifi_client.this
}

moved {
  from = time_sleep.tailscale_dhcp
  to   = module.tailscale.time_sleep.dhcp
}

moved {
  from = proxmox_virtual_environment_container.tailscale
  to   = module.tailscale.proxmox_virtual_environment_container.this
}

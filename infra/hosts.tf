locals {
  hosts = {
    # UniFi normalizes MAC addresses to lowercase, and the current provider
    # performs a case-sensitive lookup when adopting existing clients.
    tailscale = {
      hostname     = "tailscale"
      display_name = "Tailscale gateway"
      mac          = "02:ee:88:40:bc:33"
      ip           = "192.168.37.21"
      dns          = "tailscale.home.arpa"
      vm_id        = 1021
    }

    print_server = {
      hostname     = "print-server"
      display_name = "Print server"
      mac          = "02:7a:41:c3:8d:52"
      ip           = "192.168.37.41"
      dns          = "print-server.home.arpa"
      vm_id        = 1041
    }

    paperless = {
      hostname     = "paperless"
      display_name = "Paperless"
      mac          = "02:9d:44:7c:a1:b6"
      ip           = "192.168.37.44"
      dns          = "paperless.home.arpa"
      vm_id        = 1044
    }
  }
}

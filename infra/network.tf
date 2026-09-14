locals {
  hosts = {
    # UniFi normalizes MAC addresses to lowercase, and the current provider
    # performs a case-sensitive lookup when adopting existing clients.
    tailscale = {
      hostname = "tailscale"
      mac      = "02:ee:88:40:bc:33"
      ip       = "192.168.37.21"
      dns      = "tailscale.home.arpa"
    }

    print_server = {
      hostname = "print-server"
      mac      = "02:7a:41:c3:8d:52"
      ip       = "192.168.37.41"
      dns      = "print-server.home.arpa"
    }

    paperless = {
      hostname = "paperless"
      mac      = "02:9d:44:7c:a1:b6"
      ip       = "192.168.37.44"
      dns      = "paperless.home.arpa"
    }

    git = {
      hostname = "git"
      mac      = "02:de:71:b9:0d:96"
      ip       = "192.168.37.46"
      dns      = "git.home.arpa"
    }
  }
}

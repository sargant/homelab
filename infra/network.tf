locals {
  hosts = {
    tailscale = {
      hostname = "tailscale"
      mac      = "02:EE:88:40:BC:33"
      ip       = "192.168.37.21"
      dns      = "tailscale.home.arpa"
    }

    print_server = {
      hostname = "print-server"
      mac      = "02:7A:41:C3:8D:52"
      ip       = "192.168.37.41"
      dns      = "print-server.home.arpa"
    }

    paperless = {
      hostname = "paperless"
      mac      = "02:9d:44:7c:a1:b6"
      ip       = "192.168.37.44"
      dns      = "paperless.home.arpa"
    }
  }
}

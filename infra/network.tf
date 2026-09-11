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
      hostname = "paperless-temp"
      mac      = "02:6E:99:B4:31:D2"
      ip       = "192.168.37.99"
      dns      = "paperless-temp.home.arpa"
    }
  }
}

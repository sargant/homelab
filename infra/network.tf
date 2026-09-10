locals {
  hosts = {
    tailscale = {
      mac = "02:EE:88:40:BC:33"
      ip  = "192.168.37.21"
      dns = "tailscale.home.arpa"
    }

    print_server = {
      mac = "02:7A:41:C3:8D:52"
      ip  = "192.168.37.41"
      dns = "print-server.home.arpa"
    }

    paperless = {
      mac = "02:9D:44:7C:A1:B6"
      ip  = "192.168.37.44"
      dns = "paperless.home.arpa"
    }
  }
}

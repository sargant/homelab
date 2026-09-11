# homelab

Bootstrapping, infrastructure and configuration for my homelab.

## Bootstrap a Proxmox host

From a fresh checkout on the Proxmox host:

```sh
./bootstrap-proxmox.sh
cp .env.example .env
# fill in the required values in .env
just init
```

The root `justfile` is the command surface for infrastructure and host configuration.

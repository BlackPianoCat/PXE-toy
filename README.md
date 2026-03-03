# PXE Server Setup Project

This project automates the setup of a PXE boot environment using **Ansible** and optionally **Vagrant**.  
It allows multiple clients to boot the same Debian root image over the network via **PXE/NFS**, ensuring a consistent environment across all nodes.

---

## Project Structure

```

.
├── hosts                        # Ansible inventory
├── playbook.yml                  # Main playbook orchestrating setup
├── pxe_clients_script.sh         # Optional helper script to create PXE clients (Vagrant/VirtualBox)
├── README.md                     # This file
├── roles/
│   └── pxe-server/
│       ├── files/
│       │   ├── exports           # NFS export configuration
│       │   └── preseed.cfg       # Preseed file for automated Debian install
│       ├── handlers/
│       │   └── main.yml
│       └── tasks/
│           ├── debootstrap.yml   # Bootstrap Debian root filesystem
│           ├── main.yml          # Role entry point
│           ├── setup_base.yml    # Base package installation on PXE server
│           ├── setup_pxe.yml     # PXE/TFTP/dnsmasq configuration
│           └── setup.yml         # Combined/deprecated version (legacy)
├── updates.yml                   # Optional: updates playbook for server/rootfs
└── Vagrantfile                   # Optional: create PXE clients for testing

```

---

## What Happens in This Project

1. **PXE Server Base Setup**
   - Installs required packages: `debootstrap`, `dnsmasq`, `tftp`, `nfs-kernel-server`, `syslinux`, `net-tools`, `iproute2`, `rsync`, etc.
   - Syncs server time with NTP.
   - Prepares TFTP and NFS directories.

2. **Debian Root Filesystem**
   - Bootstraps a minimal Debian `bookworm` system using `debootstrap`.
   - Installs kernel, initramfs, network tools, and essential packages.
   - Configures users, hostname, and `/etc/hosts`.
   - Builds initramfs for PXE boot.

3. **PXE/TFTP Configuration**
   - Copies `pxelinux.0` and required `.c32` modules to `/srv/tftp`.
   - Copies latest kernel and initrd to `/srv/tftp`.
   - Generates PXELINUX menu using a template.
   - Configures `dnsmasq` for DHCP + TFTP serving.
   - Tests `dnsmasq` configuration before enabling service.

4. **NFS Setup**
   - Exports `/srv/debian-root` to clients via NFS.
   - Configures proper permissions for safe PXE boot.

5. **Client Booting**
   - Clients boot via PXE, receive IP from `dnsmasq`, and mount the Debian root via NFS.
   - All clients share the same root image for reproducibility.

---

## Requirements

- Debian/Ubuntu server for PXE role
- Python + Ansible installed on the host
- Optional: VirtualBox + Vagrant for local PXE client testing
- Network interface for PXE (default `eth1` for Vagrant, can override via vars)

---

## Usage

### 1. Prepare Inventory (`hosts`)
```ini
[pxe_servers]
pxe-server ansible_host=192.168.56.101

[pxe_clients]
client1
client2
````

### 2. Run PXE Server Setup

```bash
ansible-playbook -i hosts playbook.yml --ask-become-pass
```

This will:

* Bootstrap PXE server
* Prepare NFS root
* Configure TFTP/dnsmasq
* Ensure kernel/initrd and PXELINUX menu are in place

### 3. PXE Clients

* PXE clients (VMs or physical) should boot from network.
* They will mount `/srv/debian-root` via NFS and start Debian automatically.

### 4. Optional: Create Test Clients with Vagrant

```bash
./pxe_clients_script.sh
```

This script creates 3 VMs configured for PXE boot (BIOS, network-first).

---

## Notes / Tips

* Use `setup_pxe.yml` for stable PXE configuration; `setup.yml` is legacy.
* If DNS/DHCP conflicts occur, ensure `systemd-resolved` is stopped and port 53 is free.
* Kernel and initrd are automatically taken from `/srv/debian-root/boot`.
* Templates (`pxelinux_default.cfg.j2` and `dnsmasq_pxe.conf.j2`) allow easy customization.
* For production, adjust `dhcp-range` and `nfsroot` to match your network.

---

## Author

**Sebastian Korsak** – biophysicist / HPC admin / molecular dynamics researcher

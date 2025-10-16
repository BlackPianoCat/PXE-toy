
# PXE + Clonezilla Infrastructure for Debian Cloning

This project sets up a PXE boot environment with Clonezilla for disk cloning using **Ansible** and **Vagrant**.  
The goal is to provision a PXE server and boot multiple empty clients over the network to install or clone Debian automatically.

---

## Project Structure

```

PXE/
├── Vagrantfile                 # PXE server VM definition
├── hosts                       # Ansible inventory
├── playbook.yml                 # Ansible playbook for PXE server setup
├── pxe_clients_script.sh        # Bash script to create/run/destroy PXE clients
├── roles/
│   └── pxe-server/
│       ├── tasks/main.yml      # PXE server configuration tasks
│       ├── handlers/main.yml   # Handler for restarting services
│       └── files/
│           ├── preseed.cfg     # Optional automated Debian installer config
│           └── exports         # NFS export configuration
└── README.md

````

---

## What the Playbook Does

The playbook (`playbook.yml`) performs the following steps:

### 1. PXE Server Base Setup

- Installs required packages:
  - `dnsmasq` → DHCP + TFTP server for PXE boot.
  - `pxelinux` / `syslinux-common` → PXE bootloader.
  - `nfs-kernel-server` → NFS exports for clients.
  - `drbl`, `clonezilla`, `partclone` → Clonezilla server for PXE cloning.

- Configures `dnsmasq`:
  - Provides IP addresses in the range `192.168.56.100–192.168.56.200`.
  - Serves PXE bootloader from `/srv/tftp`.

- Sets up TFTP root:
  - Copies `pxelinux.0` bootloader.
  - Adds Debian netboot files (`vmlinuz`, `initrd.img`).
  - Optional preseed configuration for automated installs.

### 2. NFS and Clonezilla Setup

- Creates directories for Clonezilla images:
  - `/srv/nfs/clonezilla-images` → shared via NFS.
  - `/home/partimag` → stores master disk image.

- Configures `/etc/exports` and starts NFS service.

- Initializes DRBL / Clonezilla PXE environment:
  - Runs `drblsrv -i` → initializes DRBL configuration.
  - Runs `drblpush -i` → pushes PXE menu and configuration to TFTP.

### 3. Manual Step Reminder

- Create a master Debian image for cloning:
  ```bash
  sudo ocs-sr -q2 -j2 -z1p -i 2000 -sc -p poweroff saveparts debian_image sda
  ```

* This image is stored in `/home/partimag/debian_image/` and can be restored to PXE clients automatically.

---

## Using Vagrant

The `Vagrantfile` defines the PXE server VM:

* Box: `debian/bookworm64`
* Private network IP: `192.168.56.10`
* 1 CPU, 1 GB RAM, headless
* Automatically provisions basic packages and SSH user (`vagrant`)

### Commands

* Start PXE server:

```bash
vagrant up pxe-server
```

* SSH into PXE server:

```bash
vagrant ssh pxe-server
```

* Destroy PXE server:

```bash
vagrant destroy pxe-server
```

---

## Using the PXE Clients Script

The `pxe_clients_script.sh` automates creating and booting empty clients via VirtualBox:

```bash
./pxe_clients_script.sh -c      # Create clients
./pxe_clients_script.sh -r      # Run clients
./pxe_clients_script.sh -d      # Destroy clients
./pxe_clients_script.sh -cr     # Create then run
```

* Creates `pxe-client1`, `pxe-client2`, `pxe-client3`.
* Configures clients to boot via PXE from the host-only network.
* Ensures clients are connected to the same network as PXE server (`192.168.56.0/24`).

---

## Using Ansible Playbook

* Inventory file (`hosts`) example:

```
[pxe_servers]
pxe-server ansible_host=192.168.56.10 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/pxe-server/virtualbox/private_key

[pxe_clients]
pxe-client1
pxe-client2
pxe-client3
```

* Run the playbook:

```bash
ansible-playbook -i hosts playbook.yml
```

* This will configure the PXE server for DHCP, TFTP, NFS, and Clonezilla PXE boot.

---

## PXE Boot Flow for Clients

1. PXE clients boot and request DHCP IP from PXE server.
2. PXE server serves the bootloader and Clonezilla PXE menu.
3. Clients load Clonezilla and can restore the master Debian image.
4. After restore, clients reboot and have a fully installed Debian system.

> ⚠️ Note: You must create the master image first (`/home/partimag/debian_image/`) for cloning to work.

---

## References

* [PXELINUX Documentation](https://wiki.syslinux.org/wiki/index.php?title=PXELINUX)
* [Clonezilla Server (DRBL)](https://clonezilla.org/clonezilla-SE/)
* [Debian Netboot Images](https://www.debian.org/distrib/netinst)

---

## Notes

* PXE server uses **host-only network** (`192.168.56.0/24`) to communicate with clients.
* Make sure the Vagrant box has Python installed for Ansible provisioning.
* PXE cloning currently requires a **manual creation of the master image**; unattended restore can be added later.


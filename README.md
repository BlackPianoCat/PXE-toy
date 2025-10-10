# PXE-toy

A small lab project to set up a PXE boot infrastructure using **Vagrant**, **Ansible**, and **libvirt/KVM**.  
It allows you to spin up a PXE server and multiple bare PXE clients for testing network booting.

---

## Features

- PXE server configured with:
  - `dnsmasq` for DHCP + TFTP
  - PXE bootloader (`pxelinux.0`)
  - Debian netboot kernel and initrd
- Bare PXE clients that boot via network
- Fully automated setup via **Ansible**
- Reproducible lab environment via **Vagrant** + **libvirt**

---

## Requirements

- [Vagrant](https://www.vagrantup.com/)
- [Libvirt / KVM](https://libvirt.org/) or another supported Vagrant provider
- [Ansible 2.10+](https://docs.ansible.com/)
- Git

---

## Setup

1. Clone the repository:

```bash
git clone git@github.com:BlackPianoCat/PXE-toy.git
cd PXE-toy
````

2. Start the virtual machines:

```bash
vagrant up
```

3. Verify Ansible can reach the PXE server:

```bash
ansible pxe_servers -i hosts -m ping
```

4. Run the playbook to configure PXE server:

```bash
ansible-playbook -i hosts playbook.yml
```

---

## Directory Structure

```
PXE-toy/
├── Vagrantfile           # Vagrant configuration for PXE server + clients
├── hosts                 # Ansible inventory
├── playbook.yml          # Ansible playbook
├── roles/
│   └── pxe-server/
│       ├── tasks/main.yml
│       ├── files/
│       │   ├── pxelinux.0
│       │   ├── vmlinuz
│       │   └── initrd.img
│       └── templates/    # PXE menu templates (if needed)
└── README.md
```

---

## Usage

* Once the playbook finishes, your PXE server is ready.
* The PXE clients will boot over the network when started.
* You can edit the PXE menu template to change the boot behavior or choose a different OS image.

---

## Notes

* Make sure your Vagrant provider supports networking for PXE (host-only or private network).
* PXE clients are bare by default — no OS installed until network boot completes.
* Debian netboot kernel and initrd are included under `roles/pxe-server/files/`.

## Author

Sebastian Korsak "BlackPianoCat"

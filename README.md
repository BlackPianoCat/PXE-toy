# PXE + Debian Live / Clonezilla Infrastructure

This project sets up a **PXE boot server** for deploying Debian systems or Clonezilla live environments using **Ansible** and **Vagrant**.
It enables network boot of diskless clients on a private LAN, supporting both **Debian Live boot** and **Clonezilla cloning** workflows.

---

## 🎯 Project Goals

In simple terms:

1. **Create a PXE server** that can boot client machines over the network (no OS or disk required).
2. Provide **two boot options**:

   * **Debian Live XFCE** (from ISO image).
   * **Clonezilla Live** (for disk cloning or imaging).
3. Enable quick provisioning or rescue of multiple machines automatically.

This setup is ideal for labs or testing environments where many Debian systems must be deployed consistently.

---

## 🧩 Components Explained

* **PXE (Preboot Execution Environment)**
  Lets network clients boot via DHCP + TFTP before any OS is installed.

* **dnsmasq**
  Provides DHCP + TFTP for PXE:

  * Assigns IPs to clients (`192.168.56.100–192.168.56.200`).
  * Serves bootloader (`pxelinux.0`) and menu.

* **PXELINUX / Syslinux**
  The bootloader that runs after PXE and shows the boot menu (Debian Live, Clonezilla, etc.).

* **nginx (HTTP server)**
  Added to **serve Debian Live files faster** than TFTP (used for kernel/initrd only).

* **Clonezilla**
  Still included for optional imaging and restore workflows.

* **Ansible**
  Automates the complete PXE + network boot environment setup.

* **Vagrant**
  Creates the PXE server VM for local testing (VirtualBox host-only network).

---

## 📁 Project Structure

```
PXE/
├── Vagrantfile                   # PXE server VM definition (Debian)
├── hosts                         # Ansible inventory
├── playbook.yml                  # Main playbook to configure PXE server
├── pxe_clients_script.sh         # Script to create/run PXE client VMs
└── roles/
    └── pxe-server/
        ├── tasks/main.yml        # PXE server automation logic
        ├── handlers/main.yml     # Handlers (e.g. service restarts)
        └── files/
            ├── preseed.cfg       # (optional) for automated Debian installs
            └── exports           # NFS configuration for Clonezilla (optional)
```

---

## ⚙️ What the Playbook Does

### 1. PXE Server Base Configuration

* Detects the PXE network interface (host-only, e.g. `192.168.56.x`).
* Installs required packages:

  * `dnsmasq`, `pxelinux`, `syslinux-common`, `tftp`
  * `nfs-kernel-server`, `nginx`, `unzip`
* Configures:

  * `/srv/tftp` → TFTP root directory.
  * `/etc/dnsmasq.d/pxe.conf` → DHCP + PXE configuration.

---

### 2. Clonezilla Setup

* Downloads and unpacks **Clonezilla Live** into `/srv/tftp/live/`.
* Adds **Clonezilla boot entry** in PXE menu.
* (Optional) Can be used to create or restore disk images manually:

  ```bash
  sudo ocs-sr -q2 -j2 -z1p -i 2000 -sc -p poweroff saveparts debian_image sda
  ```

---

### 3. Debian Live ISO Boot Setup

* Downloads official Debian Live XFCE ISO:

  ```
  https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/debian-live-13.1.0-amd64-xfce.iso
  ```
* Mounts and extracts `vmlinuz`, `initrd.img`, and `filesystem.squashfs`.
* Serves the filesystem via HTTP using `nginx`.
* Adds PXE menu entry for Debian Live boot:

  ```text
  LABEL Debian Live XFCE
      MENU LABEL Debian Live 13.1.0 XFCE (64-bit)
      KERNEL debian-live/live/vmlinuz
      APPEND initrd=debian-live/live/initrd.img boot=live components fetch=http://192.168.56.10/debian-live/live/filesystem.squashfs
  ```

---

### 4. PXE Menu

When clients boot from the network, they’ll see a PXE menu with:

```
PXE Boot Menu
1. Clonezilla Live
2. Debian Live XFCE (Debian 13.1.0)
```

---

## 🧰 Using Vagrant

Start and manage your PXE server VM easily:

```bash
vagrant up pxe-server        # Launch PXE server VM
vagrant ssh pxe-server       # Connect to the PXE server
vagrant destroy pxe-server   # Remove PXE server VM
```

Network:

* Host-only adapter: `192.168.56.0/24`
* PXE server IP: `192.168.56.10`

---

## 🖥️ Running PXE Clients

Use the helper script to create or boot PXE client VMs (no OS, network boot only):

```bash
./pxe_clients_script.sh -c      # Create client VMs
./pxe_clients_script.sh -r      # Run clients
./pxe_clients_script.sh -d      # Destroy clients
./pxe_clients_script.sh -cr     # Create and run
```

Each client is configured to PXE boot from `192.168.56.10`.

---

## 🧾 Ansible Inventory Example

```
[pxe_servers]
pxe-server ansible_host=192.168.56.10 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/pxe-server/virtualbox/private_key
```

Run provisioning:

```bash
ansible-playbook -i hosts playbook.yml
```

---

## 🧠 Boot Flow Summary

1. PXE client requests IP → dnsmasq responds (DHCP).
2. dnsmasq serves `pxelinux.0` → PXE menu loads.
3. User selects either:

   * **Debian Live XFCE** → boots full Debian system over network.
   * **Clonezilla Live** → boots cloning environment.
4. Debian Live filesystem is fetched over HTTP (fast boot).
5. Clonezilla can restore or create images if desired.

---

## 📚 References

* [Debian Live ISO Images](https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/)
* [Syslinux / PXELINUX](https://wiki.syslinux.org/wiki/index.php?title=PXELINUX)
* [Clonezilla Live](https://clonezilla.org/clonezilla-live.php)

---

## 🧩 Notes

* Works on **VirtualBox host-only network** (`192.168.56.0/24`).
* Debian Live boots **directly from ISO**, no manual unpacking needed by user.
* Clonezilla remains available for custom image cloning workflows.
* You can later add a **preseed** or **autoinstall** to make Debian installation fully unattended.

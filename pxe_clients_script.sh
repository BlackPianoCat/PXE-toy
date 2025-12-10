#!/bin/bash
# =======================================
# PXE Client Automation Script for VirtualBox
# =======================================
# Creates, destroys or runs multiple PXE clients.
# Includes progress bar for VM creation.
# Ensures correct storage controller and PXE boot ordering.
# =======================================

VM_PREFIX="pxe-client"
VM_COUNT=3

HOST_ONLY_NET="vboxnet0"     # PXE network
NAT_NET=true                 # enable NAT second NIC for internet
VM_MEMORY=4096
VM_CPUS=2
DISK_SIZE=10240              # disk size in MB

# A tiny progress bar function for nicer UX
progress() {
    local step="$1"
    local total="$2"
    local width=30
    local fill=$(( step * width / total ))
    local empty=$(( width - fill ))

    printf "\r["
    printf "%0.s#" $(seq 1 $fill)
    printf "%0.s-" $(seq 1 $empty)
    printf "] %d/%d" "$step" "$total"

    if [[ "$step" -eq "$total" ]]; then
        echo ""
    fi
}

# Parse action
ACTION=""
case "$1" in
  -c|--create) ACTION="create" ;;
  -d|--destroy) ACTION="destroy" ;;
  -r|--run) ACTION="run" ;;
  -cr) ACTION="create_run" ;;
  *) echo "Usage: $0 [-c|--create | -d|--destroy | -r|--run | -cr]"; exit 1 ;;
esac


# =========================================================
# DESTROY VMs
# =========================================================
if [[ "$ACTION" == "destroy" ]]; then
  for i in $(seq 1 $VM_COUNT); do
    VM_NAME="${VM_PREFIX}${i}"

    if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
      VBoxManage controlvm "$VM_NAME" poweroff &>/dev/null || true
      VBoxManage unregistervm "$VM_NAME" --delete
      echo "[DESTROYED] $VM_NAME"
    fi
  done
  exit 0
fi


# =========================================================
# CREATE VMs
# =========================================================
if [[ "$ACTION" == "create" || "$ACTION" == "create_run" ]]; then

  total_steps=$((VM_COUNT * 5))   # create, configure, NICs, storagectl, diskattach
  current=0

  for i in $(seq 1 $VM_COUNT); do
    VM_NAME="${VM_PREFIX}${i}"
    VM_DIR="$HOME/VirtualBox VMs/$VM_NAME"
    VDI_PATH="$VM_DIR/$VM_NAME.vdi"

    if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
      echo "[SKIP] $VM_NAME exists."
      continue
    fi

    # Step 1: Create VM
    VBoxManage createvm --name "$VM_NAME" --register
    ((current++)); progress "$current" "$total_steps"

    # Step 2: Basic settings
    VBoxManage modifyvm "$VM_NAME" \
      --memory "$VM_MEMORY" \
      --cpus "$VM_CPUS" \
      --ioapic on \
      --boot1 net \
      --boot2 disk \
      --boot3 none \
      --boot4 none
    ((current++)); progress "$current" "$total_steps"

    # Step 3: NIC1 host only
    VBoxManage modifyvm "$VM_NAME" \
      --nic1 hostonly \
      --hostonlyadapter1 "$HOST_ONLY_NET" \
      --nictype1 82540EM \
      --cableconnected1 on

    # Optional NIC2 NAT
    if [[ "$NAT_NET" == true ]]; then
      VBoxManage modifyvm "$VM_NAME" \
        --nic2 nat \
        --nictype2 82540EM \
        --cableconnected2 on
    fi
    ((current++)); progress "$current" "$total_steps"

    # Step 4: Storage controller (fix SATA link down errors)
    VBoxManage storagectl "$VM_NAME" \
      --name "SATA Controller" \
      --add sata \
      --controller IntelAhci \
      --portcount 1 \
      --bootable on
    ((current++)); progress "$current" "$total_steps"

    # Step 5: Create and attach disk
    mkdir -p "$VM_DIR"
    VBoxManage createmedium disk --filename "$VDI_PATH" --size "$DISK_SIZE" --format VDI

    VBoxManage storageattach "$VM_NAME" \
      --storagectl "SATA Controller" \
      --port 0 --device 0 \
      --type hdd --medium "$VDI_PATH"
    ((current++)); progress "$current" "$total_steps"

    echo ""
    echo "[CREATED] $VM_NAME"
    echo ""
  done
fi


# =========================================================
# RUN VMs
# =========================================================
if [[ "$ACTION" == "run" || "$ACTION" == "create_run" ]]; then
  for i in $(seq 1 $VM_COUNT); do
    VM_NAME="${VM_PREFIX}${i}"
    if ! VBoxManage list runningvms | grep -q "\"$VM_NAME\""; then
      VBoxManage startvm "$VM_NAME" --type headless
      echo "[STARTED] $VM_NAME"
    fi
  done
fi

echo "[DONE] Action '$ACTION' completed."


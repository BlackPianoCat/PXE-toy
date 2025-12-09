#!/bin/bash
# =======================================
# PXE Client Automation Script for VirtualBox
# =======================================
# Flags:
#   -c | --create  -> create VMs
#   -d | --destroy -> destroy VMs
#   -r | --run     -> run existing VMs
#   -cr            -> create then run

VM_PREFIX="pxe-client"
VM_COUNT=3
HOST_ONLY_NET="vboxnet0"   # PXE network
NAT_NET=true                # set NAT NIC for internet
VM_MEMORY=4096
VM_CPUS=2
DISK_SIZE=10240             # in MB

ACTION=""
case "$1" in
  -c|--create) ACTION="create" ;;
  -d|--destroy) ACTION="destroy" ;;
  -r|--run) ACTION="run" ;;
  -cr) ACTION="create_run" ;;
  *) echo "Usage: $0 [-c|--create | -d|--destroy | -r|--run | -cr]"; exit 1 ;;
esac

# ----------------------------
# Destroy VMs
# ----------------------------
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

# ----------------------------
# Create VMs
# ----------------------------
if [[ "$ACTION" == "create" || "$ACTION" == "create_run" ]]; then
  for i in $(seq 1 $VM_COUNT); do
    VM_NAME="${VM_PREFIX}${i}"
    VM_DIR="$HOME/VirtualBox VMs/$VM_NAME"
    VDI_PATH="$VM_DIR/$VM_NAME.vdi"

    if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
      echo "[SKIP] VM $VM_NAME exists."
      continue
    fi

    # Create VM
    VBoxManage createvm --name "$VM_NAME" --register

    # Configure memory and CPU
    VBoxManage modifyvm "$VM_NAME" \
      --memory "$VM_MEMORY" \
      --cpus "$VM_CPUS" \
      --ioapic on \
      --boot1 net \
      --boot2 disk \
      --boot3 none \
      --boot4 none

    # Configure NIC1: host-only for PXE
    VBoxManage modifyvm "$VM_NAME" \
      --nic1 hostonly \
      --hostonlyadapter1 "$HOST_ONLY_NET" \
      --nictype1 82540EM \
      --cableconnected1 on

    # Optional NIC2: NAT for internet
    if [[ "$NAT_NET" == true ]]; then
      VBoxManage modifyvm "$VM_NAME" \
        --nic2 nat \
        --cableconnected2 on
    fi

    # Create and attach disk
    mkdir -p "$VM_DIR"
    VBoxManage createmedium disk --filename "$VDI_PATH" --size "$DISK_SIZE" --format VDI
    VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci
    VBoxManage storageattach "$VM_NAME" \
      --storagectl "SATA Controller" \
      --port 0 --device 0 --type hdd --medium "$VDI_PATH"

    echo "[CREATED] $VM_NAME"
  done
fi

# ----------------------------
# Run VMs
# ----------------------------
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


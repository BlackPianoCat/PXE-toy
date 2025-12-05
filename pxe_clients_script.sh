#!/bin/bash

# ----------------------------
# PXE Client Automation Script (with dedicated host-only network)
# ----------------------------
# Flags:
#   -c  create VMs
#   -d  destroy VMs
#   -r  run VMs
#   -cr create then run
# ----------------------------

VM_PREFIX="pxe-client"
VM_COUNT=3
HOST_ONLY_IP="192.168.56.1"    # IP of host-only adapter
PXE_NET_MASK="255.255.255.0"
PXE_SERVER_IP="192.168.56.10"  # PXE server IP for clients
MEMORY_MB=4096
CPUS=2
DISK_SIZE_MB=10240
DISK_CONTROLLER="SATA Controller"
HOSTONLY_NAME="vboxnet-pxe"    # Dedicated host-only network

# ----------------------------
# Parse action
# ----------------------------
ACTION=""
case "$1" in
    -c|--create) ACTION="create" ;;
    -d|--destroy) ACTION="destroy" ;;
    -r|--run) ACTION="run" ;;
    -cr) ACTION="create_run" ;;
    *) echo "Usage: $0 [-c|--create | -d|--destroy | -r|--run | -cr]"; exit 1 ;;
esac

# ----------------------------
# Utility logging
# ----------------------------
log() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; }

# ----------------------------
# Destroy VMs
# ----------------------------
if [[ "$ACTION" == "destroy" ]]; then
    for i in $(seq 1 "$VM_COUNT"); do
        VM_NAME="${VM_PREFIX}${i}"
        if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
            log "Destroying $VM_NAME"
            VBoxManage controlvm "$VM_NAME" poweroff &>/dev/null || true
            VBoxManage unregistervm "$VM_NAME" --delete || true
        else
            log "$VM_NAME does not exist, skipping"
        fi
    done
    # Optionally remove host-only network if unused
    if VBoxManage list hostonlyifs | grep -q "$HOSTONLY_NAME"; then
        log "Removing dedicated host-only network $HOSTONLY_NAME"
        VBoxManage hostonlyif remove "$HOSTONLY_NAME"
    fi
    exit 0
fi

# ----------------------------
# Ensure dedicated host-only network exists
# ----------------------------
if ! VBoxManage list hostonlyifs | grep -q "$HOSTONLY_NAME"; then
    log "Creating dedicated host-only interface $HOSTONLY_NAME"
    VBoxManage hostonlyif create
    VBoxManage hostonlyif ipconfig "$HOSTONLY_NAME" --ip "$HOST_ONLY_IP" --netmask "$PXE_NET_MASK"
    # Disable DHCP on this network to avoid conflict with PXE DHCP
    VBoxManage dhcpserver remove --ifname "$HOSTONLY_NAME" || true
else
    log "Using existing host-only network: $HOSTONLY_NAME"
fi

# ----------------------------
# Create VMs
# ----------------------------
if [[ "$ACTION" == "create" || "$ACTION" == "create_run" ]]; then
    for i in $(seq 1 "$VM_COUNT"); do
        VM_NAME="${VM_PREFIX}${i}"
        VM_DIR="$HOME/VirtualBox VMs/$VM_NAME"
        VDI_PATH="$VM_DIR/$VM_NAME.vdi"

        if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
            log "$VM_NAME already exists, skipping creation"
            continue
        fi

        log "Creating $VM_NAME"
        VBoxManage createvm --name "$VM_NAME" --register

        # Configure VM hardware and networking
        VBoxManage modifyvm "$VM_NAME" \
            --memory "$MEMORY_MB" \
            --cpus "$CPUS" \
            --ioapic on \
            --boot1 net \
            --nic1 hostonly \
            --hostonlyadapter1 "$HOSTONLY_NAME" \
            --nic2 nat   # second NIC for internet

        mkdir -p "$VM_DIR"
        VBoxManage createmedium disk --filename "$VDI_PATH" --size "$DISK_SIZE_MB" --format VDI

        VBoxManage storagectl "$VM_NAME" \
            --name "$DISK_CONTROLLER" --add sata --controller IntelAhci

        VBoxManage storageattach "$VM_NAME" \
            --storagectl "$DISK_CONTROLLER" --port 0 --device 0 \
            --type hdd --medium "$VDI_PATH"

        log "$VM_NAME created"
    done
fi

# ----------------------------
# Run VMs
# ----------------------------
if [[ "$ACTION" == "run" || "$ACTION" == "create_run" ]]; then
    for i in $(seq 1 "$VM_COUNT"); do
        VM_NAME="${VM_PREFIX}${i}"
        if VBoxManage list runningvms | grep -q "\"$VM_NAME\""; then
            log "$VM_NAME already running"
            continue
        fi
        log "Starting $VM_NAME"
        VBoxManage startvm "$VM_NAME" --type headless
    done
fi

log "Done"


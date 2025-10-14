#!/bin/bash

# ----------------------------
# PXE Client Automation Script
# ----------------------------
# Works with VirtualBox on Debian
# Flags:
#   -c | --create  -> create VMs
#   -d | --destroy -> destroy VMs
#   -r | --run     -> run existing VMs
#   -cr            -> create then run

VM_PREFIX="pxe-client"
VM_COUNT=3
HOST_ONLY_IP="192.168.56.1"
NET_MASK="255.255.255.0"

# ----------------------------
# Determine action
# ----------------------------
ACTION=""
if [[ "$1" == "-c" || "$1" == "--create" ]]; then
    ACTION="create"
elif [[ "$1" == "-d" || "$1" == "--destroy" ]]; then
    ACTION="destroy"
elif [[ "$1" == "-r" || "$1" == "--run" ]]; then
    ACTION="run"
elif [[ "$1" == "-cr" ]]; then
    ACTION="create_run"
else
    echo "Usage: $0 [-c|--create | -d|--destroy | -r|--run | -cr]"
    exit 1
fi

# ----------------------------
# Destroy VMs
# ----------------------------
if [[ "$ACTION" == "destroy" ]]; then
    for i in $(seq 1 $VM_COUNT); do
        VM_NAME="${VM_PREFIX}${i}"
        if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
            echo "Destroying VM $VM_NAME..."
            VBoxManage controlvm "$VM_NAME" poweroff &>/dev/null || true
            VBoxManage unregistervm "$VM_NAME" --delete
        else
            echo "VM $VM_NAME does not exist, skipping..."
        fi
    done
    echo "Done destroying VMs."
    exit 0
fi

# ----------------------------
# Ensure host-only network exists
# ----------------------------
NET_NAME=$(VBoxManage list hostonlyifs | awk '/Name:/ {print $2}' | head -n1)
if [[ -z "$NET_NAME" ]]; then
    echo "Creating host-only network..."
    NET_NAME=$(VBoxManage hostonlyif create | awk -F': ' '{print $2}')
    VBoxManage hostonlyif ipconfig "$NET_NAME" --ip $HOST_ONLY_IP --netmask $NET_MASK
fi
echo "Using host-only network: $NET_NAME"

# ----------------------------
# Create VMs
# ----------------------------
if [[ "$ACTION" == "create" || "$ACTION" == "create_run" ]]; then
    for i in $(seq 1 $VM_COUNT); do
        VM_NAME="${VM_PREFIX}${i}"
        VM_DIR="$HOME/VirtualBox VMs/$VM_NAME"
        VDI_PATH="$VM_DIR/$VM_NAME.vdi"

        if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
            echo "VM $VM_NAME already exists, skipping creation."
            continue
        fi

        echo "Creating VM $VM_NAME..."
        VBoxManage createvm --name "$VM_NAME" --register
        VBoxManage modifyvm "$VM_NAME" \
            --memory 512 \
            --cpus 1 \
            --nic1 hostonly \
            --hostonlyadapter1 "$NET_NAME" \
            --boot1 net

        mkdir -p "$VM_DIR"
        VBoxManage createmedium disk --filename "$VDI_PATH" --size 10240 --format VDI
        VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci
        VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VDI_PATH"

        echo "VM $VM_NAME created and configured to boot via PXE."
    done
fi

# ----------------------------
# Run VMs
# ----------------------------
if [[ "$ACTION" == "run" || "$ACTION" == "create_run" ]]; then
    for i in $(seq 1 $VM_COUNT); do
        VM_NAME="${VM_PREFIX}${i}"
        if VBoxManage list runningvms | grep -q "\"$VM_NAME\""; then
            echo "VM $VM_NAME already running."
            continue
        fi
        echo "Starting VM $VM_NAME..."
        VBoxManage startvm "$VM_NAME" --type headless
    done
fi

echo "Operation '$ACTION' completed."
echo "Use 'VBoxManage list vms' to see your clients."


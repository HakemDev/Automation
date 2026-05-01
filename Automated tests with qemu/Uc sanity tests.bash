#!/bin/bash
SECONDS=0

# ======== Create images =========
qemu-img create -f qcow2 /home/live_update/1.qcow2 20G
qemu-img create -f qcow2 /home/live_update/2.qcow2 20G
qemu-img create -f qcow2 /home/live_update/3.qcow2 20G

chmod 777 /home/live_update/1.qcow2
chmod 777 /home/live_update/2.qcow2
chmod 777 /home/live_update/3.qcow2
# ========= Common Setup =========
DISK_PATHS=("/dev/shm/images/1.qcow2" "/dev/shm/images/2.qcow2" "/dev/shm/images/3.qcow2")
VIRTIO_DISK_TARGETS=("sdd" "sde" "sdf")
VDISK_TARGETS=("vda" "vdb" "vdc")
GUEST_NAME="vm2"
SOCK="/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock"


SUSPEND_LOG="/tmp/${GUEST_NAME}_suspend_resume_shutdown_test.log"
VNIC_LOG="/tmp/${GUEST_NAME}_vnic_test.log"
VDISK_LOG="/tmp/${GUEST_NAME}_vdisk_test.log"
VIRTIO_BLK_LOG="/tmp/${GUEST_NAME}_virtio_blk_test.log"
VCPU_LOG="/tmp/${GUEST_NAME}_vcpu_test.log"
KDUMP_LOG="/tmp/${GUEST_NAME}_Kdump_test.log"
HOST_INFO_LOG="/tmp/host_info.log"
# ========= Clean Logs =========
> "$HOST_INFO_LOG"
> "$SUSPEND_LOG"
> "$VNIC_LOG"
> "$VDISK_LOG"
> "$VIRTIO_BLK_LOG"
> "$VCPU_LOG"
> "$KDUMP_LOG"

echo "Running full test suite for guest: $GUEST_NAME"

#Create my guest
Guest_creation(){
guest="vm2"
qemu-system-uc -machine virt,accel=kvm -name guest=${guest},debug-threads=on -cpu host -m 64G,slots=8,maxmem=128G -smp cpus=8,maxcpus=32 \
-enable-kvm \
-drive file=/usr/share/AAVMF/AAVMF_CODE_2M.pure-efi.fd,if=pflash,format=raw,unit=0,readonly=on \
-drive file=/write-qemu/AAVMF_VARS_1M.pure-efi.fd,if=pflash,format=raw,unit=1 \
-hda /home/live_update/vm0.qcow2 -boot order=c,menu=on \
-chardev socket,id=mon_vm,path=/write-qemu/vm0.mon.sock,server=on,wait=off \
-mon chardev=mon_vm,mode=readline -device virtio-scsi-pci,id=scsi \
-device pcie-root-port,port=5,chassis=5,id=pciroot5,bus=pcie.0,addr=0x05 \
-device pcie-root-port,port=6,chassis=6,id=pciroot6,bus=pcie.0,addr=0x06 \
-device pcie-root-port,port=7,chassis=7,id=pciroot7,bus=pcie.0,addr=0x07 \
-device pcie-root-port,port=8,chassis=8,id=pciroot8,bus=pcie.0,addr=0x08 \
-device pcie-root-port,port=9,chassis=9,id=pciroot9,bus=pcie.0,addr=0x09 \
-device pcie-root-port,port=10,chassis=10,id=pciroot10,bus=pcie.0,addr=0x0a \
-device pcie-root-port,port=11,chassis=11,id=pciroot11,bus=pcie.0,addr=0x0b \
-device pcie-root-port,port=12,chassis=12,id=pciroot12,bus=pcie.0,addr=0x0c \
-device pcie-root-port,port=13,chassis=13,id=pciroot13,bus=pcie.0,addr=0x0d \
-device pcie-root-port,port=14,chassis=14,id=pciroot14,bus=pcie.0,addr=0x0e \
-device pcie-root-port,port=15,chassis=15,id=pciroot15,bus=pcie.0,addr=0x0f \
-device pcie-root-port,port=16,chassis=16,id=pciroot16,bus=pcie.0,addr=0x10 \
-device pcie-root-port,port=17,chassis=17,id=pciroot17,bus=pcie.0,addr=0x11 \
-device pcie-root-port,port=18,chassis=18,id=pciroot18,bus=pcie.0,addr=0x12 \
-device pcie-root-port,port=19,chassis=19,id=pciroot19,bus=pcie.0,addr=0x13 \
-device pcie-root-port,port=20,chassis=20,id=pciroot20,bus=pcie.0,addr=0x14 \
-device pcie-root-port,port=21,chassis=21,id=pciroot21,bus=pcie.0,addr=0x15 \
-device pcie-root-port,port=22,chassis=22,id=pciroot22,bus=pcie.0,addr=0x16 \
-device pcie-root-port,port=23,chassis=23,id=pciroot23,bus=pcie.0,addr=0x17 \
-device pcie-root-port,port=24,chassis=24,id=pciroot24,bus=pcie.0,addr=0x18 \
-device pcie-root-port,port=25,chassis=25,id=pciroot25,bus=pcie.0,addr=0x19 \
-device pcie-root-port,port=26,chassis=26,id=pciroot26,bus=pcie.0,addr=0x1a \
-device pcie-root-port,port=27,chassis=27,id=pciroot27,bus=pcie.0,addr=0x1b \
-device pcie-root-port,port=28,chassis=28,id=pciroot28,bus=pcie.0,addr=0x1c \
-device pcie-root-port,port=29,chassis=29,id=pciroot29,bus=pcie.0,addr=0x1d \
-device pcie-root-port,port=30,chassis=30,id=pciroot30,bus=pcie.0,addr=0x1e \
-device virtio-gpu-pci -device qemu-xhci -vnc :0 -usb -device usb-kbd -device usb-tablet \
-rtc base=localtime,clock=host,driftfix=slew \
-monitor telnet:127.0.0.1:4010,server,nowait \
-serial telnet:127.0.0.1:4000,server,nowait \
-vnc unix:/write-qemu/vnc0.sock -nodefaults -vga std &
}

Guest_creation

sleep 30

# ========= 1. Host Info Collection =========
{
    write_section() {
        echo "==================== $1 ===================="
    }

    write_section "OS VERSION"
    cat /etc/os-release
    echo ""

    write_section "ARCHITECTURE"
    uname -m
    echo ""

    write_section "SYSTEM SHAPE / DMI INFO"
    dmidecode -t 1 2>/dev/null
    echo ""

    write_section "KERNEL VERSION"
    uname -r
    echo ""

    write_section "QEMU PACKAGES"
    yum list installed | grep -i qemu
    echo ""

    write_section "EDK2 PACKAGES"
    yum list installed | grep -i edk2
    echo ""
} >> "$HOST_INFO_LOG"

echo "Host information saved to: $HOST_INFO_LOG"



# ========= 2. suspend_resume_reset_shutdown =========

{
    echo "[$(date '+%F %T')] ========= Starting test sequence for $GUEST_NAME ========="
    echo "\nStatus of VM..."
    printf 'info status\n' | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock"      
    sleep 10

    echo -e "\n\nStop VM..."
    echo -e  "stop" | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock"      
    sleep 5

    echo -e "\n\nStatus of VM..."
    printf 'info status\n' | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock"      
    sleep 5

    echo -e "\n\nResuming VM..."
    echo -e  "cont" | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock"     
    sleep 5

    echo -e "\n\nStatus of VM..."
    printf 'info status\n' | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock"      
    sleep 5

    echo -e "\n\nReset VM..."
    echo -e  "system_reset" | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock"      
    sleep 60

    echo -e "\n\nStatus of VM..."
    printf 'info status\n' | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock"      
    sleep 5

    echo -e "\n\nShutting down VM..."
    echo -e  "system_powerdown" | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock"      
    sleep 30

    echo "[SUCCESS] suspend/resume/reset/shutdown test completed"
} | tee -a "$SUSPEND_LOG"

Guest_creation

sleep 20


# ========= 3. vnic_hotplug_unplug_test =========
{

    Vnics_Nbr_before_hotplug=0
    Vnics_Nbr_After_hotplug=0
    Vnics_Nbr_After_Unplug=0
    Vnic_expected=24
    Vnic_origin_nbr=0
    vnic=0
		GUEST_NAME="vm2"
    echo -e "[$(date '+%F %T')] ========= Starting 24 VNIC hotplug/unplug test for $GUEST_NAME =========\n"

    # Step 1: Initial VNIC status
    echo -e "[$(date '+%F %T')] [STEP 1] Checking initial VNIC status...\n"
    echo "[$(date '+%F %T')] ---- VNIC Status: info network ----"

    printf 'info network\n' | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock"
    printf 'info network\n' | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock" > output
    Vnics_Nbr_before_hotplug=$(grep -c '^net[0-9]\+:' output)
    echo -e "\n--------------"
    echo -e "\nnumber of nic of hotplugg $Vnics_Nbr_before_hotplug \n"

    # Step 2: Attach 24 VNICs
    for i in {1..24}; do
        printf "netdev_add user,id=netdev$((i))\n" | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock"
    done

    sleep 10

    for i in {1..24}; do
        printf "device_add virtio-net-pci,id=net$i,netdev=netdev$((i)),bus=pciroot$((i+4))\n" | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock"
    done

    sleep 10

    # check network
    echo "[$(date '+%F %T')] ---- VNIC Status: info network ----"
    printf 'info network\n' | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock"
    printf 'info network\n' | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock" > output
    Vnics_Nbr_After_hotplug=$(grep -c '^net[0-9]\+:' output)
    echo -e "\n--------------"
    echo -e "\nnumber of nic $Vnics_Nbr_After_hotplug \n"

    echo -e " \nVnics_Nbr_After_hotplug: $Vnics_Nbr_After_hotplug \n"
    echo -e " \nVnic_expected: $Vnic_expected \n"
    if [ "$Vnics_Nbr_After_hotplug" -eq "$Vnic_expected" ]; then
        echo " ------------------------ hotplug done successfuly ------------------------"
    else
        echo " ------------------------ hotplug of vnics failed ------------------------"
        exit 1
    fi

    # Step 3: Detach the VNICs
    for i in {1..24}; do
        printf "netdev_del netdev$((i))\n" | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock"
    done
    
    for i in {1..24}; do
        printf "device_del net$((i))\n" | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock"
    done

    sleep 5

    # check network
    echo "[$(date '+%F %T')] ---- VNIC Status: info network ----"

    sleep 20
    printf 'info network\n' | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock"
    printf 'info network\n' | socat - UNIX-CONNECT:"/uc/instances/${GUEST_NAME}/write-qemu/vm0.mon.sock" > output2

    Vnics_Nbr_After_Unplug=$(grep -c '^net[0-9]\+:' output2)
    echo -e "\n--------------"
    echo -e "\nnumber of nic $Vnics_Nbr_After_Unplug \n"
    echo -e "\nVnics_Nbr_before_hotplug $Vnics_Nbr_before_hotplug \n"

   if [ "$Vnics_Nbr_After_Unplug" -eq "$Vnics_Nbr_before_hotplug" ]; then
        echo " ------------------------ Unplug done successfuly ------------------------"
    else
        echo " ------------------------ Unplug of vnics failed ------------------------"
        exit 1
    fi
} | tee -a "$VNIC_LOG"


# ========= 4 virtio-scsi vDisk hot plug/unplug =========

log() {
    echo -e "\n[$(date '+%F %T')] $1"
}

get_disk_count() {
    printf 'info block\n' | socat - UNIX-CONNECT:"$SOCK" | grep -c scsi-disk
}

wait_for_disk_count() {
    expected=$1
    retries=10

    for ((i=1; i<=retries; i++)); do
        current=$(get_disk_count)
        if [[ "$current" -eq "$expected" ]]; then
            return 0
        fi
        sleep 2
    done

    return 1
}


{

log "=== Starting Disk Hotplug Test ==="
GUEST_NAME="vm2"

# Step 1: Check initial state
initial_count=$(get_disk_count)
log "Initial disk count: $initial_count"

# Step 2: Add disks
for i in {1..3}; do
    disk_file="/home/live_update/$i.qcow2"

    if [[ ! -f "$disk_file" ]]; then
        log "ERROR: Missing disk file $disk_file"
        exit 1
    fi

    log "Adding disk $i"
    printf "drive_add 0 if=none,file=$disk_file,format=qcow2,id=scsi-disk$i\n" \
        | socat - UNIX-CONNECT:"$SOCK"

    sleep 1

    printf "device_add scsi-hd,drive=scsi-disk$i,id=scsi-dev$i\n" \
        | socat - UNIX-CONNECT:"$SOCK"

    sleep 1
done

# Step 3: Verify hotplug
expected_after_add=$((initial_count + 3))
log "Waiting for disks to appear..."

if wait_for_disk_count "$expected_after_add"; then
    log "Hotplug successful (count = $expected_after_add)"
else
    log "ERROR: Hotplug failed"
    exit 1
fi

# Step 4: Remove disks
for i in {1..3}; do
    log "Removing disk $i"

    printf "device_del scsi-dev$i\n" | socat - UNIX-CONNECT:"$SOCK"
    sleep 1

    printf "drive_del scsi-disk$i\n" | socat - UNIX-CONNECT:"$SOCK"
    sleep 1
done

# Step 5: Verify unplug
log "Waiting for disks to be removed..."

if wait_for_disk_count "$initial_count"; then
    log "Unplug successful (count = $initial_count)"
else
    log "ERROR: Unplug failed"
    exit 1
fi

log "=== Disk Hotplug Test Completed Successfully ==="

} | tee -a "$VDISK_LOG"

# ========= 5 virtio-blk-pci hotplug/unplug =========
log() {
    echo -e "\n[$(date '+%F %T')] $1"
}

get_disk_count() {
    printf 'info block\n' | socat - UNIX-CONNECT:"$SOCK" | grep -c blk-disk
}

wait_for_disk_count() {
    expected=$1
    retries=10

    for ((i=1; i<=retries; i++)); do
        current=$(get_disk_count)
        if [[ "$current" -eq "$expected" ]]; then
            return 0
        fi
        sleep 2
    done

    return 1
}

{
log "=== Starting virtio-blk-pci Hotplug Test ==="


# Step 1: Check initial state
initial_count=$(get_disk_count)
log "Initial disk count: $initial_count"

# Step 2: Add disks
for i in {1..3}; do
    disk_file="/home/live_update/$i.qcow2"

    if [[ ! -f "$disk_file" ]]; then
        log "ERROR: Missing disk file $disk_file"
        exit 1
    fi

    log "Adding disk $i"
    printf "drive_add 0 if=none,file=$disk_file,format=qcow2,id=blk-disk$i\n" \
        | socat - UNIX-CONNECT:"$SOCK"

    sleep 1
		
    printf "device_add virtio-blk-pci,drive=blk-disk$i,id=blk-dev$i,bus=pciroot$((6+i))\n" \
        | socat - UNIX-CONNECT:"$SOCK"

    sleep 1
done

# Step 3: Verify hotplug
expected_after_add=$((initial_count + 3))
log "Waiting for disks to appear..."

if wait_for_disk_count "$expected_after_add"; then
    echo -e "\n expected_after_add= $expected_after_add"
    log "Hotplug successful (count = $expected_after_add)"
else
    echo -e "\n expected_after_add= $expected_after_add"
    log "ERROR: Hotplug failed"
    exit 1
fi

# Step 4: Remove disks
for i in {1..3}; do
    log "Removing disk $i"

    printf "device_del blk-dev$i\n" | socat - UNIX-CONNECT:"$SOCK"
    sleep 2

    printf "drive_del blk-disk$i\n" | socat - UNIX-CONNECT:"$SOCK"
    sleep 1
done

# Step 5: Verify unplug
log "Waiting for disks to be removed..."

if wait_for_disk_count "$initial_count"; then
    log "Unplug successful (count = $initial_count)"
else
    log "ERROR: Unplug failed"
    exit 1
fi

log "=== virtio blk VDISK Test Completed Successfully ==="

} | tee -a "$VIRTIO_BLK_LOG"


#!/system/bin/sh

LOG=/persist/metroid-recovery-state.log
DMESG=/persist/metroid-recovery-dmesg.log
LOGCAT=/persist/metroid-recovery-logcat.log

{
    echo "=== boot ==="
    cat /proc/uptime
    cat /proc/cmdline
    cat /proc/bootconfig
    echo "=== block devices ==="
    ls -la /dev/block/bootdevice/by-name
    ls -la /dev/block/mapper
    echo "=== mounts ==="
    mount
    echo "=== modules ==="
    cat /proc/modules
} > "$LOG" 2>&1

i=0
while [ "$i" -lt 12 ]; do
    {
        echo "=== sample $i ==="
        cat /proc/uptime
        getprop | grep -E '\[(ro.boot|ro.crypto|crypto.metroid|metroid.vendor|vendor.sys.listeners|sys.usb|init.svc.adbd|twrp|fox)'
        echo "--- mapper ---"
        ls -la /dev/block/mapper
        echo "--- relevant mounts ---"
        mount | grep -E '(/vendor|/system|/product|/odm|/data|/metadata|configfs|functionfs)'
        echo "--- UDC ---"
        ls -la /sys/class/udc
        cat /config/usb_gadget/g1/UDC
        echo "--- processes ---"
        ps -A | grep -E '(recovery|adbd|fastboot|vold|keymint|keystore|gatekeeper|qseecom|vibrator)'
    } >> "$LOG" 2>&1
    sleep 5
    i=$((i + 1))
done

dmesg > "$DMESG" 2>&1
logcat -b all -d > "$LOGCAT" 2>&1
sync

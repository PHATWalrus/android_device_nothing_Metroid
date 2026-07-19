#!/system/bin/sh

LOG=/persist/of_usb.log
echo "=== USB bring-up ===" > "$LOG"

echo normal > /sys/devices/platform/soc/a600000.ssusb/orientation 2>>"$LOG"
echo peripheral > /sys/devices/platform/soc/a600000.ssusb/mode 2>>"$LOG"
for role in /sys/class/usb_role/*/role; do
    [ -e "$role" ] || continue
    echo device > "$role" 2>>"$LOG"
done

ls /sys/class/udc >> "$LOG" 2>&1
echo "state=$(getprop sys.usb.state)" >> "$LOG"

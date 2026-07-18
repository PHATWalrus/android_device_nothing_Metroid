#!/system/bin/sh

i=0
while [ ! -e /dev/aw86927_haptic ] && [ "$i" -lt 40 ]; do
    sleep 0.25
    i=$((i + 1))
done

mkdir -p /mnt/vendor/persist/haptic
chmod 0771 /mnt/vendor/persist/haptic
chown system:system /mnt/vendor/persist/haptic
chmod 0666 /dev/aw86927_haptic /proc/haptic/* 2>/dev/null
chown system:system /dev/aw86927_haptic /proc/haptic/* 2>/dev/null
chmod 0666 /sys/class/leds/vibrator_nt/* 2>/dev/null
chown system:system /sys/class/leds/vibrator_nt/* 2>/dev/null
setprop metroid.haptics.ready 1

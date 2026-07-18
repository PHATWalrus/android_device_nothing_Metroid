#!/system/bin/sh

TAG=METROID-PLATFORM

note() {
    log -t "$TAG" "$*"
}

fail() {
    setprop metroid.platform.error "$1"
    note "failed: $1"
    exit 1
}

setprop metroid.platform.ready 0
setprop metroid.platform.error ""
setprop metroid.battery.ready 0
setprop metroid.thermal.ready 0
setprop metroid.cpu.capped 0

aw_driver=/sys/bus/i2c/drivers/aw9380x_cap
if [ -e "$aw_driver/8-0012" ]; then
    echo 8-0012 > "$aw_driver/unbind" || fail aw9380x_unbind
fi

set_cpu_policy() {
    policy="$1"
    ceiling="$2"
    echo schedutil > "$policy/scaling_governor" || return 1
    echo "$ceiling" > "$policy/scaling_max_freq" || return 1
}

set_cpu_policy /sys/devices/system/cpu/cpufreq/policy0 1516800 || fail cpu_policy0
set_cpu_policy /sys/devices/system/cpu/cpufreq/policy2 2208000 || fail cpu_policy2
set_cpu_policy /sys/devices/system/cpu/cpufreq/policy5 2073600 || fail cpu_policy5
set_cpu_policy /sys/devices/system/cpu/cpufreq/policy7 2400000 || fail cpu_policy7
setprop metroid.cpu.capped 1

cpu_temp=""
for zone in /sys/class/thermal/thermal_zone*; do
    [ -r "$zone/type" ] || continue
    if [ "$(cat "$zone/type")" = "cpu-0-0-0" ]; then
        cpu_temp="$zone/temp"
        break
    fi
done
[ -n "$cpu_temp" ] || fail cpu_temp_sensor
ln -sf "$cpu_temp" /tmp/metroid_cpu_temp || fail cpu_temp_link
setprop metroid.thermal.ready 1

slot="$(getprop ro.boot.slot_suffix)"
case "$slot" in
    _a|_b) ;;
    *) fail slot_suffix ;;
esac

modem="/dev/block/by-name/modem${slot}"
dsp="/dev/block/by-name/dsp${slot}"
i=0
while { [ ! -e "$modem" ] || [ ! -e "$dsp" ]; } && [ "$i" -lt 30 ]; do
    sleep 0.1
    i=$((i + 1))
done
[ -e "$modem" ] || fail modem_block
[ -e "$dsp" ] || fail dsp_block

mkdir -p /tmp/metroid-firmware
if [ ! -r /tmp/metroid-firmware/image/adsp.mdt ]; then
    mount -t vfat -o ro "$modem" /tmp/metroid-firmware || fail modem_mount
fi
[ -r /tmp/metroid-firmware/image/adsp.mdt ] || fail modem_firmware
if ! grep -q ' /vendor/dsp ' /proc/mounts; then
    mount -t ext4 -o ro "$dsp" /vendor/dsp || fail dsp_mount
fi
if [ ! -r /vendor/firmware/adsp.mdt ]; then
    mount -o bind /tmp/metroid-firmware/image /vendor/firmware || fail firmware_bind
fi
[ -r /vendor/firmware/adsp.mdt ] || fail firmware_files

echo 1 > /proc/sys/kernel/firmware_config/force_sysfs_fallback || fail firmware_fallback

adsp=""
for remoteproc in /sys/class/remoteproc/remoteproc*; do
    [ -r "$remoteproc/name" ] || continue
    if [ "$(cat "$remoteproc/name")" = "3000000.remoteproc-adsp" ]; then
        adsp="$remoteproc"
        break
    fi
done
[ -n "$adsp" ] || fail adsp_remoteproc

if [ "$(cat "$adsp/state")" != "running" ]; then
    echo start > "$adsp/state" || fail adsp_start
fi

i=0
while [ ! -r /sys/class/power_supply/battery/capacity ] && [ "$i" -lt 20 ]; do
    sleep 0.25
    i=$((i + 1))
done
[ -r /sys/class/power_supply/battery/capacity ] || fail battery_timeout

setprop metroid.battery.ready 1
setprop metroid.platform.ready 1
note "ready: battery=$(cat /sys/class/power_supply/battery/capacity)% cpu_temp=$cpu_temp"

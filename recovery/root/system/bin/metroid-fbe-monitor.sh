#!/system/bin/sh

LOG=/persist/metroid-fbe.log
SERVICE=android.hardware.security.keymint.IKeyMintDevice/default

note() {
    echo "[METROID-FBE] $*" >> "$LOG"
    log -t METROID-FBE "$*"
}

setprop crypto.metroid.keymint_ready 0
setprop crypto.metroid.keymint_timeout 0
note "KeyMint registration monitor started"
i=0
while [ "$i" -lt 15 ]; do
    result="$(service check "$SERVICE" 2>&1)"
    if echo "$result" | grep -q ': found'; then
        note "KeyMint AIDL registered after ${i}s"
        setprop crypto.metroid.keymint_timeout 0
        setprop crypto.metroid.keymint_ready 1
        exit 0
    fi
    pid="$(pidof android.hardware.security.keymint-service-qti 2>/dev/null)"
    if [ -z "$pid" ]; then
        pid="$(ps -A | awk '/keymint-service-qti/ {print $2; exit}')"
    fi
    if [ -n "$pid" ]; then
        wchan="$(cat "/proc/$pid/wchan" 2>/dev/null)"
        note "sample=${i}s keymint_pid=$pid wchan=${wchan:-unknown}"
    else
        note "sample=${i}s keymint process absent"
    fi
    sleep 1
    i=$((i + 1))
done

setprop crypto.metroid.keymint_timeout 1
note "KeyMint did not register; keystore2 remains stopped"
{
    echo "[METROID-FBE] timeout state"
    getprop | grep -E '\[(ro.boot.verifiedbootstate|ro.boot.flash.locked|ro.boot.product.vendor.sku|vendor.sys.listeners.registered|init.svc.vendor.keymint-qti|crypto.metroid)'
    ps -A | grep -E '(keymint|qseecom|gatekeeper|keystore)'
    for task in /proc/$pid/task/*; do
        [ -e "$task/wchan" ] || continue
        echo "task=$(basename "$task") wchan=$(cat "$task/wchan")"
    done
    dmesg | grep -iE '(qtee|qsee|keymint|smcinvoke|trustzone)' | tail -n 80
} >> "$LOG" 2>&1
exit 1

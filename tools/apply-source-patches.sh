#!/usr/bin/env bash
set -euo pipefail

device_dir="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -n "${ANDROID_BUILD_TOP:-}" ]]; then
    top="$ANDROID_BUILD_TOP"
else
    top="$(cd "$device_dir/../../.." && pwd)"
fi

apply_patch_once() {
    local project="$1"
    local patch="$2"

    if git -C "$project" apply --reverse --check "$patch" >/dev/null 2>&1; then
        echo "already applied: ${patch#$device_dir/}"
        return 0
    fi

    git -C "$project" apply --check "$patch"
    git -C "$project" apply "$patch"
    echo "applied: ${patch#$device_dir/}"
}

require_project() {
    local project="$1"
    [[ -d "$project/.git" || -f "$project/.git" ]] || {
        echo "missing source project: $project" >&2
        exit 1
    }
}

require_project "$top/system/vold"
require_project "$top/bootable/recovery"

has_native_omapi_packaging() {
    local recovery="$1"

    [[ -f "$top/external/se_omapi/Android.bp" ]] && \
        grep -q "TW_INCLUDE_OMAPI" "$recovery/Android.mk" && \
        grep -q "se_omapi" "$recovery/Android.mk" && \
        grep -q "TW_INCLUDE_OMAPI" "$recovery/prebuilt/Android.mk" && \
        grep -q "se_omapi" "$recovery/prebuilt/Android.mk" && \
        grep -q "external/se_omapi" "$recovery/prebuilt/Android.bp" && \
        grep -q "LOCAL_MODULE := se_omapi.rc" "$recovery/etc/Android.mk" && \
        grep -q "LOCAL_MODULE := se_omapi.xml" "$recovery/etc/Android.mk"
}

# TeamWin 14 fallback patches.
if grep -q "AidlIGatekeeper" "$top/system/vold/Decrypt.cpp"; then
    echo "provided by source: AIDL Gatekeeper"
else
    apply_patch_once "$top/system/vold" \
        "$device_dir/patches/system_vold/0001-vold-support-AIDL-GateKeeper-1-2.patch"
fi

if grep -q "mAidlDevice" "$top/system/vold/Weaver1.cpp"; then
    echo "provided by source: AIDL Weaver"
else
    apply_patch_once "$top/system/vold" \
        "$device_dir/patches/system_vold/0002-vold-Add-support-for-AIDL-weaver-service-1-2.patch"
fi

keystore_wait_patch="$device_dir/patches/system_vold/0003-vold-bound-keystore2-service-wait.patch"
if grep -qF '[METROID-FBE] timed out waiting for keystore2' "$top/system/vold/Keystore.cpp"; then
    echo "provided by source: bounded keystore2 wait"
else
    apply_patch_once "$top/system/vold" "$keystore_wait_patch"
fi

single_wait_patch="$device_dir/patches/system_vold/0004-vold-avoid-repeated-keystore2-wait.patch"
if grep -qF 'keystore2_full_wait_done' "$top/system/vold/Keystore.cpp"; then
    echo "provided by source: single full keystore2 wait"
else
    apply_patch_once "$top/system/vold" "$single_wait_patch"
fi

filesystem_ids_patch="$device_dir/patches/bootable_recovery/0002-recovery-include-android-filesystem-config.patch"
if grep -q "private/android_filesystem_config.h" "$top/bootable/recovery/partitionmanager.cpp"; then
    echo "provided by source: partition manager Android filesystem IDs"
else
    apply_patch_once "$top/bootable/recovery" "$filesystem_ids_patch"
fi

pending_merge_patch="$device_dir/patches/bootable_recovery/0005-recovery-only-unmap-super-for-pending-merge.patch"
if grep -qF 'does not require a pre-wipe super unmap' "$top/bootable/recovery/partitionmanager.cpp"; then
    echo "provided by source: snapshot-aware data format"
else
    apply_patch_once "$top/bootable/recovery" "$pending_merge_patch"
fi

haptics_lookup_patch="$device_dir/patches/bootable_recovery/0003-recovery-use-nonblocking-vibrator-lookup.patch"
if grep -qF 'AServiceManager_checkService(kVibratorInstance.c_str())' "$top/bootable/recovery/minuitwrp/events.cpp"; then
    echo "provided by source: non-blocking vibrator lookup"
else
    apply_patch_once "$top/bootable/recovery" "$haptics_lookup_patch"
fi

gui_poll_patch="$device_dir/patches/bootable_recovery/0004-recovery-sleep-between-gui-input-polls.patch"
if grep -qF 'kMaxInputPollSleepUs = 1000' "$top/bootable/recovery/gui/gui.cpp"; then
    echo "provided by source: bounded GUI input polling"
else
    apply_patch_once "$top/bootable/recovery" "$gui_poll_patch"
fi

# Verify native OrangeFox OMAPI support.
omapi_patch="$device_dir/patches/bootable_recovery/0001-recovery-package-native-OMAPI-on-14.1.patch"
if has_native_omapi_packaging "$top/bootable/recovery"; then
    echo "provided by source: native OMAPI packaging"
elif git -C "$top/bootable/recovery" apply --reverse --check "$omapi_patch" >/dev/null 2>&1; then
    echo "already applied: ${omapi_patch#$device_dir/}"
elif git -C "$top/bootable/recovery" apply --check "$omapi_patch" >/dev/null 2>&1; then
    apply_patch_once "$top/bootable/recovery" "$omapi_patch"
else
    echo "OMAPI packaging is partial or this is a diverged recovery source; refusing to force the TeamWin fallback patch." >&2
    echo "Expected a complete OrangeFox fox_14.1 recovery checkout plus external/se_omapi/Android.bp." >&2
    echo "Re-sync bootable/recovery, vendor/recovery, and external/se_omapi with the official OrangeFox fox_14.1 sync, then rerun this helper." >&2
    exit 1
fi

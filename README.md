# OrangeFox device tree for Nothing Phone (3)

Android recovery device tree for the Nothing Phone (3), codenamed `Metroid`.

## Device

| Item | Value |
| --- | --- |
| Device | Nothing Phone (3) |
| Model | A024 |
| Codename | Metroid |
| Platform | Qualcomm SM8735 (`sun`) |
| Architecture | arm64 |
| Recovery branch | OrangeFox `fox_14.1` |
| Partition scheme | A/B, Virtual A/B, dynamic partitions |
| Recovery partition | 104857600 bytes |
| Data filesystem | F2FS |

## Status

| Feature | Status |
| --- | --- |
| Boot | Working |
| Touchscreen | Working |
| ADB | Working |
| 120 Hz UI | Working |
| Battery and CPU temperature | Testing |
| Power button | Testing |
| AIDL haptics | Testing |
| FBE decryption | Testing |
| Fastbootd | Rebuild required |

MTP is disabled.

## Build

Sync the OrangeFox 14.1 source and clone this tree to
`device/nothing/Metroid`.

```bash
cd ~/fox_14.1

export FOX_BUILD_DEVICE=Metroid
export CCACHE_DIR=/mnt/ccache
ccache -M 50G -F 0

source build/envsetup.sh
lunch twrp_Metroid-ap2a-eng

bash device/nothing/Metroid/tools/apply-source-patches.sh
bash device/nothing/Metroid/tools/verify-orangefox-source.sh

mka recoveryimage -j"$(nproc)"
```

The recovery image is written to:

```text
out/target/product/Metroid/recovery.img
```

## Dirty build

```bash
mka recoveryimage -j"$(nproc)"
```

Run `mka relink_libraries` first after changing recovery C++ sources.

## Fastbootd test

```bash
adb reboot fastboot
fastboot devices
fastboot getvar is-userspace
```

`is-userspace` should return `yes`.

## Notes

- The device name is case-sensitive: use `Metroid`.
- The recovery image contains no kernel or DTB.
- `TW_INCLUDE_OMAPI` uses the native OrangeFox 14.1 implementation.
- Proprietary files are intentionally not ignored by Git.
- Keep a stock recovery image available before flashing test builds.

## Credits

- [OrangeFox Recovery Project](https://gitlab.com/OrangeFox)
- [TeamWin Recovery Project](https://github.com/TeamWin)
- [wisevessel/np3-devtree](https://gitlab.com/wisevessel/np3-devtree)
- [Farpathan/android_device_nothing_metroid](https://github.com/Farpathan/android_device_nothing_metroid)

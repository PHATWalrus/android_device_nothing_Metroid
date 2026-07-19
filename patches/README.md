# OrangeFox 14.1 source patches

Run after each clean source sync:

    bash device/nothing/Metroid/tools/apply-source-patches.sh

OMAPI, dmctl, dynamic-super sizing, and settings persistence are configured
from the device tree. The helper only applies compatibility or runtime fixes
that fox_14.1 cannot express through device variables or ramdisk init. Every
patch is checked before it is applied.

The remaining patches cover AIDL Gatekeeper/Weaver compatibility, bounded
keystore2 waits, Android filesystem IDs, non-blocking AIDL haptics, bounded
GUI polling, snapshot-state-aware formatting, and serialized GUI USB changes.

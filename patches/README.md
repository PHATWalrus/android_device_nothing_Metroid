# OrangeFox 14.1 source patches

Run after each clean source sync:

    bash device/nothing/Metroid/tools/apply-source-patches.sh

The helper applies missing AIDL Gatekeeper/Weaver support, the recovery
filesystem-ID include, native OMAPI packaging when needed, the bounded
keystore2 wait, non-blocking vibrator lookup, bounded GUI input polling, and
snapshot-aware data formatting. Every patch is checked first.

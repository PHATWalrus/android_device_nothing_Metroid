#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <extracted-firmware-root>" >&2
    exit 2
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source_root="$(cd "$1" && pwd)"
destination_root="$repo_root/proprietary"
count=0

while IFS='|' read -r relative expected_hash; do
    [[ -z "$relative" || "$relative" == \#* ]] && continue
    source_file="$source_root/$relative"
    destination_file="$destination_root/$relative"

    [[ -f "$source_file" ]] || { echo "missing firmware file: $source_file" >&2; exit 1; }
    actual_hash="$(sha256sum "$source_file" | awk '{print $1}')"
    [[ "$actual_hash" == "$expected_hash" ]] || {
        echo "hash mismatch: $source_file" >&2
        echo "expected $expected_hash" >&2
        echo "actual   $actual_hash" >&2
        exit 1
    }

    mkdir -p "$(dirname "$destination_file")"
    cp -f "$source_file" "$destination_file"
    count=$((count + 1))
done < "$repo_root/proprietary-files.txt"

echo "Extracted and verified $count Metroid recovery blobs."

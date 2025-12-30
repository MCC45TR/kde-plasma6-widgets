#!/bin/bash
# Find Windows Mount Point
TARGET_MNT=""

# Iterate over NTFS/fuseblk partitions
# We use lsblk to find mountpoints
lsblk -rno MOUNTPOINT,FSTYPE | grep -E 'ntfs|fuseblk' | awk '{print $1}' | while read -r mnt; do
    if [ -z "$mnt" ]; then continue; fi
    
    # Check for ntoskrnl.exe
    KERNEL_PATH=""
    if [ -f "$mnt/Windows/System32/ntoskrnl.exe" ]; then
        KERNEL_PATH="$mnt/Windows/System32/ntoskrnl.exe"
    elif [ -f "$mnt/Windows/system32/ntoskrnl.exe" ]; then
        KERNEL_PATH="$mnt/Windows/system32/ntoskrnl.exe"
    fi

    if [ -n "$KERNEL_PATH" ]; then
        # Extract version
        # Look for 10.0.x.x pattern
        VERSION=$(strings -e l "$KERNEL_PATH" | grep -m 1 "10\.0\.[0-9]\+" | cut -d " " -f 1)
        if [ -n "$VERSION" ]; then
            echo "$VERSION"
            exit 0
        fi
    fi
done

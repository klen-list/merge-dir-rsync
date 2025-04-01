#!/bin/bash

SOURCE_DIRS=(
    "source1"
    "source2"
#    "source3"
)
DEST_DIR="target_dir"

if [ ! -d "$DEST_DIR" ]; then
    echo "[Sync] $DEST_DIR not found, no sync needed"
    exit 0
fi

generate_blacklist() {
    local source="$1"
    local blacklist_file="rsync_blacklist.txt"
    > "$blacklist_file"  # Clear file
    for dir in "${SOURCE_DIRS[@]}"; do
        if [ "$dir" != "$source" ]; then
            ls "$dir" | sed 's/^/- /' >> "$blacklist_file"
        fi
    done
}

compare_and_sync() {
    local source="$1"
    local dest="$2"
    local source_name=$(basename "$source")

    echo "[Sync] Check diff between $source and $dest"

    generate_blacklist "$source"
    differences=$(rsync -rcnv --exclude-from=rsync_blacklist.txt "$dest/" "$source/" | grep -v "^sending incremental file list$" | grep -v "^$" | grep -v "^sent .* bytes  received .* bytes.*$" | grep -v "^total size is.*$")

    if [ -n "$differences" ]; then
        echo "[Sync] WARNING! NEXT FILES ARE DIFFERENCE!!!"
        echo "$differences"

        read -p "Sync $source_name? (y/n) " answer
        if [[ $answer == "y" ]]; then
            rsync -qrc --exclude-from=rsync_blacklist.txt "$dest/" "$source/"
            echo "Sync $source_name complete"
        else
            echo "Sync $source_name skipped"
        fi
    else
        echo "[Sync] $source and $dest are same"
    fi

    echo "------------------------"
}

for source in "${SOURCE_DIRS[@]}"; do
    compare_and_sync "$source" "$DEST_DIR"
done

rm rsync_blacklist.txt
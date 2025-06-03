#!/bin/bash

# Backup script - backs up using rclone.
# If no local directory is given, all directories in the current directory
# will be backed up.
# Usage: ./rclone_backup.sh [local-dir|.] <remote-name>

if [ $# -ne 2 ]; then
    echo "Usage: $0 [local-dir|.] <remote-name>"
    echo "Examples:"
    echo "  $0 ~/Documents documents    # backup specific directory"
    echo "  $0 . documents              # backup all subdirs in current dir"
    exit 1
fi

DIR="$1"
REMOTE="$2"

# Validate local directory exists
if [ ! -d "$DIR" ]; then
    echo "Error: Local directory '$DIR' does not exist."
    exit 1
fi

# Validate remote exists
if ! rclone listremotes | grep -q "^${REMOTE}:$"; then
    echo "Error: Remote '$REMOTE' not found in rclone config"
    echo "Available remotes:"
    rclone listremotes
    exit 1
fi

echo "Starting backup from: $(realpath "$DIR")"
echo "Using remote: $REMOTE"
echo "Backup time: $(date)"

backup_directory() {
    local source_dir="$1"
    local dest_name="$2"

    echo "Backing up $source_dir -> $REMOTE:$dest_name..."
    rclone sync "$source_dir" "$REMOTE:$dest_name" \
        --progress \
        --exclude="*.tmp" \
        --exclude=".DS_Store" \
        --exclude="Thumbs.db" \
        --exclude="*.swp" \
        --exclude=".git/" \
        --stats=10s

    if [ $? -eq 0 ]; then
        echo "✓ $dest_name backup completed"
    else
        echo "✗ $dest_name backup failed"
        return 1
    fi
}

if [ "$DIR" = "." ]; then
    # Backup all subdirectories in current directory
    found_dirs=false
    for dir in */; do
        if [ -d "$dir" ]; then
            dirname="${dir%/}"
            backup_directory "$dirname" "$dirname"
            found_dirs=true
        fi
    done

    if [ "$found_dirs" = false ]; then
        echo "No subdirectories found in $(pwd)"
        exit 1
    fi
else
    # Backup specific directory
    if [ ! -d "$DIR" ]; then
        echo "Error: Directory '$DIR' does not exist"
        exit 1
    fi

    # Use basename for remote path
    dest_name=$(basename "$DIR")
    backup_directory "$DIR" "$dest_name"
fi

echo "All backups completed: $(date)"

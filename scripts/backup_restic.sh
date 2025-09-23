#!/bin/bash
set -e

# Folgende ENVs sind für restic und rclone erforderlich
# - RESTIC_REPOSITORY
# - BACKUP_LOCATION
# - RCLONE_CONFIG
# - RESTIC_PASSWORD_FILE / RESTIC_PASSWORD / RESTIC_PASSWORD_COMMAND

source ./scripts/utils.sh

if is_true "$DEBUG_MODE"; then
  set -x
fi

backup_location="${BACKUP_LOCATION:-/var/mcserver/}"
export RCLONE_CONFIG="${RCLONE_CONFIG:-/run/secrets/rcloneconfig}"

if [ -z "${RESTIC_REPOSITORY}" ]; then
    echo -e "\n[${CYAN} INFO ${RESET}] restic Backup is disabled! No RESTIC_REPOSITORY provided!"
    exit 0
fi

if [ ! -d "$backup_location" ]; then
    echo -e "\n[${CYAN} INFO ${RESET}] Minecraft server is not initialized"
    exit 0
fi



# Check if repo is not initialized
check_restic_repo() {
    if restic cat config >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

init_restic_repo() {
    set +e
    if ! check_restic_repo; then
        echo -e "\n[${CYAN} INFO ${RESET}] Initializing Restic repository..."
        if restic init; then
            echo -e "\n[${CYAN} INFO ${RESET}] Repository successfully initialized"
        else
            echo -e "\n[${PURPLE} ERROR ${RESET}] Repository could not be initialized!"
            exit 1
        fi
    fi

    set -e
}

backup_restic() {
    local tag1="$1"
    local tag2="$(date +"$(eval echo "${BACKUP_FILE_FORMAT}")")"

    echo -e "\n[${CYAN} INFO ${RESET}] Starting restic backup"

    if restic backup --tag "$tag1" --tag "$tag2" "$backup_location"; then
        echo -e "\n[${CYAN} INFO ${RESET}] restic backup completed successfully"
    else
        echo -e "\n[${PURPLE} ERROR ${RESET}] restic backup failed!"
        exit 1
    fi
}


# Script start

if ! is_true "$BACKUP_RESTIC_SKIP_INIT"; then
    init_restic_repo
else
    echo -e "[${CYAN} INFO ${RESET}] Skipping Restic repository initialization"
fi


backup_restic "$1"
#!/bin/bash
set -e

# =======================
# Default Environment Variables
# =======================
: "${RCLONE_CONFIG:=/run/secrets/rcloneconfig}"
: "${BACKUP_RESTIC_FORGET_ENABLED:=true}"
: "${BACKUP_RESTIC_FORGET_ARGS:=--keep-last 7 --prune}"

# Folgende ENVs sind für restic und rclone erforderlich
# - RESTIC_REPOSITORY
# - BACKUP_LOCATION
# - RCLONE_CONFIG
# - RESTIC_PASSWORD_FILE / RESTIC_PASSWORD / RESTIC_PASSWORD_COMMAND

source ./scripts/utils.sh

if is_true "$DEBUG_MODE"; then
  set -x
fi

backup_location="$BACKUP_LOCATION"
export RCLONE_CONFIG

if [ -z "${RESTIC_REPOSITORY}" ]; then
    echo -e "\n[${CYAN} INFO ${RESET}] restic Backup is disabled! No RESTIC_REPOSITORY provided!"
    exit 0
fi

if [ ! -d "$backup_location" ]; then
    echo -e "\n[${CYAN} INFO ${RESET}] Minecraft server is not initialized"
    exit 0
fi

is_repo_initialized() {
    if restic cat config >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

init_restic_repo_unless_exists() {
    set +e
    if ! is_repo_initialized; then
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

restic_forget() {
    local forget_args="$BACKUP_RESTIC_FORGET_ARGS"
    echo -e "\n[${CYAN} INFO ${RESET}] Starting restic forget with args: ${forget_args}"
    if restic forget ${forget_args}; then
        echo -e "\n[${CYAN} INFO ${RESET}] restic forget completed successfully"
    else
        echo -e "\n[${PURPLE} ERROR ${RESET}] restic forget failed!"
        exit 1
    fi
}

if ! is_true "$BACKUP_RESTIC_SKIP_INIT"; then
    init_restic_repo_unless_exists
else
    echo -e "[${CYAN} INFO ${RESET}] Skipping Restic repository initialization"
fi

backup_restic "$1"

if is_true "$BACKUP_RESTIC_FORGET_ENABLED"; then
    restic_forget
else
    echo -e "[${CYAN} INFO ${RESET}] restic forget is disabled"
fi
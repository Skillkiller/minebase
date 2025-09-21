#!/bin/bash

set -e
source ./scripts/utils.sh

if is_true "$DEBUG_MODE"; then
  set -x
fi

backup_rclone() {
  if ./scripts/backup_rclone.sh "$1" 2>&1 | tee output.log; then
    notify "$BACKUP_SUCCESS_SCRIPT" "$(cat output.log)"
  else
    notify "$BACKUP_FAILED_SCRIPT" "$(cat output.log)"
  fi
}

BUILD_SCRIPT=$(realpath ./scripts/build.sh)
RUN_SCRIPT=$(realpath ./scripts/run.sh)

./scripts/information.sh
is_true "$PRE_START_BACKUP" && backup_rclone "pre" &

if [ -f "$BUILD_SCRIPT" ]; then 
  "$BUILD_SCRIPT"
else
  echo -e "${PURPLE}ATTENTION: No build script at $BUILD_SCRIPT existent!${RESET}"
fi

if [ -f "$RUN_SCRIPT" ]; then 
  "$RUN_SCRIPT"
else
  echo -e "${PURPLE}No run script at $RUN_SCRIPT existent!${RESET}"
  exit 1
fi

is_true "$POST_START_BACKUP" && backup_rclone "post"
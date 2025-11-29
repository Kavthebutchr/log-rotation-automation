#!/usr/bin/env bash
# log-rotation.sh
# Rotate, compress, cleanup logs and alert on /var usage.
# Safe to run from cron (idempotent). Supports --dry-run and --force.

set -u

# Default config
LOG_DIR="/var/log/myapp"
APP_LOG="$LOG_DIR/app.log"
TASK_LOG="$LOG_DIR/rotation-task.log"
LOCK_DIR="/var/lock/log-rotation.lock"
KEEP_DAYS=7
WARN_THRESHOLD=75
CRITICAL_THRESHOLD=90
EXIT_THRESHOLD=95
DRY_RUN=0
FORCE=0

timestamp() { date +"%Y-%m-%d %H:%M:%S"; }
log() {
  local msg="$1"
  echo "$(timestamp) - $msg" >> "$TASK_LOG"
}

echo_and_log() {
  local msg="$1"
  echo "$msg"
  log "$msg"
}

usage() {
  cat <<EOF
Usage: $0 [--dry-run] [--force]
  --dry-run   : show actions but don't change files
  --force     : run even if disk usage < warn threshold
EOF
}

# Parse args
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $arg"; usage; exit 1 ;;
  esac
done

# Ensure log dir exists
if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$LOG_DIR"
fi

# Create task log if missing
if [ "$DRY_RUN" -eq 0 ] && [ ! -f "$TASK_LOG" ]; then
  touch "$TASK_LOG"
fi

# Acquire simple lock (mkdir is atomic)
if mkdir "$LOCK_DIR" 2>/dev/null; then
  trap 'rmdir "$LOCK_DIR" >/dev/null 2>&1' EXIT
else
  echo "Another instance is running. Exiting." >&2
  exit 0
fi

# Function: check disk usage
check_disk() {
  # Get numeric percent for /var
  local pcent
  pcent=$(df --output=pcent /var | tail -1 | tr -dc '0-9')
  if [ -z "$pcent" ]; then
    echo "Failed to read disk usage for /var" >&2
    pcent=0
  fi
  echo "$pcent"
}

# Function: rotate log
rotate_log() {
  if [ ! -f "$APP_LOG" ]; then
    echo_and_log "No app log at $APP_LOG; nothing to rotate."
    return
  fi
  local ts
  ts=$(date +"%Y%m%d-%H%M")
  local rotated="$LOG_DIR/app-$ts.log"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN: mv '$APP_LOG' '$rotated'"
  else
    mv "$APP_LOG" "$rotated"
    # recreate empty app.log with same permissions as parent
    touch "$APP_LOG"
  fi
  echo_and_log "Rotated $APP_LOG -> $rotated"
}

# Function: compress rotated logs
compress_logs() {
  # Target pattern: app-YYYYMMDD-HHMM.log
  shopt -s nullglob
  local f
  for f in "$LOG_DIR"/app-*.log; do
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "DRY-RUN: gzip '$f'"
    else
      # gzip -9 to maximize compression; -f to overwrite if exists
      gzip -9 -f "$f"
      echo_and_log "Compressed $f -> $f.gz"
    fi
  done
  shopt -u nullglob
}

# Function: delete old gz files
cleanup_old() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN: find $LOG_DIR -name 'app-*.log.gz' -mtime +$KEEP_DAYS -print -delete"
  else
    # find and delete
    find "$LOG_DIR" -name 'app-*.log.gz' -mtime +$KEEP_DAYS -print -delete | while read -r removed; do
      echo_and_log "Deleted old log: $removed"
    done
  fi
}

# Start
current_usage=$(check_disk)

if [ "$FORCE" -eq 0 ]; then
  if [ "$current_usage" -ge "$EXIT_THRESHOLD" ]; then
    echo_and_log "CRITICAL: /var partition at ${current_usage}% (>= ${EXIT_THRESHOLD}%). Exiting with code 2."
    exit 2
  elif [ "$current_usage" -ge "$CRITICAL_THRESHOLD" ]; then
    echo_and_log "CRITICAL: /var partition almost full! ${current_usage}%"
  elif [ "$current_usage" -ge "$WARN_THRESHOLD" ]; then
    echo_and_log "WARNING: /var partition reaching critical usage: ${current_usage}%"
  else
    echo_and_log "/var usage at ${current_usage}% - below warning threshold (${WARN_THRESHOLD}%)."
  fi
else
  echo_and_log "FORCE mode: ignoring thresholds (current /var usage ${current_usage}%)"
fi

# If we are below warning and not forced, proceed normally: rotation still okay
# Rotate, compress, cleanup
rotate_log
compress_logs
cleanup_old

echo_and_log "Rotation task completed. Current /var usage: ${current_usage}%"

exit 0

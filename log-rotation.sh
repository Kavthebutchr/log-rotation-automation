#!/usr/bin/env bash
# log-rotation.sh
# Rotate and compress logs; cleanup old logs.
# Safe to run with cron.

# Configuration
LOG_DIR="/tmp/myapp-test/log"
APP_LOG="$LOG_DIR/app.log"
KEEP_DAYS=7

# Rotate log
if [ -f "$APP_LOG" ]; then
    TIMESTAMP=$(date +"%Y%m%d-%H%M")
    ROTATED="$LOG_DIR/app-$TIMESTAMP.log"
    mv "$APP_LOG" "$ROTATED"
    echo "Rotated $APP_LOG -> $ROTATED"
else
    echo "No log file to rotate."
fi

# Compress rotated logs
for f in $LOG_DIR/app-*.log; do
    [ -f "$f" ] && gzip "$f"
done

# Cleanup old logs
find $LOG_DIR -name "app-*.log.gz" -mtime +$KEEP_DAYS -delete


#!/usr/bin/env bash
# test.sh — demo for log-rotation.sh

# Create temporary test directory
mkdir -p /tmp/myapp-test/log
echo "line1" > /tmp/myapp-test/log/app.log

# Run log rotation script in dry-run mode
bash ../log-rotation.sh --dry-run

# Show files in test directory
ls -lh /tmp/myapp-test/log

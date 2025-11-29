# Log Rotation Script

Simple Bash script to rotate and compress logs, and cleanup old logs.

## Usage

Run the script manually:
```bash
bash log-rotation.sh
```

## Testing Locally

1. Create a test directory and a fake log:
```bash
mkdir -p /tmp/myapp-test/log
echo "line1" > /tmp/myapp-test/log/app.log
```
2. Update `LOG_DIR` in the script to point to `/tmp/myapp-test/log`.
3. Run the script:
```bash
bash log-rotation.sh
```
4. Check files:
```bash
ls -lh /tmp/myapp-test/log
```

## Cleanup

Logs older than 7 days are automatically deleted.

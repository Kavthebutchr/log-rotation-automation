# Log Rotation Automation Script

This project contains a production-ready Bash script that automates log rotation, compression, cleanup, and disk-usage alerting for a Linux environment. It is designed to be safe for cron execution and suitable for DevOps environments.

## Features

* Rotates `app.log` into timestamped files
* Compresses rotated logs into `.gz`
* Deletes compressed logs older than a set number of days
* Warns and alerts based on `/var` partition disk usage
* Exits with error if usage exceeds a critical limit
* Logs all actions to a task log
* Safe for cron (uses lock directory)
* Supports `--dry-run` and `--force` options

## Project Structure

```
log-rotation.sh   # Main automation script
README.md         # Documentation
LICENSE           # MIT License (optional)
.gitignore        # Git ignore patterns
```

## Usage

Run the script manually:

```bash
bash log-rotation.sh
```

Dry run:

```bash
bash log-rotation.sh --dry-run
```

Force mode (ignore disk thresholds):

```bash
bash log-rotation.sh --force
```

## Cron Example

Run every 15 minutes:

```
*/15 * * * * /usr/local/bin/log-rotation.sh >> /var/log/myapp/rotation-cron.log 2>&1
```

## Testing Locally

1. Create a test directory:

```bash
mkdir -p /tmp/myapp-test/log
```

2. Change `LOG_DIR` inside the script to point to:

```
/tmp/myapp-test/log
```

3. Run tests using dry-run and real mode.

## Contributing

Feel free to submit improvements or additional ideas once the project is in GitHub.

## License

This project will use the MIT License (see `LICENSE` file).

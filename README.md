# Resource Monitor (PowerShell)

A PowerShell script to monitor CPU, memory, disk usage, and open file descriptors on Windows. The script runs as a background job and logs system resource usage, issuing warnings when usage exceeds predefined thresholds.

## Features

- Monitors CPU, memory, and disk usage.
- Checks for open file descriptors.
- Logs messages to a file with timestamps.
- Issues warnings when resource usage exceeds configurable thresholds.
- Supports `start`, `stop`, and `restart` commands for easy management.

## Requirements

- Windows PowerShell.
- Administrator privileges may be required for some system counters.

## Configuration

Set the following thresholds in the script (default values provided):

- `CPU_THRESHOLD`: CPU usage percentage threshold (default: 90%).
- `MEM_THRESHOLD`: Memory usage percentage threshold (default: 80%).
- `DISK_THRESHOLD`: Disk usage percentage threshold (default: 85%).
- `FD_THRESHOLD`: Maximum allowed open file descriptors (default: 1000).
- `INTERVAL`: Interval in seconds between checks (default: 10 seconds).

## Usage

1. **Download the script** to a directory of your choice.
2. **Run the script** from PowerShell with the following commands:

  powershell
   .\Resource-Monitor.ps1 {start|stop|restart}
  

   - `start`: Starts the resource monitor in the background.
   - `stop`: Stops the resource monitor and cleans up the job.
   - `restart`: Restarts the resource monitor.

### Examples

To start monitoring:
powershell
.\Resource-Monitor.ps1 start


To stop monitoring:
powershell
.\Resource-Monitor.ps1 stop


To restart monitoring:
powershell
.\Resource-Monitor.ps1 restart


## Logging

- Logs are saved in `resource_monitor.log` in the same folder as the script.
- Each log entry contains a timestamp and message detailing the resource check results.

## PID File

- The script saves the background job ID to `resource_monitor.pid` in the same folder as the script.
- This file is used to manage the job when stopping or restarting the script.

## Example Log Output


2024-11-07 14:00:00 - Starting resource monitor...
2024-11-07 14:00:10 - Starting resource check...
2024-11-07 14:00:10 - WARNING: CPU usage is above 90% - Current: 92.5%
2024-11-07 14:00:10 - WARNING: Memory usage is above 80% - Current: 83.2%
2024-11-07 14:00:10 - WARNING: Disk usage on C: is above 85% - Current: 88.6%
2024-11-07 14:00:10 - Resource check complete.


## Notes

- Ensure the script has the necessary permissions to access system counters.
- If the PID file is missing or corrupted, a stale job ID may prevent normal operation. In this case, delete the `resource_monitor.pid` file and restart the script.

## License

This project is licensed under the MIT License.

# Resource-Monitor.ps1
# PowerShell script to monitor CPU, memory, disk, and file descriptors on Windows

# Configuration - thresholds and log file
$CPU_THRESHOLD = 90
$MEM_THRESHOLD = 80
$DISK_THRESHOLD = 85
$FD_THRESHOLD = 1000  # File descriptor threshold

$LOG_FILE = Join-Path -Path $PSScriptRoot -ChildPath "resource_monitor.log"
$PID_FILE = Join-Path -Path $PSScriptRoot -ChildPath "resource_monitor.pid"
$INTERVAL = 10  # Monitoring interval in seconds

# Function to log messages
function Log-Message {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -Append -FilePath $LOG_FILE
}

# Function to check CPU usage
function Check-CPU {
    $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue
    if ($cpuUsage -gt $CPU_THRESHOLD) {
        Log-Message "WARNING: CPU usage is above $CPU_THRESHOLD% - Current: $([math]::Round($cpuUsage, 2))%"
    }
}

# Function to check memory usage
function Check-Memory {
    $memory = Get-WmiObject -Class Win32_OperatingSystem
    $memUsage = (($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100
    if ($memUsage -gt $MEM_THRESHOLD) {
        Log-Message "WARNING: Memory usage is above $MEM_THRESHOLD% - Current: $([math]::Round($memUsage, 2))%"
    }
}

# Function to check disk space usage
function Check-Disk {
    $diskUsage = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used / $_.Free * 100 -gt $DISK_THRESHOLD }
    foreach ($drive in $diskUsage) {
        $usagePercent = ($drive.Used / ($drive.Used + $drive.Free)) * 100
        Log-Message "WARNING: Disk usage on $($drive.Name) is above $DISK_THRESHOLD% - Current: $([math]::Round($usagePercent, 2))%"
    }
}

# Function to check open file descriptors (open handles)
function Check-FileDescriptors {
    $fdCount = (Get-Process | Measure-Object -Property Handles -Sum).Sum
    if ($fdCount -gt $FD_THRESHOLD) {
        Log-Message "WARNING: Number of open file descriptors is above $FD_THRESHOLD - Current: $fdCount"
    }
}

# Function to stop the script
function Stop-Script {
    if (Test-Path $PID_FILE) {
        $jobId = Get-Content $PID_FILE
        if (Get-Job -Id $jobId -ErrorAction SilentlyContinue) {
            Write-Output "Stopping resource monitor (Job ID: $jobId)..."
            Stop-Job -Id $jobId
            Remove-Item $PID_FILE
            Write-Output "Stopped."
        } else {
            Write-Output "No running job found with Job ID: $jobId. Cleaning up PID file."
            Remove-Item $PID_FILE
        }
    } else {
        Write-Output "No PID file found. Is the script running?"
    }
}

# Function to start the script
function Start-Script {
    if (Test-Path $PID_FILE) {
        $jobId = Get-Content $PID_FILE
        if (Get-Job -Id $jobId -ErrorAction SilentlyContinue) {
            Write-Output "Resource monitor is already running (Job ID: $jobId)."
            return
        } else {
            Write-Output "Stale PID file found. Starting new process and cleaning up..."
            Remove-Item $PID_FILE
        }
    }

    # Start monitoring in the background
    Write-Output "Starting resource monitor..."
    Log-Message "Starting resource monitor..."
    
    $job = Start-Job -ScriptBlock {
        param ($cpuThreshold, $memThreshold, $diskThreshold, $fdThreshold, $logFile, $interval)

        function Log-Message {
            param ([string]$Message)
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "$timestamp - $Message" | Out-File -Append -FilePath $logFile
        }

        while ($true) {
            Log-Message "Starting resource check..."
            
            # CPU check
            $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue
            if ($cpuUsage -gt $cpuThreshold) {
                Log-Message "WARNING: CPU usage is above $cpuThreshold% - Current: $([math]::Round($cpuUsage, 2))%"
            }

            # Memory check
            $memory = Get-WmiObject -Class Win32_OperatingSystem
            $memUsage = (($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100
            if ($memUsage -gt $memThreshold) {
                Log-Message "WARNING: Memory usage is above $memThreshold% - Current: $([math]::Round($memUsage, 2))%"
            }

            # Disk check
            $diskUsage = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used / $_.Free * 100 -gt $diskThreshold }
            foreach ($drive in $diskUsage) {
                $usagePercent = ($drive.Used / ($drive.Used + $drive.Free)) * 100
                Log-Message "WARNING: Disk usage on $($drive.Name) is above $diskThreshold% - Current: $([math]::Round($usagePercent, 2))%"
            }

            # File descriptors check
            $fdCount = (Get-Process | Measure-Object -Property Handles -Sum).Sum
            if ($fdCount -gt $fdThreshold) {
                Log-Message "WARNING: Number of open file descriptors is above $fdThreshold - Current: $fdCount"
            }

            Log-Message "Resource check complete."
            Start-Sleep -Seconds $interval
        }
    } -ArgumentList $CPU_THRESHOLD, $MEM_THRESHOLD, $DISK_THRESHOLD, $FD_THRESHOLD, $LOG_FILE, $INTERVAL

    # Save the job ID instead of the process PID
    $job.Id | Out-File -FilePath $PID_FILE

    Write-Output "Resource monitor started (Job ID: $($job.Id))."
}

# Function to restart the script
function Restart-Script {
    Write-Output "Restarting resource monitor..."
    Stop-Script
    Start-Script
}

# Main control flow for start/stop/restart
if ($args.Count -eq 0) {
    Write-Output "Usage: .\Resource-Monitor.ps1 {start|stop|restart}"
    return
}

switch ($args[0]) {
    "start" { Start-Script }
    "stop" { Stop-Script }
    "restart" { Restart-Script }
    default {
        Write-Output "Usage: .\Resource-Monitor.ps1 {start|stop|restart}"
    }
}

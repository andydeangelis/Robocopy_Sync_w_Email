# Robocopy Sync with Email

A PowerShell script that uses `robocopy` to keep source and destination folders in sync, with support for email notifications, Windows Event Log integration, and automatic archive cleanup.

## Overview

`RobocopyEmailMain.ps1` is a comprehensive wrapper around the Windows `robocopy` utility that provides:

- **Robust file synchronization** using robocopy's MIR (mirror) mode
- **Detailed logging** with per-run directories capturing all file operations
- **Failed file tracking** with automatic extraction and event log reporting
- **ZIP compression** of logs for archival and email attachment
- **Email notifications** with sync status and results
- **Windows Event Log integration** for monitoring and alerting
- **Automatic archive cleanup** based on configurable retention policies
- **Dynamic event source naming** based on source/destination paths

## Features

### Synchronization
- Uses robocopy with `/MIR` (mirror) mode for bidirectional sync
- Configurable retry attempts for failed file copies
- Multi-threaded operation (defaults to system CPU count)
- Excludes system attributes and Recycle Bin directories

### Logging
- Creates timestamped log directories for each run
- Robocopy detailed log with per-file operation tracking
- PowerShell transcript logging for debugging
- Failed file extraction and event log reporting

### Event Log Integration
- Automatic Windows Event Log entries for successes and failures
- Configurable event source (auto-generated or custom)
- Failed file list captured in event log for ERROR states
- Information events for successful completions

### Archive Management
- Automatic ZIP compression of logs and reports
- Configurable retention period (default 30 days)
- Automatic cleanup of old ZIP files on each run
- Organized archive directory structure

### Email Notifications
- SMTP configuration with SSL/TLS support
- Anonymous or credential-based authentication
- Configurable TCP port
- ZIP archive attachment with results

## Prerequisites

- Windows operating system with PowerShell 3.0+
- `robocopy` installed (included with Windows)
- For email: SMTP server access with appropriate credentials
- For Event Log: Administrator privileges on first run (to create event source)
- Network access to source and destination paths

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `SourcePath` | String | Yes | | Source path for the robocopy job |
| `DestinationPath` | String | Yes | | Destination path for the robocopy job |
| `LogFilePath` | String | Yes | | Path where log files will be written |
| `smtpServer` | String | Conditional | | SMTP server hostname or IP (required if `-SendEmail`) |
| `smtpFrom` | String | Conditional | | Sender email address (required if `-SendEmail`) |
| `smtpTo` | String | Conditional | | Recipient email address (required if `-SendEmail`) |
| `NumRetries` | Int | No | 5 | Robocopy retry attempts for failed files |
| `NumThreads` | Int | No | CPU count | Number of parallel robocopy threads |
| `SendEmail` | Switch | No | $false | Send email notification with ZIP attachment |
| `smtpTCPPort` | Int | No | 25 | SMTP server TCP port |
| `UseSSL` | Switch | No | $false | Use SSL/TLS for SMTP connection |
| `AnonymousSMTP` | Switch | No | $false | Use anonymous SMTP authentication |
| `SMTPCredential` | PSCredential | No | | SMTP credential object (if not anonymous) |
| `EventSource` | String | No | Auto-generated | Windows Event Log source name |
| `KeepDays` | Int | No | 30 | Days to retain archive ZIP files |
| `Test` | Switch | No | $false | Testing mode (for debugging) |

## Usage Examples

### Basic Synchronization (Local)
```powershell
.\RobocopyEmailMain.ps1 `
  -SourcePath "C:\Data\Source" `
  -DestinationPath "D:\Backup\Destination" `
  -LogFilePath "C:\Logs\RobocopyLogs"
```

### Synchronization with Email Notification
```powershell
.\RobocopyEmailMain.ps1 `
  -SourcePath "C:\Data\Source" `
  -DestinationPath "\\server\share\backup" `
  -LogFilePath "C:\Logs\RobocopyLogs" `
  -SendEmail `
  -smtpServer "mail.company.com" `
  -smtpFrom "robocopy@company.com" `
  -smtpTo "admin@company.com" `
  -UseSSL
```

### With Custom Credentials and Archive Retention
```powershell
$cred = Get-Credential
.\RobocopyEmailMain.ps1 `
  -SourcePath "C:\Data\Source" `
  -DestinationPath "\\server\share\backup" `
  -LogFilePath "C:\Logs\RobocopyLogs" `
  -SendEmail `
  -smtpServer "mail.company.com" `
  -smtpFrom "robocopy@company.com" `
  -smtpTo "admin@company.com" `
  -SMTPCredential $cred `
  -UseSSL `
  -smtpTCPPort 587 `
  -KeepDays 60
```

### With Custom Event Source
```powershell
.\RobocopyEmailMain.ps1 `
  -SourcePath "C:\Data\Projects" `
  -DestinationPath "\\archive\projects" `
  -LogFilePath "C:\Logs\RobocopyLogs" `
  -EventSource "ProjectBackup-Daily"
```

## Exit Codes

The script maps robocopy exit codes to human-readable status messages:

| Code | Status | Description |
|------|--------|-------------|
| 0 | SUCCESS | No changes; all files already synchronized |
| 1 | SUCCESS | One or more files copied successfully |
| 2 | SUCCESS | Extra files detected; no failures |
| 3 | SUCCESS | Files copied; extra files detected |
| 4 | ERROR | Mismatched files detected |
| 5 | ERROR | Some files copied; mismatches occurred |
| 6 | ERROR | Additional and mismatched files exist |
| 7 | ERROR | Files copied; mismatch and extra files present |
| 8 | ERROR | Some files failed; retry limit exceeded |
| 16 | ERROR | Fatal error; no files copied |

## Log Output

Each run creates a timestamped directory structure:

```
LogFilePath/
  └── MM-dd-yyyy_hh.mm.ss/
      └── RobocopySyncLog_MM-dd-yyyy_hh.mm.ss.log
      
RobocopyCompressedReports/
  └── RobocopyResults_MM-dd-yyyy_hh.mm.ss.zip
```

## Windows Event Log

Events are logged to the **Application** event log:

- **Event ID 1001**: Robocopy job failed (includes failed file details)
- **Event ID 1002**: Robocopy job completed successfully

Event Source defaults to `RobocopyMain-[SourceFolder]-[DestFolder]` or can be customized with the `-EventSource` parameter.

## Scheduled Execution

To schedule regular synchronization, create a Windows Task Scheduler task:

```powershell
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -File C:\Scripts\RobocopyEmailMain.ps1 -SourcePath "C:\Data" -DestinationPath "\\server\backup" -LogFilePath "C:\Logs" -SendEmail -smtpServer mail.company.com -smtpFrom backup@company.com -smtpTo admin@company.com -UseSSL'
$trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM
Register-ScheduledTask -TaskName "Daily Robocopy Sync" -Action $action -Trigger $trigger -RunLevel Highest
```

## Troubleshooting

### Event Log Creation Fails
**Issue**: "Unable to write to Application event log"
- **Solution**: Run PowerShell as Administrator on first execution (requires privilege to create new event source)

### Zip Creation Error
**Issue**: "CreateFromDirectory... Could not find a part of the path"
- **Solution**: Ensure `LogFilePath` exists and is writable; the script creates `RobocopyCompressedReports` automatically

### Email Not Sending
**Issue**: SMTP timeout or authentication failure
- **Solution**: Verify SMTP settings, firewall rules, and credentials; test with `SendEmail` switch disabled first

### Robocopy Permission Denied
**Issue**: "Access is denied" in robocopy log
- **Solution**: Run the script with appropriate permissions to both source and destination; use Task Scheduler with higher privileges if needed

## Notes

- Created with: SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.150
- Created on: 8/21/2019
- Author: Andy DeAngelis
- Filename: RobocopyEmailMain.ps1

## License

This script is provided as-is for use in your organization.


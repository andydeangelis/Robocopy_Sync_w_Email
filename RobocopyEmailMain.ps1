<#
	.SYNOPSIS
		A brief description of the Invoke-RobocopyEmailMain_ps1 file.
	
	.DESCRIPTION
		A description of the file.
	
	.PARAMETER smtpServer
		String - $smtpServer Enter Your SMTP Server Hostname or IP Address
	
	.PARAMETER smtpFrom
		String - From Address, eg "IT Support <support@domain.com>"
	
	.PARAMETER smtpTo
		String - To address, eg "recipient@domain.com"
	
	.PARAMETER LogFilePath
		String - Specify the path where log files will be written.
	
	.PARAMETER Test
		Switch - Testing Enabled
	
	.PARAMETER SendEmail
		Switch - Tells the script whether or not to send email.
	
	.PARAMETER SourcePath
		String - Source path for the robocopy job.
	
	.PARAMETER DestinationPath
		String - Destination path for the robocopy job.
	
	.PARAMETER NumRetries
		Int - How many retries should robocopy do on a failed file copy.
	
	.PARAMETER NumThreads
		Int - number of simultaneous robocopy threads. Defaults to number of logical cores in the system running the script.
	
	.PARAMETER SMTPCredential
		PSCredential Object - Use Get-Credential to specify credential object for the SMTP server.
	
	.PARAMETER UseSSL
		Switch - Specifies whether or not to use SSL to communicate with the SMTP server.
	
	.PARAMETER AnonymousSMTP
		Switch - Specifies whether or not to use anonymous SMTP. If specified, the SMTPCredential is ignored.
	
	.PARAMETER smtpTCPPort
		Int - The TCP port to use when connecting to the SMTP server. Defaults to TCP port 25.
	
	.PARAMETER LogFile
		String - The path to store the log files from the robocopy job.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.150
		Created on:   	8/21/2019 1:58 PM
		Created by:   	Andy DeAngelis
		Organization:
		Filename:     	RobocopyEmailMain.ps1
		===========================================================================
#>
param
(
	[ValidateNotNull()]
	[string]$smtpServer,
	[ValidateNotNull()]
	[string]$smtpFrom,
	[string]$smtpTo,
	[Parameter(Mandatory = $true)]
	[string]$LogFilePath,
	[switch]$Test,
	[Parameter(Mandatory = $false)]
	[switch]$SendEmail,
	[Parameter(Mandatory = $true)]
	[string]$SourcePath,
	[Parameter(Mandatory = $true)]
	[string]$DestinationPath,
	[int]$NumRetries,
	[int]$NumThreads,
	[PScredential]$SMTPCredential,
	[switch]$UseSSL,
	[switch]$AnonymousSMTP,
	[Parameter(Mandatory = $false)]
	[int]$smtpTCPPort = 25
)

$datetime = get-date -f MM-dd-yyyy_hh.mm.ss
$logFileFullPath = "$LogFilePath\RobocopySyncLog_$datetime.log"
$textEncoding = [System.Text.Encoding]::UTF8

if (-not (Get-Item $LogFilePath -ErrorAction SilentlyContinue))
{
	New-Item $LogFilePath -ItemType Directory
}

if (-not $NumRetries) { $NumRetries = 5 }

# Determine the number of threads that Robocopy will use based on the number of logical CPUs in the system.

if (-not $NumThreads)
{
	$processors = get-wmiobject -computername localhost Win32_ComputerSystem
	$NumThreads = 0
	try
	{
		$NumThreads = @($processors).NumberOfLogicalProcessors
	}
	catch
	{
		$NumThreads = @($processors).NumberOfProcessors
	}
}

# Change robocopy options as needed. ( http://ss64.com/nt/robocopy.html )
robocopy $SourcePath $DestinationPath /MIR /FFT /R:$NumRetries /MT:$NumThreads /LOG:$logFileFullPath  /XA:S /XD *RECYCLE.BIN*

# DO NOT INSERT ANY CODE BETWEEN THE RBOCOPY COMMAND AND THE SWITCH DEFINITION.

Switch ($LASTEXITCODE)
{
	16
	{
		$exit_code = "16"
		$exit_reason = "[***FATAL ERROR***] Robocopy did not copy any files.  Check the command line parameters and verify that Robocopy has enough rights to write to the destination folder"
		$backupState = "ERROR"
	}
	15
	{
		$exit_code = "15"
		$exit_reason = "[FAILED] OKCOPY + FAIL MISMATCH EXTRA COPY"
		$backupState = "ERROR"
	}
	14
	{
		$exit_code = "14"
		$exit_reason = "[FAILED] FAIL MISMATCH EXTRA"
		$backupState = "ERROR"
	}
	13
	{
		$exit_code = "13"
		$exit_reason = "[FAILED] OKCOPY + FAIL MISMATCH COPY"
		$backupState = "ERROR"
	}
	12
	{
		$exit_code = "12"
		$exit_reason = "[FAILED] FAIL MISMATCH"
		$backupState = "ERROR"
	}
	11
	{
		$exit_code = "11"
		$exit_reason = "[FAILED] OKCOPY + FAIL EXTRA COPY"
		$backupState = "ERROR"
	}
	10
	{
		$exit_code = "10"
		$exit_reason = "[FAILED] FAIL EXTRA"
		$backupState = "ERROR"
	}
	9
	{
		$exit_code = "9"
		$exit_reason = "[FAILED] FAIL COPY"
		$backupState = "ERROR"
	}
	8
	{
		$exit_code = "8"
		$exit_reason = "[FAILED COPIES] Some files or directories could not be copied and the retry limit was exceeded"
		$backupState = "ERROR"
	}
	7
	{
		$exit_code = "7"
		$exit_reason = "Files were copied, a file mismatch was present, and additional files were present."
		$backupState = "ERROR"
	}
	6
	{
		$exit_code = "6"
		$exit_reason = "Additional files and mismatched files exist. No files were copied and no failures were encountered. This means that the files already exist in the destination directory."
		$IncludeAdmin = $False
		$backupState = "ERROR"
	}
	5
	{
		$exit_code = "5"
		$exit_reason = "Some files were copied. Some files were mismatched. No failure was encountered."
		$IncludeAdmin = $False
		$backupState = "ERROR"
	}
	4
	{
		$exit_code = "4"
		$exit_reason = "MISMATCHED files or directories were detected.  Examine the log file for more information"
		$IncludeAdmin = $False
		$backupState = "ERROR"
	}
	3
	{
		$exit_code = "3"
		$exit_reason = "Some files were copied. Additional files were present. No failure was encountered."
		$IncludeAdmin = $False
		$backupState = "SUCCESSFULL"
	}
	2
	{
		$exit_code = "2"
		$exit_reason = "EXTRA FILES or directories were detected.  Examine the log file for more information"
		$IncludeAdmin = $False
		$backupState = "SUCCESSFULL"
	}
	1
	{
		$exit_code = "1"
		$exit_reason = "One of more files were copied SUCCESSFULLY"
		$IncludeAdmin = $False
		$backupState = "SUCCESSFULL"
	}
	0
	{
		$exit_code = "0"
		$exit_reason = "NO CHANGE occurred and no files were copied"
		$backupState = "SUCCESSFULL"
		$SendEmail = $False
		$IncludeAdmin = $False
	}
	default
	{
		$exit_code = "Unknown ($LASTEXITCODE)"
		$exit_reason = "Unknown Reason"
		$IncludeAdmin = $False
	}
}

$EmailSubject = "Robocopy Status: " + "[" + $backupState + "]; " + $exit_reason + ";EC: " + $exit_code
$EmailBody = "Robocopy status attached."

if (Get-Item "$LogFilePath\RobocopyCompressedReports" -ErrorAction SilentlyContinue)
{
	#Compress-Archive -LiteralPath $logFileFullPath -CompressionLevel Optimal -DestinationPath "$LogFilePath\RobocopyCompressedReports\RobocopyResults_$datetime.zip"
	
	.\7za.exe a -tzip "$PSScriptRoot\Reports\RobocopyCompressedReports\RobocopyResults_$datetime.zip" $logFileFullPath
}
else
{
	New-Item -Path $LogFilePath -Name "RobocopyCompressedReports" -ItemType Directory
	#Compress-Archive -LiteralPath $logFileFullPath -CompressionLevel Optimal -DestinationPath "$LogFilePath\RobocopyCompressedReports\RobocopyResults_$datetime.zip"
	
	.\7za.exe a -tzip "$PSScriptRoot\Reports\RobocopyCompressedReports\RobocopyResults_$datetime.zip" $logFileFullPath
}

# Now, send an email if specified.

if ($SendEmail)
{
	if ($AnonymousSMTP)
	{
		if ($UseSSL)
		{
			try
			{
				Send-Mailmessage -smtpServer $smtpServer -Port $smtpTCPPort -from $smtpFrom -to $smtpTo -subject $EmailSubject -body $EmailBody -bodyasHTML -priority High -Encoding $textEncoding -Attachments "$LogFilePath\RobocopyCompressedReports\RobocopyResults_$datetime.zip" -UseSsl -ErrorAction Stop
			}
			catch
			{
				$errorMessage = $_.Exception.Message
				Write-Output $errorMessage
			}
		}
		else
		{
			try
			{
				Send-Mailmessage -smtpServer $smtpServer -Port $smtpTCPPort -from $smtpFrom -to $smtpTo -subject $EmailSubject -body $EmailBody -bodyasHTML -priority High -Encoding $textEncoding -Attachments "$LogFilePath\RobocopyCompressedReports\RobocopyResults_$datetime.zip" -ErrorAction Stop
			}
			catch
			{
				$errorMessage = $_.Exception.Message
				Write-Output $errorMessage
			}
		}
	}
	else
	{
		if ($UseSSL)
		{
			try
			{
				Send-Mailmessage -smtpServer $smtpServer -Port $smtpTCPPort -from $smtpFrom -to $smtpTo -subject $EmailSubject -body $EmailBody -bodyasHTML -priority High -Encoding $textEncoding -Attachments "$LogFilePath\RobocopyCompressedReports\RobocopyResults_$datetime.zip" -UseSsl -Credential $SMTPCredential -ErrorAction Stop
			}
			catch
			{
				$errorMessage = $_.Exception.Message
				Write-Output $errorMessage
			}
		}
		else
		{
			{
				try
				{
					Send-Mailmessage -smtpServer $smtpServer -Port $smtpTCPPort -from $smtpFrom -to $smtpTo -subject $EmailSubject -body $EmailBody -bodyasHTML -priority High -Encoding $textEncoding -Attachments "$LogFilePath\RobocopyCompressedReports\RobocopyResults_$datetime.zip" -Credential $SMTPCredential -ErrorAction Stop
				}
				catch
				{
					$errorMessage = $_.Exception.Message
					Write-Output $errorMessage
				}
			}
		}
	}
}

Remove-Item $logFileFullPath -Force -Confirm:$false
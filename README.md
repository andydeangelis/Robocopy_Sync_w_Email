# Robocopy_Sync_w_Email

	.SYNOPSIS
		Script that will use robocopy to keep a source and destination folder in sync and email results base via SMTP.
	
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
 

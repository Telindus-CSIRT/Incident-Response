
$exchangePath = (Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ExchangeServer\v15\Setup).MsiInstallPath


function Check-CmdletInfra_LocalQueue-Logs(){

	Write-Output "`n*** Checking Webshell in Cmdlet log files ***"

	$logs =Get-ChildItem -Recurse -Path "$exchangePath\Logging\CmdletInfra\Others\*.log" | Select-String "Set-.*VirtualDirectory" -List | Select-Object Path

	if ($logs.Path.Count -gt 0) {
        Write-Output "Webshell found"
        $logs.Path
    } else {
        Write-Output "No Webshell found."
    }
	
	foreach ( $log in $logs.Path )
	{
		Write-Output "Webshell found in $log"
		Get-Content $log | Where-Object {$_ -match ".*JScript.*"} | ForEach-Object {
			"Timestamp : "+$_.split(",")[0] `
			+"`n"+"PID : "+$_.split(",")[9] `
			+"`n"+"User : "+$_.split(",")[14] `
			+"`n"+"Service : "+$_.split(",")[19] `
			+"`n"+"Function : "+$_.split(",")[20] `
			+"`n"+"Payload : "+$_.split(",")[21]+"`n"
		}
	}

	Write-Output "`n*** Checking LocalPowerShell Cmdlet log files ***"

	$cmdlist = "Get-Mailbox","New-MailboxExportRequest","Get-MailboxExportRequest","Remove-MailboxExportRequest"

	Get-ChildItem -Recurse $exchangePath\Logging\CmdletInfra\LocalPowerShell\Cmdlet\*_Cmdlet_*.log | Select-String -Pattern $cmdlist | 
	Select-Object Path, Pattern, @{name='StartTime';expression={$_.Line.split(",")[1]}},`
	@{name='RequestId';expression={$_.Line.split(",")[2]}},`
	@{name='ProcessId';expression={$_.Line.split(",")[9]}},`
	@{name='ProcessName';expression={$_.Line.split(",")[10]}},`
	@{name='AuthenticatedUser';expression={$_.Line.split(",")[14]}},`
	@{name='Cmdlet';expression={$_.Line.split(",")[20]}},`
	@{name='Parameters';expression={$_.Line.split(",")[21]}},`
	@{name='ExecutionResult';expression={$_.Line.split(",")[57]}} | Format-List
	
	Write-Output "`n*** Checking LocalQueue log files ***"

	Get-ChildItem -Recurse $exchangePath\Logging\LocalQueue\Exchange\audit*.log | Select-String -Pattern $cmdlist | 
	Select-Object Path, Pattern, @{name='Timestamp';expression={$_.Line.split(",")[0]}},` 
	@{name='ProcessId';expression={$_.Line.split(",")[1]}},`
	@{name='ProcessName';expression={$_.Line.split(",")[2]}},` 
	@{name='Data';expression={($_.Line.split("{.*}"))}} | Format-List
	

}


Check-CmdletInfra_LocalQueue-Logs
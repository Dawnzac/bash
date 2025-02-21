# Function to check if running as Administrator
function Test-Admin {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $princ = New-Object Security.Principal.WindowsPrincipal $user
    return $princ.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Logging function
function Write-Log {
    param ([string]$Message)
    $LogFile = "C:\ProgramData\SetFixedIP.log"
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -Append -FilePath $LogFile -Encoding utf8
}

# Relaunch as Administrator if not already
if (-not (Test-Admin)) {
    Write-Log "Restarting with administrator privileges..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Log "Script started"

# Define network settings
$IPPrefix = "172.25.1"
$LastOctet = Read-Host "Enter the last octet for the static IP ( $IPPrefix. )"

if ($LastOctet -match "^\d{1,3}$" -and [int]$LastOctet -ge 1 -and [int]$LastOctet -le 254) {
    $DesiredIP = "$IPPrefix.$LastOctet"
    Write-Log "User entered valid last octet: $LastOctet. Desired IP: $DesiredIP"
}
else {
    Write-Log "Invalid last octet entered: $LastOctet. Exiting."
    Write-Host "Invalid input! Please enter a number between 1 and 254."
    pause
    exit
}

$Gateway = "172.25.1.1"
$DNS1 = "8.8.8.8"
$DNS2 = "8.8.4.4"

# Get active network adapter
$Adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

if ($Adapter) {
    $CurrentIP = (Get-NetIPAddress -InterfaceAlias $Adapter.Name -AddressFamily IPv4).IPAddress
    Write-Log "Active adapter: $($Adapter.Name), Current IP: $CurrentIP"

    if ($CurrentIP -ne $DesiredIP) {
        Write-Log "IP mismatch detected. Changing from $CurrentIP to $DesiredIP."

        # Remove existing IP
        Get-NetIPAddress -InterfaceAlias $Adapter.Name -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
        
        # Set static IP
        New-NetIPAddress -InterfaceAlias $Adapter.Name -IPAddress $DesiredIP -PrefixLength 24 -DefaultGateway $Gateway -Confirm:$false
        
        # Set DNS Servers
        Set-DnsClientServerAddress -InterfaceAlias $Adapter.Name -ServerAddresses ($DNS1, $DNS2)

        Write-Log "Successfully changed IP to $DesiredIP."
    }
    else {
        Write-Log "IP is already correct: $DesiredIP"
    }
}
else {
    Write-Log "No active network adapter found. Exiting."
    Write-Host "No active network adapter found."
    exit
}

# Scheduled Task Name
$TaskName = "SetFixedIP"
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($ExistingTask) {
    Write-Log "Scheduled task '$TaskName' already exists."
}
else {
    Write-Log "Creating scheduled task '$TaskName' to run at startup."

    # Inline PowerShell script that will run at startup
    $EmbeddedScript = @"
`$LogFile = 'C:\ProgramData\SetFixedIP.log'
function Write-Log {
    param ([string]`$Message)
    `$Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    `"$Timestamp - `$Message`" | Out-File -Append -FilePath `$LogFile -Encoding utf8
}
Write-Log 'Scheduled Task Execution Started'

`$DesiredIP = '$DesiredIP'
`$SubnetMask = '255.255.255.0'
`$Gateway = '172.25.1.1'
`$DNS1 = '8.8.8.8'
`$DNS2 = '8.8.4.4'

`$Adapter = Get-NetAdapter | Where-Object { `$_."Status" -eq "Up" }
if (`$Adapter) {
    `$CurrentIP = (Get-NetIPAddress -InterfaceAlias `$Adapter.Name -AddressFamily IPv4).IPAddress
    Write-Log 'Adapter found: ' + `$Adapter.Name + ', Current IP: ' + `$CurrentIP
    if (`$CurrentIP -ne `$DesiredIP) {
        Write-Log 'Updating IP from ' + `$CurrentIP + ' to ' + `$DesiredIP
        Get-NetIPAddress -InterfaceAlias `$Adapter.Name -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:`$false -ErrorAction SilentlyContinue
        New-NetIPAddress -InterfaceAlias `$Adapter.Name -IPAddress `$DesiredIP -PrefixLength 24 -DefaultGateway `$Gateway -Confirm:`$false
        Set-DnsClientServerAddress -InterfaceAlias `$Adapter.Name -ServerAddresses (`$DNS1, `$DNS2)
        Write-Log 'IP successfully updated to ' + `$DesiredIP
    } else {
        Write-Log 'IP is already correct: ' + `$DesiredIP
    }
} else {
    Write-Log 'No active adapter found at startup'
}
Write-Log 'Scheduled Task Execution Completed'
"@

    # Convert script to Base64 for secure execution
    $EncodedScript = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($EmbeddedScript))

    # Create new scheduled task with embedded script
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $EncodedScript"
    $Trigger = New-ScheduledTaskTrigger -AtStartup
    $Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -Settings $TaskSettings

    Register-ScheduledTask -TaskName $TaskName -InputObject $Task | Out-Null

    Write-Log "Scheduled task '$TaskName' created successfully."
}
Start-Sleep -Seconds 3
Remove-Item -Path $PSCommandPath -Force

Write-Log "Script execution completed."
Write-Host "Press Enter to exit..."
Read-Host | Out-Null

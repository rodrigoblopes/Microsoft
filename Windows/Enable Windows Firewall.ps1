# Enable Windows Firewall
Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled True

# Enable logging for dropped packets in the domain profile
Set-NetFirewallProfile -Profile Domain -LogFileName "%systemroot%\system32\LogFiles\Firewall\pfirewall-domain.log" -LogBlocked True

# Enable logging for dropped packets in the public profile
Set-NetFirewallProfile -Profile Private -LogFileName "%systemroot%\system32\LogFiles\Firewall\pfirewall-private.log" -LogBlocked True

# Enable logging for dropped packets in the private profile
Set-NetFirewallProfile -Profile Public -LogFileName "%systemroot%\system32\LogFiles\Firewall\pfirewall-public.log" -LogBlocked True

# Display confirmation messages
Write-Host "Windows Firewall has been enabled in the domain, public, and private profiles."
Write-Host "Logging for dropped packets has been enabled in the specified paths."

# Restart the Network Location Awareness service:
Restart-Service -Name NlaSvc -Force

# Check if the machine is a domain controller
$productType = (Get-CimInstance -ClassName Win32_OperatingSystem).ProductType
if ($productType -eq 2) {
    Write-Output "This machine is a domain controller. Creating rule for mDNS"
    New-NetFirewallRule -DisplayName "Allow mDNS" -Direction Inbound -Protocol UDP -LocalPort 5353 -Action Allow
} else {
    Write-Output "This machine is not a domain controller."
}

# Check if the machine is a SQL Server.
$services = Get-WmiObject -class Win32_SystemServices
$isSqlServer = $false
foreach ($service in $services.partcomponent) {
    if ($service -match 'MSSQLSERVER') {
        Write-Output "This machine is a SQL Server."
        $isSqlServer = $true
        break
    }
}
if (-not $isSqlServer) {
    Write-Output "This machine is not a SQL Server."
    return
}

# If the machine is a SQL Server, check if the rules for SQL Server are already created.
$rule = Get-NetFirewallRule -DisplayName 'SQL Server' -ErrorAction SilentlyContinue
if ($rule) {
    Write-Output "The rules for SQL Server are already created."
    return
}

# If the rules are not created, create the rules to allow inbound connections to the SQL Server.
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol UDP -LocalPort 1434 -Action Allow
Write-Output "The rules to allow inbound connections to the SQL Server have been created."
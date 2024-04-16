<#
.SYNOPSIS
The script helps collecting log files, configuration files, Windows Event Logs of YSoft SafeQ.
.DESCRIPTION
The script identifies YSoft SafeQ installation and collects all possible log files and configuration.
The script collects information from Windows Event Viewer.
The script collects information from Windows System Information
The script collects data for defined period of time (see $LogAge parameter). E.g. if the issue happened 3 hours
ago, you would collect data from the last 4-5 hours to ensure that all data for analysis are available.
The script collects only data from the server where the command was triggered for the past X hours (see
$LogAge parameter). In case other servers may be involved (Management Server, CBPR Client, Authentication
against SPOC group, etc.) data from all affected servers has to be provided.
- for instance an authentication issue on an MFD managed by a SPOC group hidden behind a virtual IP address
of load balancer occurs; log files from all servers in the SPOC group as well as from the Management servers has
to be provided.
- log files must cover the date and time of the occurrence.
PowerShell 3.0 or higher is required, current version can be listed by command: $PSVersionTable.PSVersion.Maj
or
The script must be launched using PowerShell as an Administrator.
Additional data such as "Support information" (YSoft SafeQ management interface > Dashboard > Click "Support
information" > Click "Download support information"), screenshots and other relevant information must be
collected manually and provided along with the log files.
.PARAMETER LogAge
Defines the period for how how many hours the log files will be collected from now to the past (default
configuration is past 24 hours).
.PARAMETER RootCollectionPath
Defines the folder where on the server would you like to store the data (by default a new folder will be created
on the desktop).
.PARAMETER GetLog
Determine if logs are collected ($true / $false).
.PARAMETER GetConf
Determine if the configuration files are collected ($true / $false).
.PARAMETER GetCert
Determine if certificates and private keys are collected ($true / $false).
.PARAMETER GetMisc
Determine if Windows Event Logs, System Information, list of Windows services, list of Memory Dumps are
collected ($true / $false).
.NOTES
Version: 1.37
Last Modified: 09/Jun/2023
.EXAMPLE
Define required values in $LogAge and $RootCollectionPath parameter.
Run Windows PowerShell as an administrator and launch the command as follows:
C:\Users\Administrator\Downloads> .\SQ_Collect_Logs.ps1
#>
#-----------------------------------------------------------[Parameters]-----------------------------------------------------------
# Set the log age to gather in hours (Default: $LogAge = 24)
$LogAge = 24
# Log collection folder (Default: $RootCollectionPath = "$($env:USERPROFILE)\Desktop")
# Example : $RootCollectionPath = "C:\Temp"
$RootCollectionPath = "$($env:USERPROFILE)\Desktop"
# Get logs ($true / $false)
$GetLog = $true
# Get configuration files ($true / $false)
$GetConf = $true
# Get certificates and private keys ($true / $false)
$GetCert = $true
# Get Windows Event Logs, System Information, Memory Dumps ($true / $false)
$GetMisc = $true
#-----------------------------------------------------------[Execution]------------------------------------------------------------
# Input value check
If (($GetConf -eq $false) -and ($GetLog -eq $false) -and ($GetMisc -eq $false) -and ($GetCert -eq $false)) {
Write-Warning 'Nothing to collect. Please review the configuration and re-run the script.'
'Press any key to exit the script.' | Out-Host
Read-Host
exit
}
# Admin rights check
If (-NOT ([Security.Principal.WindowsPrincipal]
[Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(([System.Security.Principal.SecurityIdentifier]
'S-1-5-32-544'))) {
Write-Warning 'Administrative rights are missing. Please re-run the script as an Administrator.'
'Press any key to exit the script.' | Out-Host
Read-Host
exit
}
# Create function for data copying
function copydata($FileToCopy) {
ForEach ($tmp in $FileToCopy) {
$DirectoryName = $tmp.DirectoryName -replace ("\w:\\","")
$Destination = "$DataDest\$DirectoryName"
If (!(Test-Path $Destination)) {
New-Item -Path $Destination -ItemType Directory | Out-Null
}
Copy-Item $tmp.FullName -Destination $Destination
}
}
# Create functions for data extraction
function Expand-ZIP($file, $destination) {
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($file, $destination)
}
# Create functions for data archivation
# Using .NET function is better than native Compress-Archive (PS5), native Compress-Archive may consume all
the OS memory
function Compress-ZIP($directory, $destination) {
Try {
Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
} Catch {
"File compression failed, kindly pack the files manually and provide them to CSS." | Out-Host
"Files are available at: $DataDest" | Out-Host
"" | Out-Host
'Press any key to exit the script.' | Out-Host
Read-Host
exit
} Finally {
[System.AppContext]::SetSwitch('Switch.System.IO.Compression.ZipFile.UseBackslash', $false)
[System.IO.Compression.ZipFile]::CreateFromDirectory($directory, $destination, "optimal", $true)
}
}
# Prepare the log collection folder
$IPaddress = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object {$_.DefaultIPGateway
-ne $null}).IPAddress | Select-Object -First 1
$FolderName = "$($env:COMPUTERNAME)_$($IPaddress)"
$DataDest = "$($RootCollectionPath)\$($FolderName)"
'Locating the installation directories'
# Identify all YSoft SafeQ services based on the service name or description
$ServiceList = @()
$ServiceList += Get-ChildItem -Path HKLM:\SYSTEM\CurrentControlSet\Services | Get-ItemProperty | `
? {($_.PSChildName -match 'YSoft.*|YSQ.*' -or $_.DisplayName -match 'YSoft.*|YSQ.*')} | `
? {$_.PSPath -notmatch 'YSoftEtcd|YSoftSQ-LDAP|YSoftSafeQLDAPReplicator|YSoftSafeQCMLDBS|YSoftWeb|
YSoftPGSQL|YSoftIms'}
ForEach ($Service in $ServiceList) {
$tmp = ($Service.ImagePath -replace '(?<=\.exe).+', '').Trim('`"')
$tmp = $tmp.Substring(0,$tmp.LastIndexOf('\')) -Replace ('\\?bin\\?','') -Replace ('\\?tomcat\\?','') -Replace ('\
\Service\\?','') -Replace ('PGSQL','PGSQL-data') -replace ('\\procrun','')
$Service | Add-Member -MemberType NoteProperty -Name Path -Value $tmp
}
# Add location for customizations
# Look for customizations in the root dir of detected service (e.g. for C:\SafeQ6\Management check dirs in C:
\SafeQ6; too generic paths like C:\ or C:\ProgramData are skipped)
# The customizations that were already detected based on the service name are not added again
$findcustom = $ServiceList | ? {$_.PSChildName -in "YSoftSQ-Management",'YSoftSQ-SPOC','YSoftSQ-WPS'}
if ($findcustom) {
$pathtoignore = ($Env:ALLUSERSPROFILE, $Env:ProgramData, $Env:ProgramFiles, $Env:ProgramW6432, $Env:
windir)
$findcustom = $findcustom.Path -replace '\\\w+$',''
$findcustom = $findcustom | ? { $_ -notin $pathtoignore -and $_ -notmatch '^\w:(|\\)$' }
if ( $findcustom ) { Get-ChildItem -Path $findcustom -Directory | ? { $_.FullName -notin $ServiceList.Path } |
ForEach { $ServiceList += New-Object -TypeName PSObject -Property @{Path = $_.FullName} }}
}
# Temporary workaround for YSoftSQ-SPOOLER v3 client deployed by old MSI package (key path in registry is
just <drive>:, packages from QuickPrint no longer afffected)
# this detects the problematic client and updates its ImagePath inside of source variable $ServiceList
$v3clientmsi = $ServiceList | ? {$_.DisplayName -eq "YSoft SafeQ Spooler"}
if ($v3clientmsi -and $v3clientmsi.Path -match "\w:$") {
$v3clientmsi.Path = $v3clientmsi.ImagePath -replace '\\\d+\.\d+\.\d+\.\d+\\..\\latest\
\YSoft\.Spooler\.Host\.exe"\s--run-as-service','\latest' -replace '"',''
}
# Exclude services where path does not exist on the filesystem
$FinServiceList = @()
ForEach ($Service in $ServiceList){
If (Test-Path $Service.Path) { $FinServiceList += $Service }
}
# General list of directories to exclude from all searches to speed up processing
$DirExclude = '\\.*backup.*|\\PGSQL\\|PGSQL-data\\(base|pg_wal)|\\spoolcache|\\cache|\\missioncontrol|java\\(demo|
sample|lib|legal)\\|web-inf\\(views|classes|libs)|\\assets\\|\\catalina\\localhost|FSP\\universal-pcl-driver|Client\
\resources\\app|\\AccountedJobs|\\ims\\\.vertx'
if ($GetConf -eq $true) {
'Copying the configuration files' | Out-Host
# Obtaining all the configuration files
$FileExtension = '.conf','.config','.properties','.xml','.json','.drl','.ini'
$FileExclude = '\.dll\.config'
$DirExcludeConf = $DirExclude + '|\\terminalserver|MobilePrint\\Service'
$ConfToCopy = @()
ForEach ($Service in $FinServiceList) {
if ($Service.PSChildName -match 'YSoftSQ-UP-CONNECTOR') {
$target = $([Environment]::SystemDirectory) + '\config\systemprofile\.universal-print'
if ([Environment]::Is64BitProcess){
$ConfToCopy += Get-ChildItem -Path $target -File -Recurse -Include 'desiredState.json'
} else {
	Write-Warning "$($target+'\desiredState.json') cannot be collected."
'Either collect it manually and attach it to the output or re-launch the script in x64 version of
PowerShell.' | Out-Host
'Press any key to continue.' | Out-Host
Read-Host
}
Remove-Variable target
}
if ($Service.PSChildName -match 'YSoftSQ-TS*'){
$ConfToCopy += Get-ChildItem -Path $Service.Path -File -Recurse -Include 'TerminalServer.exe.config'
} elseif ($Service.PSChildName -match 'YSoftSQ-MPS|YSoftMobilePrintServer') {
$ConfToCopy += Get-ChildItem -Path $Service.Path -File -Recurse -Include '*.config'
} else {
$LookupDir = @()
$LookupDir += Get-ChildItem -Path $Service.Path -Directory -Recurse | ? { $_.FullName -notmatch
$DirExcludeConf }
$LookupDir += Get-Item $Service.Path
$ConfToCopy += $LookupDir | Get-ChildItem -File | ? {$_.Extension -in $FileExtension -and $_.FullName
-notmatch $FileExclude }
}
}
$ConfToCopy = $ConfToCopy | Sort FullName -Unique
copydata $ConfToCopy
}
if ($GetCert -eq $true) {
'Copying the certificates and private keys' | Out-Host
# Obtaining all the certificate and private key files based on the predefined list
$CertList = '\.(cer$|crt$|key$|pfx$|jks$|p12$|pem$)|\\.*keystore|\\.*truststore'
$CertToCopy = @()
ForEach ($Service in $FinServiceList) {
$LookupDir = @()
$LookupDir += Get-ChildItem -Path $Service.Path -Directory -Recurse | ? { $_.FullName -notmatch
$DirExclude }
$LookupDir += Get-Item $Service.Path
$CertToCopy += $LookupDir | Get-ChildItem -File | ? { $_.FullName -match $CertList }
}
$CertToCopy = $CertToCopy | Sort FullName -Unique
copydata $CertToCopy
}
if ($GetLog -eq $true) {
'Copying the log files' | Out-Host
# Obtaining all the files modified in the defined period plus the two last files of each filename pattern
$LogToCopy = @()
ForEach ($Service in $FinServiceList) {
$LogList = @()
$LookupDir = @()
$LookupDir += Get-ChildItem -Path $Service.Path -Directory -Recurse | ? { $_.FullName -notmatch
$DirExclude }
$LookupDir += Get-Item $Service.Path
$LogList += $LookupDir | Get-ChildItem -File | ? { (($_.Length -gt 0) -and ($_.extension -eq ".log")) -or
($_.DirectoryName -match "\\(pg_log|log|logs)$") }
# Additional location for global install log
$LogList += (Get-Item $Service.Path).parent.FullName | Get-ChildItem -File | ? {$_.extension -eq ".log"}
# Additional location for YSoftSQ-SPOOLER install.log and YSoft SAFEQ Client v3 log
if ($Service.PSChildName -eq 'YSoftSQ-SPOOLER') {
$LogList += Get-ChildItem -Path $(($env:USERPROFILE -replace "[^\\]*(?:)?$") +
'*\AppData\Roaming\YSoft SafeQ Client\logs') -Recurse
if ($Service.Path -match 'versions\\latest') {
$LogList += Get-ChildItem -Path $($Service.Path -replace 'versions\\latest','logs') -File -ErrorAction
Ignore #this is for very old v3 client
} else {
$LogList += Get-ChildItem -Path $($Service.Path + '\logs') -File -ErrorAction Ignore
}
}
# Additional location for YSoft SAFEQ client (non-v3, Desktop Interface)
if ($Service.PSChildName -eq 'YSoftSQ-FSP'){
$LogList += Get-ChildItem -Path $(($env:USERPROFILE -replace "[^\\]*(?:)?$") + '*\.safeq6\logs\')
-Recurse
}
# Code to pick the last two logs for each name pattern
$Patterns = @()
ForEach ($Log in $LogList) {
If ($Log.BaseName -match "postgresql") {
$Patterns += ($Log.BaseName -Split ('\-'))[0]
} Elseif ($Log.BaseName -match "jobservice") {
$Patterns += 'jobservice' # workaround SBT-3255
} Elseif ($Log.BaseName -match "\.") {
$Patterns += ($Log.BaseName -Split ('\.'))[0]
} Else {
$Patterns += $Log.BaseName
}
}
$Patterns = $Patterns | Select-Object -Unique
$LastLogs = @()
ForEach ($Pattern in $Patterns) {
$LastLogs += $LogList | ? {$_.BaseName -match "$Pattern"} | Sort-Object LastWriteTime -Descending |
Select-Object -First 2
}
$LogToCopy += $LogList | ? {$_.LastWriteTime -gt (Get-Date).AddHours(-$LogAge) -or $_ -in $LastLogs}
}
$LogToCopy = $LogToCopy | Sort FullName -Unique
copydata $LogToCopy
'Extracting archived logs' | Out-Host
$ZipFiles = Get-ChildItem -Path $DataDest -Recurse | Where-Object {$_.Name -match '.zip'}
If ($ZipFiles) {
$progresstrack = 0
$command = [scriptblock]::Create('Expand-ZIP -File $($ZipFile.FullName) -Destination $
($ZipFile.Directory.FullName)')
ForEach ($ZipFile in $ZipFiles) {
Try {
Write-Progress -Activity "Extracting archived logs" -CurrentOperation "" -PercentComplete ($progress
track/$zipfiles.Count*100)
$progresstrack = $progresstrack + 1
& $command
Remove-Item -Path $ZipFile.FullName
} Catch {<#"File extraction failed, keeping an archive: $ZipFile"#>}
}
Write-Progress -Activity "Extracting archived logs" -Status "Ready" -Complete
}
}
if ($GetMisc -eq $true) {
If (!(Test-Path $DataDest)) {New-Item -Path $DataDest -ItemType Directory | Out-Null}
'Getting the Windows Event Logs' | Out-Host
Get-EventLog Application -After (Get-Date).AddHours(-$LogAge) | Format-Table -Property TimeWritten, Source,
EventID, EntryType, Message -wrap -auto | Out-File $DataDest\EventLog_Application.txt -Width 250 -Encoding
utf8
Get-EventLog System -After (Get-Date).AddHours(-$LogAge) | Format-Table -Property TimeWritten, Source,
EventID, EntryType, Message -wrap -auto | Out-File $DataDest\EventLog_System.txt -Width 250 -Encoding utf8
'Getting the System Info' | Out-Host
$sysinfo = @()
If ([System.Version]$PSVersionTable.PSVersion -ge [System.Version]"5.1") {
$sysinfo += 'Accurate CPU information obtained by PowerShell 5.1 or higher:'
$sysinfo += (Get-ComputerInfo -Property CsNumberOfLogicalProcessors, CsNumberOfProcessors,
CsProcessors | Format-List | Out-String).Trim()
$sysinfo += ''
}
$sysinfo += 'Generic system information:'
$sysinfo += 'WARNING: The number of CPU cores listed below is incorrect, because command "sysinfo"
provides inaccurate data.'
$sysinfo += systeminfo
$sysinfo | Out-File $DataDest\SystemInfo.txt -Encoding utf8
'Getting details about services' | Out-Host
$OSservicelist = Get-WmiObject win32_service
foreach ($OSservice in $OSservicelist) {
$OSr = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$($OSservice.Name)"
If ( $OSr.DelayedAutostart -eq 1 -and $OSr.Start -eq 2 ) { $OSservice.StartMode = $OSservice.StartMode +
' (Delayed)' }
}
$OSservicelist | Sort DisplayName | format-table -Property DisplayName, Name, StartName, StartMode, State |
Out-File $DataDest\Services.txt -Width 250 -Encoding utf8
'Getting details about Windows Certificate Store' | Out-Host
Get-ChildItem cert: -Recurse | Where {!$_.PSIsContainer} | Format-List Subject, FriendlyName, PSParentPath,
Issuer, Thumbprint, DnsNameList, NotBefore, NotAfter, HasPrivateKey, EnhancedKeyUsageList | Out-File
$DataDest\Windows_Cert_Store.txt -Encoding utf8
'Getting details about available memory dumps' | Out-Host
$dmp = Get-ChildItem -Path $FinServiceList.Path -Include *.hprof,*.mdmp,*.dmp -Recurse
If (![string]::IsNullOrEmpty($dmp)) {
$dmp | Format-Table -Property FullName, Length, LastWriteTime -AutoSize | Out-File $DataDest\Dump_List.
txt -Encoding utf8
} Else {
'No hprof/mdmp/dmp files found.' | Out-File $DataDest\Dump_List.txt -Encoding utf8
}
}
'Compressing the files' | Out-Host
$FileName = "$($RootCollectionPath)\$($FolderName)_YSoftDiagData_$((Get-Date).ToString('yyyy-MM-dd-HH-mmss')).
zip"
Compress-ZIP -Directory $DataDest -Destination $FileName
'Removing temporary files' | Out-Host
Remove-Item -Path $DataDest -Recurse -Force
Write-Output ""
Write-Output "Work done, the output is in $FileName"
Write-Output 'Feel free to close the script'
Read-Host
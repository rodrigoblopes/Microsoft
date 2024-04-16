Import-Module C:\SOE\Scripts\SOEModule.psm1
$script:soe = Get-SOE
if ($null -eq $soe) { break }

$Server = "file01.edphotels.com.au"
$Serverpath = "\\$Server\Companydata$" 
$ServerExists = (Test-NetConnection -ComputerName $Server).PingSucceeded

$PSDriveName = "F"

If (!$ServerExists) {
    Write-Host "Not on EDP Network unable to map drive"
    Exit
}

$psd = Get-PSDrive -Name $PSDriveName -ErrorAction SilentlyContinue
if ($null -ne $psd) {

    # a drive is mapped, but we're not sure if this is the correct
    # mapping
    $desiredRoot = $Serverpath.ToLower()
    # weird usage of DisplayRoot, but it works
    $actualRoot = $psd.DisplayRoot.ToLower()

    Write-Host "Checking to see if drive is mapped to correct UNC path ($desiredRoot)."

    if ($desiredRoot -eq $actualRoot) {
        Write-Host "Drive Already Mapped to correct UNC path"
        Exit
    }

}

# set a default set of credentials
$smb = [PSCustomObject]@{
    User = "EDP\design-smb"
    Password = "CyanAnaconda79"
}

# update smb object if Design-SMB.json exists
if (Test-Path -Path "$($script:soe.Config)\Design-SMB.json") {
    Write-Host "Getting override credentials from Design-SMB.json file..."
    $smb = Get-Content -Path "$($script:soe.Config)\Design-SMB.json" | ConvertFrom-Json
    Write-Host "Updated user is $($smb.User)"
}

# remove the psdrive for F as it isn't there, or is mapped incorrectly
Remove-PSDrive -Name $PSDriveName -ErrorAction SilentlyContinue -Force | Out-Null

$cred = [pscredential]::new($smb.User, (ConvertTo-SecureString $smb.Password -AsPlainText -Force))
$params = @{
    Name = $PSDriveName;
    PSProvider = "FileSystem";
    Root = $Serverpath;
    Credential = $cred;
    Persist = $true;
    Scope = "Global";
}

Write-Host "Attempting to map $PSDriveName to $Serverpath"
New-PSDrive @params | Out-Null

Write-Host "Drive is now mapped."
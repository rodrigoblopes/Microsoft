# Check if Active Directory module is installed
$adModuleInstalled = Get-Module -ListAvailable -Name ActiveDirectory

if (-not $adModuleInstalled) {
    Write-Host "Active Directory module is not installed. Installing..."
    Install-WindowsFeature RSAT-AD-PowerShell
    Write-Host "Active Directory module installed."
} else {
    Write-Host "Active Directory module is already installed."
}

# Check execution policy
$executionPolicy = Get-ExecutionPolicy

if ($executionPolicy -eq "Restricted") {
    Write-Host "Execution policy is restricted. Changing to RemoteSigned..."
    Set-ExecutionPolicy RemoteSigned
    Write-Host "Execution policy updated."
} else {
    Write-Host "Execution policy is already set to $executionPolicy."
}

# Get subfolder names under C:\Users
$usersFolder = "C:\Users"
$subfolders = Get-ChildItem -Path $usersFolder -Directory

# Get a list of enabled user accounts from Active Directory
$enabledAccounts = Get-ADUser -Filter {Enabled -eq $true} -Properties SamAccountName

# Compare subfolder names with enabled account names
foreach ($subfolder in $subfolders) {
    $subfolderName = $subfolder.Name
    $matchingAccount = $enabledAccounts | Where-Object { $_.SamAccountName -eq $subfolderName }

    if ($matchingAccount) {
        Write-Host "User account '$subfolderName' is enabled." -ForegroundColor Green
    } else {
        Write-Host "User account '$subfolderName' is disabled." -ForegroundColor Red
    }
}

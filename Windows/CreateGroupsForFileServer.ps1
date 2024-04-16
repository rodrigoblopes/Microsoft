# Set the base path
$basePath = "N:\Ninti One Limited"

# Set the target OU
$ouPath = "OU=Test,OU=Security Groups,OU=SBSUsers,OU=Users,OU=MyBusiness,DC=nintione,DC=local"

# Get a list of folders in the base path
$folders = Get-ChildItem -Path $basePath -Directory

# Loop through each folder
foreach ($folder in $folders) {
    $folderName = $folder.Name

    # Define group names
    $dlGroupNameFA = "DL_FA_$folderName"
    $dlGroupNameRO = "DL_RO_$folderName"
    $gsGroupNameFA = "GS_FA_$folderName"
    $gsGroupNameRO = "GS_RO_$folderName"

    # Check if groups already exist
    $existingGroupsFA = Get-ADGroup -Filter { Name -eq $dlGroupNameFA } -SearchBase $ouPath -ErrorAction SilentlyContinue
    $existingGroupsRO = Get-ADGroup -Filter { Name -eq $dlGroupNameRO } -SearchBase $ouPath -ErrorAction SilentlyContinue

    if ($existingGroupsFA -or $existingGroupsRO) {
        Write-Host "Groups $dlGroupNameFA or $dlGroupNameRO already exist in OU: $ouPath. Skipping..."
        continue
    }

    # Create Domain Local Security Groups in the specified OU
    New-ADGroup -Name $dlGroupNameFA -GroupScope DomainLocal -GroupCategory Security -Description "Access to $basePath\$folderName - Modify Permission" -Path $ouPath
    New-ADGroup -Name $dlGroupNameRO -GroupScope DomainLocal -GroupCategory Security -Description "Access to $basePath\$folderName - Read Only Permission" -Path $ouPath

    # Edit folder permissions and add Domain Local groups
    $folderPath = Join-Path $basePath $folderName
    try {
        icacls $folderPath /grant "$($dlGroupNameFA):(OI)(CI)M"
        icacls $folderPath /grant "$($dlGroupNameRO):(OI)(CI)R"
    } catch {
        Write-Host "Error modifying folder permissions for $folderPath. Error details: $_"
    }

    # Create Global Security Groups in the specified OU
    New-ADGroup -Name $gsGroupNameFA -GroupScope Global -GroupCategory Security -Description "Access to $basePath\$folderName - Modify Permission" -Path $ouPath
    New-ADGroup -Name $gsGroupNameRO -GroupScope Global -GroupCategory Security -Description "Access to $basePath\$folderName - Read Only Permission" -Path $ouPath

    # Add Global Security Groups as members of Domain Local Security Groups
    Add-ADGroupMember -Identity $dlGroupNameFA -Members $gsGroupNameFA
    Add-ADGroupMember -Identity $dlGroupNameRO -Members $gsGroupNameRO
}

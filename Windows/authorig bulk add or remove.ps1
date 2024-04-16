# Import the Active Directory module
Import-Module ActiveDirectory

# Specify the group name and file paths
$groupName = "AllowsendtoDistributionList"
$currentUsersFilePath = "C:\Temp\AllowSendtoDistributionList_current.txt"
$logFilePath = "C:\Temp\AllowSendtoDistributionList_changes.txt"

# Step 1: Compare the current group members with the file
$currentGroupMembers = Get-ADGroupMember -Identity $groupName | Select-Object -ExpandProperty DistinguishedName
$previousGroupMembers = Get-Content -Path $currentUsersFilePath

$changes = Compare-Object $currentGroupMembers $previousGroupMembers

if ($changes) {
    # Step 2: If there's a difference, perform the following actions
    Write-Host "Changes detected. Starting the changes."

    # Step 2a: Delete all users from the attribute authorig in all distribution groups
    $universalDistributionGroups = Get-ADGroup -Filter {GroupCategory -eq 'Distribution' -and GroupScope -eq 'Universal'}
    
    foreach ($group in $universalDistributionGroups) {
        Set-ADGroup -Identity $group -Clear authorig
    }

    # Step 2b: Include the current users from the group AllowsendtoDistributionList in the attribute authorig in all Distribution Groups
    foreach ($group in $universalDistributionGroups) {
        Set-ADGroup -Identity $group -Add @{authorig=$currentGroupMembers -join ","}
    }

    # Step 2c: Export the new values replacing the old $currentUsersFilePath
    $currentGroupMembers | Out-File -FilePath $currentUsersFilePath -Encoding utf8
    Write-Host "New values exported to $currentUsersFilePath."

    # Step 3: Save changes in the log file
    "Changes detected at $(Get-Date)" | Out-File -Append -FilePath $logFilePath
    "Users Added: $($currentGroupMembers -join ', ')" | Out-File -Append -FilePath $logFilePath
    "--------------------------------------" | Out-File -Append -FilePath $logFilePath

    Write-Host "Changes detected and logged. Current users file and distribution group attributes updated."
} else {
    # Step 4: If no change, print a message
    Write-Host "No change happened. Current users file remains unchanged."
}

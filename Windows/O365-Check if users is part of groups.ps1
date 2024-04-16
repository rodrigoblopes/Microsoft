# Import required module
Import-Module ActiveDirectory

# Specify the groups
$adGroups = @("Domain Admins", "Enterprise Admins", "Schema Admins")

# Get all users
$users = Get-ADUser -Filter *

# Initialize an array to store the results
$results = @()

# Check group membership for each user
foreach ($user in $users) {
    Write-Host "Checking user: $($user.UserPrincipalName)"
    
    # Use sAMAccountName to get user
    $userObject = Get-ADUser -Filter { sAMAccountName -eq $user.SamAccountName }

    # Check group membership in Active Directory
    $adMembership = Get-ADPrincipalGroupMembership -Identity $userObject | Select-Object -ExpandProperty Name
    Write-Host "Groups: $($adMembership -join ', ')"

    # Find common groups between user's groups and specified groups
    $elevatedGroups = $adGroups | Where-Object { $adMembership -contains $_ }

    # Initialize result
    $result = if ($elevatedGroups) { $elevatedGroups -join ', ' } else { "No elevated privileges" }

    # Add result to the results array
    $results += [PSCustomObject]@{
        Name = $user.Name
        UPN = $user.UserPrincipalName
        Result = $result
    }
}

# Specify the output file path
$outputFilePath = "C:\Temp\AD_Privileges_Output.csv"

# Output results to CSV file
$results | Export-Csv -Path $outputFilePath -NoTypeInformation
Write-Host "Results exported to $outputFilePath."

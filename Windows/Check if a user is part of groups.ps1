
<#

Check if a user is part of the groups listed in $adGroups

#>

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
    # Check group membership in Active Directory
    $adMembership = $user.MemberOf | Get-ADGroup | Select-Object -ExpandProperty Name

    # Initialize result
    $result = "No elevated privileges"

    # Check if user is part of any of the specified groups
    foreach ($group in $adGroups) {
        if ($group -in $adMembership) {
            $result = $group
            break
        }
    }

    # Add result to the results array
    $results += [PSCustomObject]@{
        UPN = $user.UserPrincipalName
        Name = $user.Name
        Result = $result
    }
}

# Output results to CSV file
$results | Export-Csv -Path "C:\Temp\AD_Privileges_output.csv" -NoTypeInformation

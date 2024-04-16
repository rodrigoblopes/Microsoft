# Import the Active Directory module
Import-Module ActiveDirectory

# Define the OUs
$OUs = @(
    "OU=Distribution Groups,OU=MyBusiness,DC=StBasils,DC=local",
    "OU=Groups,OU=St Basils,DC=StBasils,DC=local"
)

# Iterate through each OU
foreach ($OU in $OUs) {
    # Get all distribution groups in the current OU
    $DistributionGroups = Get-ADGroup -Filter {GroupCategory -eq "Distribution"} -SearchBase $OU #-Properties authOrig

    # Process each distribution group
    foreach ($Group in $DistributionGroups) {
        # Store the existing values in 'authOrig'
        $existingAuthOrig = $Group.authOrig

        # Add the specified security group to 'authOrig' if not already present
        $SecurityGroup = Get-ADGroup -Filter {Name -eq "Allow send to Distribution List"} -SearchBase "OU=Security Groups,OU=MyBusiness,DC=StBasils,DC=local"
        if ($SecurityGroup -ne $null -and $existingAuthOrig -notcontains $SecurityGroup.DistinguishedName) {
            Set-ADGroup -Identity $Group.DistinguishedName -Add @{authOrig=$SecurityGroup.DistinguishedName}
            Write-Host "Added 'Allow send to Distribution List' to 'authOrig' for $($Group.Name)"
        }
        else {
            Write-Host "Security group 'Allow send to Distribution List' already present or not found for $($Group.Name)."
        }
    }
}
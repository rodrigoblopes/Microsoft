#Remove all users assigned to the Perfectdata Software
Connect-MgGraph

# Get Service Principal using objectId
$sp = Get-MgServicePrincipal -ServicePrincipalId e367d79c-4bc2-491c-9881-b6ccb3e276cb

# Get MS Graph App role assignments using objectId of the Service Principal
$assignments = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $sp.Id -All

# Remove all users and groups assigned to the application
$assignments | ForEach-Object {
    if ($_.PrincipalType -eq "User") {
        Remove-MgUserAppRoleAssignment -UserId $_.PrincipalId -AppRoleAssignmentId $_.Id
    } elseif ($_.PrincipalType -eq "Group") {
        Remove-MgGroupAppRoleAssignment -GroupId $_.PrincipalId -AppRoleAssignmentId $_.Id
    }
}
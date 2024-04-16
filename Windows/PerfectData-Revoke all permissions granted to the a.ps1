#Revoke all permissions granted to the application
Connect-MgGraph

# Get Service Principal using objectId
$sp = Get-MgServicePrincipal -ServicePrincipalId e367d79c-4bc2-491c-9881-b6ccb3e276cb

# Get all delegated permissions for the service principal
$spOAuth2PermissionsGrants = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $sp.Id -All

# Remove all delegated permissions
$spOAuth2PermissionsGrants | ForEach-Object {
    Remove-MgOauth2PermissionGrant -OAuth2PermissionGrantId $_.Id
}

# Get all application permissions for the service principal
$spApplicationPermissions = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id

# Remove all app role assignments
$spApplicationPermissions | ForEach-Object {
    Remove-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $_.PrincipalId -AppRoleAssignmentId $_.Id
}
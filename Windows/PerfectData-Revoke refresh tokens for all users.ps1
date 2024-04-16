#Revoke refresh tokens for all users
Connect-MgGraph

# Get Service Principal using objectId
$sp = Get-MgServicePrincipal -ServicePrincipalId e367d79c-4bc2-491c-9881-b6ccb3e276cb

# Get MS Graph App role assignments using objectId of the Service Principal
$assignments = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $sp.Id -All | Where-Object {$_.PrincipalType -eq "User"}

# Revoke refresh token for all users assigned to the application
$assignments | ForEach-Object {
    Invoke-MgInvalidateUserRefreshToken -UserId $_.PrincipalId
}
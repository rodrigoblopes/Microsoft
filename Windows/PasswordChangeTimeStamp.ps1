#Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All" -TenantId 19e41c83-89af-462a-8fdc-4302e47ac19f
 
#Set the properties to retrieve
$Properties = @(
    "id",
    "DisplayName",
    "userprincipalname",
    "PasswordPolicies",
    "lastPasswordChangeDateTime",
    "pwdlastset"
    "mail",
    "jobtitle",
    "department",
    "whenCreated",
    "AccountEnabled"
    )
 
#Retrieve the password change date timestamp of all users
$AllUsers = Get-MgUser -All -Property $Properties | Select -Property $Properties
 
#Export to CSV
$AllUsers | Export-Csv -Path "C:\Temp\PasswordChangeTimeStamp.csv" -NoTypeInformation


#Read more: https://www.sharepointdiary.com/2022/04/office-365-get-last-password-change-date-using-powershell.html#ixzz8LucUNGRv
# Remove automapping for a shared mailbox
# https://learn.microsoft.com/en-us/outlook/troubleshoot/profiles-and-accounts/remove-automapping-for-shared-mailbox
# https://learn.microsoft.com/en-us/previous-versions/office/exchange-server-2010/hh529943(v=exchg.141)

#1. Connect to Exchange Online PowerShell.
Connect-ExchangeOnline

#2. To remove the user's full access permission from the mailbox, run the following command:
#This example removes full access permissions from Kathleen Reiter's mailbox for the admin account.
Remove-MailboxPermission -Identity kathleenr@contoso.onmicrosoft.com -User admin@contoso.onmicrosoft.com -AccessRights FullAccess

#3. To grant full access permissions back to the user on the mailbox with automapping disabled, run the following command:
Add-MailboxPermission -Identity kathleenr@contoso.onmicrosoft.com -User admin@contoso.onmicrosoft.com -AccessRights FullAccess -AutoMapping $false
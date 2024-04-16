# Connect to Exchange Online
#$UserCredential = Get-Credential
#$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
#Import-PSSession $Session

# Start the historical search
$HistoricalSearch = Start-HistoricalSearch -ReportType MessageTrace -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date) -SenderAddress jboylan@claytonhomes.com.au -ReportTitle "Email activity for jboylan@claytonhomes.com.au"

# Wait for the search to complete
while ($HistoricalSearch.Status -eq "NotStarted") {
    Start-Sleep -Seconds 10
    Get-HistoricalSearch
}

# Export the results to a CSV file
$HistoricalSearch | Export-Csv -Path "C:\Users\Rodrigo.Lopes\OneDrive - Comwire IT\Desktop\Ticket\ClaytonChurchInvest\Logs\EmailActivity.csv" -NoTypeInformation

# Disconnect the session
#Remove-PSSession $Session

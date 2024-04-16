#Run the following commands before execute the scripts:
#Connect-ExchangeOnline
#Connect-IPPSSession

#Define the name of the Search
$searchName = "T20230918.0208-1306 Delete Deleted Items"

$searchNamePurge = "$searchName" + "_Purge"
$action = {
    New-ComplianceSearchAction -SearchName $searchName -Purge -PurgeType HardDelete -Confirm:$false -Force
}

for ($i = 1; $i -le 100; $i++) {
    Write-Host "Executing iteration $i"
    do {
        Start-Sleep -Seconds 100 
        $status = Get-ComplianceSearchAction | Where-Object { $_.Name -eq $searchNamePurge }
        Write-Host "Status: $($status.Status)"
    } while ($status.Status -ne "Completed")

    try {
        & $action
    }
    catch {
        Write-Host "An error occurred while executing the command. Exiting loop."
        break
    }
}
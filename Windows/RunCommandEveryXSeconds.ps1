# Define the mailbox identity
$MailboxIdentity = "roryd@navigatefinancial.com.au"

# Infinite loop to run the command every 90 seconds
while ($true) {
    # Get mailbox statistics and format the output
    Get-MailboxStatistics -Identity $MailboxIdentity -Archive |
        Format-Table DisplayName, ItemCount, TotalItemSize -AutoSize

    # Wait for 90 seconds
    Start-Sleep -Seconds 90
}

$SMBUser = "EDP\design-smb"
$SMBPass = "CyanAnaconda79"
$Server = "file01.edphotels.com.au"
$Serverpath = "\\$Server\Companydata$" 
$ServerExists = (Test-NetConnection -ComputerName $Server).PingSucceeded

$PSDriveName = "F"
$pathExists = Test-Path -Path "$($PSDriveName):\Design"

If ($ServerExists)  {
    If ($pathExists)  {
        Write-Host "Drive Already Mapped"
        # remove the psdrive for F just in case
        Remove-PSDrive -Name $PSDriveName -ErrorAction SilentlyContinue -Force
        Start-Sleep -Seconds 5

        $cred = [pscredential]::new($SMBUser, (ConvertTo-SecureString $SMBPass -AsPlainText -Force))
        $params = @{
            Name = $PSDriveName;
            PSProvider = "FileSystem";
            Root = $Serverpath;
            Credential = $cred;
            Persist = $true;
            Scope = "Global";
        }
        Exit
    }
    else {

        # remove the psdrive for F just in case
        Remove-PSDrive -Name $PSDriveName -ErrorAction SilentlyContinue -Force

        $cred = [pscredential]::new($SMBUser, (ConvertTo-SecureString $SMBPass -AsPlainText -Force))
        $params = @{
            Name = $PSDriveName;
            PSProvider = "FileSystem";
            Root = $Serverpath;
            Credential = $cred;
            Persist = $true;
            Scope = "Global";
        }

        Write-Host "Attempting to map $PSDriveName to $Serverpath"
        New-PSDrive @params

        Write-Host "Drive Mapped"
        Exit
    }
} else {
    Write-Host "Not on EDP Network unable to map drive"
    Exit
}
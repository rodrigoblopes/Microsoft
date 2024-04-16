$newFQDN = "fortivpn.avkau.com.au:44245"

$paths = Resolve-Path HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\*\
foreach($path in $paths){
    Set-ItemProperty -Path $path -Name "Server" -Value $newFQDN
}
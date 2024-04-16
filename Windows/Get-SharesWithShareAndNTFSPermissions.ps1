 <#
        License terms
        This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
        
        This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
        
        You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.
        #>

# Get Server List from Domain
Clear-Host

$DomName = Get-ADDomain |Select -Expand NetBIOSName

$ServerListPath = New-Item -ItemType Directory -Force -Path C:\TEMP${DomName}_Onboarding${DomName}_ServerShares
$ServerListFile = "Servers.txt"

Get-ADComputer -Filter ('operatingSystem -Like "*Server*" -and Enabled -Eq "TRUE"') | Select-Object -Expand Name |Out-File $ServerListPath\$ServerListFile


# Invoke Share Commands for All Servers in Active Directory
$Servers = Get-Content $ServerListPath\$ServerListFile
$resultShares = foreach ($Server in $Servers) {
    Write-Host "Processing $Server basic Share info. Please wait."
    try{

        Invoke-Command -ErrorAction Stop -cn $server{
                     
        #get all Shares
$shares    = Get-WmiObject -Class Win32_Share 
$shareList = New-Object -TypeName System.Collections.ArrayList

foreach ($share in $shares) {
  
  #excluding default shares   
  if ($share.Name -notmatch '(?im)^([a-z]{1}|admin|ipc|print)\$$') {
  #if (($share.Name -notmatch '(?im)^[a-z]{1,1}\$') -and ($share.Name -notmatch '(?im)^[admin]{5,5}\$') -and ($share.Name -notmatch '(?im)^[ipc]{3,3}\$') -and ($share.Name -notmatch '(?im)^[print]{5,5}\$') )
    
    $shareAccessInfo = ''
    $ntfsAccessInfo  = ''    
    
    #extract permissions from the current share
    $fileAccessControlList = Get-Acl -Path $($share.Path) | Select-Object -ExpandProperty Access | Select-Object -Property FileSystemRights, AccessControlType, IdentityReference    
    
    #excluding uncritical information as Builtin Accounts as Administratrators, System, NT Service and Trusted installer
    foreach ($fileAccessControlEntry in $fileAccessControlList) {
      if (($fileAccessControlEntry.FileSystemRights -notmatch '\d') -and ($fileAccessControlEntry.IdentityReference -notmatch '(?i)Builtin\\Administrators|NT\sAUTHORITY\\SYSTEM|NT\sSERVICE\\TrustedInstaller')) {      
        $ntfsAccessInfo += "$($fileAccessControlEntry.IdentityReference); $($fileAccessControlEntry.AccessControlType); $($fileAccessControlEntry.FileSystemRights)" + ' | '  
      }
    } #END foreach ($fileAccessControlEntry in $fileAccessControlList)

    $ntfsAccessInfo = $ntfsAccessInfo.Substring(0,$ntfsAccessInfo.Length - 3)
    $ntfsAccessInfo = $ntfsAccessInfo -replace ',\s?Synchronize',''   
    
    #getting share permissions   
    $shareSecuritySetting    = Get-WmiObject -Class Win32_LogicalShareSecuritySetting -Filter "Name='$($share.Name)'"               
    $shareSecurityDescriptor = $shareSecuritySetting.GetSecurityDescriptor()
    $shareAcccessControlList = $shareSecurityDescriptor.Descriptor.DACL          
    
    #converting share permissions to be human readable
    foreach($shareAccessControlEntry in $shareAcccessControlList) {
    
      $trustee    = $($shareAccessControlEntry.Trustee).Name      
      $accessMask = $shareAccessControlEntry.AccessMask
      
      if($shareAccessControlEntry.AceType -eq 0) {
        $accessType = 'Allow'
      } else {
        $accessType = 'Deny'
      }
        
      if ($accessMask -match '2032127|1245631|1179817|1179819') {          
        if ($accessMask -eq 2032127) {
          $accessMaskInfo = 'FullControl'
        } elseif ($accessMask -eq 1179817) {
          $accessMaskInfo = 'Read'
        } elseif ($accessMask -eq 1179819) {
          $accessMaskInfo = 'Read'
        } elseif ($accessMask -eq 1245631) {
          $accessMaskInfo = 'Change'
        } else {
          $accessMaskInfo = 'unknown'
        }
        $shareAccessInfo += "$trustee; $accessType; $accessMaskInfo" + ' | '
      }            
    
    } #END foreach($shareAccessControlEntry in $shareAcccessControlList)
    
       
    if ($shareAccessInfo -match '|') {
      $shareAccessInfo = $shareAccessInfo.Substring(0,$shareAccessInfo.Length - 3)
    }               
    
    #putting extracted information together into a custom object
    $myShareHash = @{'Name'=$share.Name}
    $myShareHash.Add('FileSystemsPath',$share.Path )       
    $myShareHash.Add('Description',$share.Description)        
    $myShareHash.Add('NTFSPermissions',$ntfsAccessInfo)
    $myShareHash.Add('SharePermissions',$shareAccessInfo)
    $myShareObject = New-Object -TypeName PSObject -Property $myShareHash
    $myShareObject.PSObject.TypeNames.Insert(0,'MyShareObject')  
    
    #store the custom object in a list    
    $null = $shareList.Add($myShareObject)
  
  } #END if (($share.Name -notmatch '(?im)^[a-z]{1,1}\$') -and ($share.Name -notmatch '(?im)^[admin]{5,5}\$') -and ($share.Name -notmatch '(?im)^[ipc]{3,3}\$') )
  
} #END foreach ($share in $shares)

$shareList

        }
    }
    catch {
        "$server could not be contacted. System may be Windows Server 2008, be offline, or PS Remoting is not enabled." | Out-File -Append $ServerListPath\Share_Permissions_Exceptions.csv
        }
    } $reorderedShareList = $resultShares | Select-Object PSComputerName, Name, Description, FileSystemPath, SharePermissions, NTFSPermissions, RunspaceId, PSShowComputerName
    $resultShares | Export-csv $ServerListPath\Server_Share_Permissions_Info.csv -NoTypeInformation -Append    



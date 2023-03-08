$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer() #Change to SCCM server name

$computerscope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$updatescope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
#Exclude the following states from update list
$updatescope.ExcludedInstallationStates = 'NotApplicable','Unknown','Installed'

#Create Forward and Reverse lookup
$groups = @{}
$dataHolder = @()
$wsus.GetComputerTargetGroups() | ForEach-Object {$groups[$_.Name]=$_.id;$groups[$_.ID]=$_.name}

Do {
$keepRunning = $true
Write-Host "
----------MENU----------------------------
1 = List WSUS Groups
 = Pull Updates For Entire WSUS Group
3 = Quit
------------------------------------------"
$choice1 = read-host -prompt "Select-Object number & press enter:"

Switch ($choice1) {
"1" {$wsus.GetComputerTargetGroups().Name}
"2" {
$DataHolder = @()
$computerscope4 = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$updatescope4 = New-Object Microsoft.UpdateServices.Administration.UpdateScope
#Only list updates that are needed
$updatescope4.ExcludedInstallationStates = 'NotApplicable','Unknown','Installed'
#Only list updates that are approved
$updatescope4.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::LatestRevisionApproved;

$TargetGroup = Read-Host -prompt "Please enter a group name:"

$pcgroup = @($wsus.GetComputerTargets($computerscope4) | Where-Object {$_.ComputerTargetGroupIds -eq $groups[$TargetGroup]}) | Select-Object -expand Id

$pcinfo = $wsus.GetSummariesPerComputerTarget($updatescope4,$computerscope4) | Where-Object {$pcgroup -Contains $_.ComputerTargetID} | ForEach-Object {
$computerscope2 = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$computerscope2.NameIncludes = $wsus.GetComputerTarget(([guid]$_.ComputerTargetId)).FullDomainName
 
$pcupSum = ($wsus.GetSummariesPerUpdate($updatescope4,$computerscope2) | ForEach-Object {($wsus.GetUpdate($_.UpdateId).Title)})
 

$data = New-Object PSObject -Property @{
"Client" = $wsus.GetComputerTarget(([guid]$_.ComputerTargetId)).FullDomainName
"IP Address" = $wsus.GetComputerTarget(([guid]$_.ComputerTargetId)).IPAddress
"Group" = $wsus.GetComputerTarget(([guid]$_.ComputerTargetId)).RequestedTargetGroupName
"Updates" = ($_.NotInstalledCount + $_.DownloadedCount)
"Failed" = $_.FailedCount
"LastSync" = $wsus.GetComputerTarget(([guid]$_.ComputerTargetId)).LastReportedStatusTime
"Titles" = $pcupSum | Out-String
}
  
$DataHolder += $data | Select-Object Client,"IP Address",Group,Updates,Failed,LastSync,Titles | Where-Object {$_.Updates -ne "0"}

}
#Display table in PS Window. Commented out due to being too large of a table to display properly.
#$DataHolder | Select-Object Client,"IP Address",Group,Updates,Failed,LastSync,Titles| Sort LastSync -Descending |
#Format-Table -Wrap -Autosize @{L="Last Sync with WSUS";E={$_.LastSync};align='left'},@{L="Host Name";E={$_.Client};align='center'},"IP Address",@{L="WSUS Group";E={$_.Group};align='center'},@{L="# Needed";E={$_.Updates};align='center'},@{L="Failed";E={$_.Failed};align='center'},@{L="Updates Titles";E={$_.Titles};align='left'}
 
#Create CSV
$DataHolder | Select-Object LastSync,Client,"IP Address",Group,Updates,Failed,Titles | Sort-Object LastSync -Descending | Export-Csv "$TargetGroup.csv" -NoTypeInformation
#Display GridView Popup
$DataHolder | Select-Object LastSync,Client,"IP Address",Group,Updates,Failed,Titles | Sort-Object LastSync -Descending | Out-GridView -Title $TargetGroup

$DataHolder= @()
$pcupSum = ""
}
"3" {$keepRunning = $False
exit 
}
}
} while ($keepRunning -eq $true)
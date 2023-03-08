$User = ''
$Password = ''
$count=0
$reopen_array = @()

#// Set Instance
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; 
#$URI = 'https://yara.service-now.com/api/now/table/sc_task?sysparm_query=state=2^assigned_to.sys_id=458a1bd1dbd6cf0062c4fe9b0c961994^u_reopen_count!=0'
$URI = 'https://page.service-now.com/api/now/table/sc_task?sysparm_query=state=2^assigned_to.sys_id=458a1bd1dbd6cf0062c4fe9b0c961994'

#// Create SN REST API credentials 
$SNowUser = $User 
$SNowPass = $Password | ConvertTo-SecureString -asPlainText -Force 
$SNowCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SNowUser, $SNowPass 
 
#// Get all incidents Assigned To
$Requests = Invoke-RestMethod -Uri $URI -Credential $SNowCreds -Method Get -ContentType "application/json" 


#// Show each incident found 
foreach ($rtsk in $Requests.result) 
{
    $details = $rtsk.number
    $reopen = $rtsk.u_reopen_count

    if($reopen -ne '0')
    {
        $reopen_array += $rtsk.number
    }

}
$count = $reopen_array.Count
$reopen_array

if($count -ne 0)
{
$Now = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$logger_file = 'H:\Runbooks\reopen\'+$Now+'.txt'
if(Test-path -path $logger_file)
{
Write-Output $reopen_array >> $logger_file
}
else
{
New-Item -path $logger_file -ItemType 'file'
}
}
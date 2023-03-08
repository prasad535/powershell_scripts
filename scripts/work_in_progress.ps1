$User = ''
$Password = ''
$count=0
$array = @()

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

foreach ($rtsk in $Requests.result) 
{
    $details = $rtsk.number
    $reopen = $rtsk.u_reopen_count

    $created_date = [DateTime]$rtsk.sys_created_on
    $current_date = Get-Date

    $diferenceTime = [float]($current_date - $created_date).TotalHours

    if(($diferenceTime -gt 12) -and ($reopen -eq '0'))
        {
            $array += $rtsk.number
        }
}

if($count -ne 0)
{
$Now = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$logger_file = 'c:\temp\'+$Now+'.txt'
Write-Output $array >> $logger_file
}

$array
$count = $array.Count
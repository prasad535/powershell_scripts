function PasswordManager{
    param(
        [Parameter(Mandatory=$true)] [string] $SERVICE_NOW_USERNAME,
        [Parameter(Mandatory=$true)] [securestring] $SERVICE_NOW_TEST_PASSWORD
    )
    #$SECURE_PASSWORD = $SERVICE_NOW_TEST_PASSWORD | ConvertTo-SecureString -AsPlainText -Force
    $PSCredentials = New-Object -TypeName System.Management.Automation.PSCredential ($SERVICE_NOW_USERNAME, $SERVICE_NOW_TEST_PASSWORD)
    return $PSCredentials
}

function ServiceNowPOST
{
    param
  (
    [Parameter(Mandatory=$true)] [string] $Rtask,
    [Parameter(Mandatory=$true)] [string] $Notes,
    [Parameter(Mandatory=$true)] [string] $Action
  )

  $SERVICE_NOW_USERNAME = ""
  $SERVICE_NOW_TEST_PASSWORD = ""

  $SECURE_PASSWORD = $SERVICE_NOW_TEST_PASSWORD | ConvertTo-SecureString -AsPlainText -Force
  $Credential = PasswordManager -SERVICE_NOW_USERNAME $SERVICE_NOW_USERNAME -SERVICE_NOW_TEST_PASSWORD $SECURE_PASSWORD
  start-sleep 5
  $URI = "https://page.service-now.com/api/now/import/u_m2m_transactions_catalog_task"
  
  #$body = '{"u_sn_catalog_task_number":"'+$Rtask +'" , "u_work_notes":"'+ $Notes+'"  , "u_action":"'+$Action +'"}'

   $body = @{
'u_action' = $Action 
"u_sn_catalog_task_number" = $Rtask 
"u_work_notes" = $Notes
#"u_resolution_notes" = $notes
}
$bodyJson = $body | ConvertTo-Json

  $Requests = Invoke-RestMethod -uri $URI -Credential $Credential -Method Post -ContentType "application/json" -Body $bodyJson 

}

$Rtask = ""
$worknotes = ""
$action = ""

$Payload = ""

$File_path = 'H:\Logger\Logs\'+$Rtask+'.log'

if(Test-path -path $File_path)
{
Write-output $worknotes >> $File_path
Write-output $Payload >> $File_path
}
else{
New-Item -path $File_path
Write-output $worknotes >> $File_path
Write-output $Payload >> $File_path
}

ServiceNowPOST -Rtask $Rtask -Notes $worknotes -Action $action
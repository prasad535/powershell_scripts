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
    [Parameter(Mandatory=$true)] [string] $Action,
    [Parameter(Mandatory=$true)] [string] $ResolutionNotes
  )

  $SERVICE_NOW_USERNAME = ""
  $SERVICE_NOW_TEST_PASSWORD = ""

  $SECURE_PASSWORD = $SERVICE_NOW_TEST_PASSWORD | ConvertTo-SecureString -AsPlainText -Force
  $Credential = PasswordManager -SERVICE_NOW_USERNAME $SERVICE_NOW_USERNAME -SERVICE_NOW_TEST_PASSWORD $SECURE_PASSWORD
  start-sleep 5
  $URI = "https://page.service-now.com/api/now/import/u_m2m_transactions_catalog_task"
  
  #$body = '{"u_sn_catalog_task_number":"'+$Rtask +'" , "u_work_notes":"'+ $Notes+'"  , "u_action":"'+$Action +'","u_resolution_notes":"'+$ResolutionNotes+'"}'

   $body = @{
   'u_action' = $Action 
   "u_sn_catalog_task_number" = $Rtask 
   "u_work_notes" = $Notes
   "u_resolution_notes" = $ResolutionNotes
}
$bodyJson = $body | ConvertTo-Json  

$Requests = Invoke-RestMethod -uri $URI -Credential $Credential -Method Post -ContentType "application/json" -Body $bodyJson 

}

$Rtask = "\`d.T.~Ed/{8DB9DA96-1EF7-46FD-AC6D-EFF733A6D8AE}.{18502BDC-8911-43BA-8252-64D3C6C875C8}\`d.T.~Ed/"
$worknotes = "\`d.T.~Ed/{8DB9DA96-1EF7-46FD-AC6D-EFF733A6D8AE}.{7A742280-5332-4227-9CD7-30BA749BED07}\`d.T.~Ed/"
$action = "\`d.T.~Ed/{8DB9DA96-1EF7-46FD-AC6D-EFF733A6D8AE}.{87010326-A74E-4C9D-9983-EBC2CB016838}\`d.T.~Ed/"
$ResolutionNotes = "\`d.T.~Ed/{8DB9DA96-1EF7-46FD-AC6D-EFF733A6D8AE}.{0A391482-CB82-4BA6-AB0E-25E00FA389E0}\`d.T.~Ed/"
$Payload = "\`d.T.~Ed/{8DB9DA96-1EF7-46FD-AC6D-EFF733A6D8AE}.{E0F2725F-C301-41A9-AA74-FABABF578F48}\`d.T.~Ed/"

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

ServiceNowPOST -Rtask $Rtask -Notes $worknotes -Action $action -ResolutionNotes $ResolutionNotes
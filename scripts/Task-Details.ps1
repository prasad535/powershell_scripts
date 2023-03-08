function Get-TaskDetails
{ 
[cmdletbinding()]
  param
  (
    [Parameter(Mandatory=$true)] [string] $SERVICE_NOW_USERNAME,
    [Parameter(Mandatory=$true)] [pscredential][ValidateNotNullOrEmpty()] $SERVICE_NOW_TEST_PASSWORD,
    [Parameter(Mandatory=$true)] $Tickets
  )
  
  $SECURE_PASSWORD = $SERVICE_NOW_TEST_PASSWORD| ConvertTo-SecureString -AsPlainText -Force

  $PSCredentials = New-Object –TypeName System.Management.Automation.PSCredential ($SERVICE_NOW_USERNAME, $SECURE_PASSWORD)
  foreach($task in $Tickets)
  {
  $number = $task
    
  $URI = 'https://page.service-now.com/api/now/table/sc_task?sysparm_query=number=' + $number

  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
  $Requests = Invoke-RestMethod -Uri $URI -Credential $PSCredentials -Method Get -ContentType "application/json" 

    foreach ($rtsk in $Requests.result) 
        { 
          $details = $rtsk.number +';' + $rtsk.u_automated_description
          $num, $description = $details.split(';')
          $File_path = 'H:\Logger\Logs\ItemOne\'+$num+'.log'
          Write-Output "========================== Started Get-Task Details Activity==========================\n" >> $File_path
          Write-Output "Payload : $description \n" >> $File_path
          Write-Output "========================== Get Task details  completed==========================\n" >> $File_path
        }
  }

}

Get-TaskDetails -SERVICE_NOW_USERNAME '' -SERVICE_NOW_TEST_PASSWORD '' -Tickets 'RTSK1023098 RTSK1021951 RTSK1022779 RTSK1023366 RTSK1022054 RTSK1023533'
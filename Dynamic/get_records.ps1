function PasswordManager{
    param(
        [Parameter(Mandatory=$true)] [string] $SERVICE_NOW_USERNAME,
        [Parameter(Mandatory=$true)] [securestring] $SERVICE_NOW_TEST_PASSWORD
    )
    #$SECURE_PASSWORD = $SERVICE_NOW_TEST_PASSWORD | ConvertTo-SecureString -AsPlainText -Force
    $PSCredentials = New-Object -TypeName System.Management.Automation.PSCredential ($SERVICE_NOW_USERNAME, $SERVICE_NOW_TEST_PASSWORD)
    return $PSCredentials
}
function Get-Records
{ 
  param
  (
    [Parameter(Mandatory=$true)] [string] $ITEM_SYS_ID
  )
  $SERVICE_NOW_USERNAME = ""
  $SERVICE_NOW_TEST_PASSWORD = ""

  $SECURE_PASSWORD = $SERVICE_NOW_TEST_PASSWORD | ConvertTo-SecureString -AsPlainText -Force
  $Credential = PasswordManager -SERVICE_NOW_USERNAME $SERVICE_NOW_USERNAME -SERVICE_NOW_TEST_PASSWORD $SECURE_PASSWORD
  $ASSIGNED_TO_SYS_ID = '458a1bd1dbd6cf0062c4fe9b0c961994'
  $STATE = '-2'
  
  $URI = "https://page.service-now.com/api/now/table/sc_task?sysparm_query=request_item.cat_item.sys_id=$ITEM_SYS_ID^state=$STATE^assigned_to.sys_id=$ASSIGNED_TO_SYS_ID"
 
  $Requests = Invoke-RestMethod -Uri $URI -Credential $Credential -Method Get -ContentType "application/json"
  
  $RTASK_Array = @()
  foreach ($rtsk in $Requests.result) 
    { 
        $RTASK_Number = $rtsk.number
        $RTASK_Array += $RTASK_Number
     }  
    $count = $RTASK_Array.count
    return $count, $RTASK_Array
 
}

$ITEM_ID = ""

$Count, $Tickets_Array = Get-Records -ITEM_SYS_ID $ITEM_ID
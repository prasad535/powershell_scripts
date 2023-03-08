function PasswordManager{
    param(
        [Parameter(Mandatory=$true)] [string] $SERVICE_NOW_USERNAME,
        [Parameter(Mandatory=$true)] [securestring] $SERVICE_NOW_TEST_PASSWORD
    )
    #$SECURE_PASSWORD = $SERVICE_NOW_TEST_PASSWORD | ConvertTo-SecureString -AsPlainText -Force
    $PSCredentials = New-Object -TypeName System.Management.Automation.PSCredential ($SERVICE_NOW_USERNAME, $SERVICE_NOW_TEST_PASSWORD)
    return $PSCredentials
}

function Get-TaskDetails
{
param(
        [Parameter(Mandatory=$true)] [string] $number
    )
  $SERVICE_NOW_USERNAME = ""
  $SERVICE_NOW_TEST_PASSWORD = ""

  $SECURE_PASSWORD = $SERVICE_NOW_TEST_PASSWORD | ConvertTo-SecureString -AsPlainText -Force
  $Credential = PasswordManager -SERVICE_NOW_USERNAME $SERVICE_NOW_USERNAME -SERVICE_NOW_TEST_PASSWORD $SECURE_PASSWORD
 
    $URI = 'https://page.service-now.com/api/now/table/sc_task?sysparm_query=number=' + $number
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
    $Requests = Invoke-RestMethod -Uri $URI -Credential $Credential -Method Get -ContentType "application/json" 

    $Xml_data = $Requests.result 
    $details = $Xml_data.number +';' + $Xml_data.u_automated_description
    $num, $description = $details.split(';')
    #$File_path = 'H:\Logger\Logs\ItemOne\'+$num+'.log'
    
    return $num, $description   

}

$Tickets = ""

$number, $Description = Get-TaskDetails -number $Tickets

#$File_path = 'H:\Logger\Logs\ItemOne\'+$number+'.log'
#Write-output $Description >> $File_path
$dump = "C:\temp\clouddevices.csv"

if(Test-Path $dump)
{
    Remove-Item -Path $dump -Force
}

function Get-AuthToken 
{
  <# 
      .SYNOPSIS 
      This function is used to authenticate with the Graph API REST interface 
      .DESCRIPTION 
      The function authenticate with the Graph API Interface with the tenant name 
      .EXAMPLE 
      Get-AuthToken 
      Authenticates you with the Graph API interface 
      .NOTES 
      NAME: Get-AuthToken 
  #>
    
  [cmdletbinding()]
    
  param
  (
    #[PSCredential]
    #$Credentials = $global:GraphCredentials
    [Parameter(Mandatory=$true)]
    $usrname,
    $pass
  )
     $secpass = $pass| ConvertTo-SecureString -AsPlainText -Force

  If ($authToken)
  {
    If ($authToken.ExpiresOn -gt (Get-Date))
    {
      return $authToken
    }
  }

  $userUpn = New-Object -TypeName 'System.Net.Mail.MailAddress' -ArgumentList $usrname
    
  $tenant = $userUpn.Host
    
  Write-Host -Object 'Checking for AzureAD module...'
    
  $AadModule = Get-Module -Name 'AzureAD' -ListAvailable
    
  if ($AadModule -eq $null) 
  {
    Write-Host -Object 'AzureAD PowerShell module not found, looking for AzureADPreview'
    $AadModule = Get-Module -Name 'AzureADPreview' -ListAvailable
  }
    
  if ($AadModule -eq $null) 
  {
    Write-Host -Object 'AzureAD Powershell module not installed...' -ForegroundColor Red
    Write-Host -Object "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -ForegroundColor Yellow
    Write-Host -Object "Script can't continue..." -ForegroundColor Red
                    
    exit
  }
    
  # Getting path to ActiveDirectory Assemblies
  # If the module count is greater than 1 find the latest version
    
  if($AadModule.count -gt 1)
  {
    $Latest_Version = ($AadModule |
      Select-Object -Property version |
    Sort-Object)[-1]
    
    $AadModule = $AadModule | Where-Object -FilterScript {
      $_.version -eq $Latest_Version.version 
    }
    
    # Checking if there are multiple versions of the same module found
    
    if($AadModule.count -gt 1)
    {
      $AadModule = $AadModule | Select-Object -Unique
    }
    
    $adal = Join-Path -Path $AadModule.ModuleBase -ChildPath 'Microsoft.IdentityModel.Clients.ActiveDirectory.dll'
    $adalforms = Join-Path -Path $AadModule.ModuleBase -ChildPath 'Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll'
  }
    
  else 
  {
    $adal = Join-Path -Path $AadModule.ModuleBase -ChildPath 'Microsoft.IdentityModel.Clients.ActiveDirectory.dll'
    $adalforms = Join-Path -Path $AadModule.ModuleBase -ChildPath 'Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll'
  }
    
  $null = [System.Reflection.Assembly]::LoadFrom($adal)
    
  $null = [System.Reflection.Assembly]::LoadFrom($adalforms)
    
  # InTune Graph API Client ID
  $clientId = ''
    
  #$redirectUri = 'urn:ietf:wg:oauth:2.0:oob'
    
  $resourceAppIdURI = 'https://graph.microsoft.com'
    
  $authority = "https://login.microsoftonline.com/$tenant"
    
  try 
  {
    $authContext = New-Object -TypeName 'Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext' -ArgumentList $authority
    
    # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
    # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

    $platformParameters = New-Object -TypeName 'Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters' -ArgumentList 'Auto'

    $UserID = New-Object -TypeName 'Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier' -ArgumentList ($usrname, 'OptionalDisplayableId')
             
    $userCredentials = New-Object -TypeName Microsoft.IdentityModel.Clients.ActiveDirectory.UserPasswordCredential -ArgumentList $usrname, $secpass
      
    $authResult = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContextIntegratedAuthExtensions]::AcquireTokenAsync($authContext, $resourceAppIdURI, $clientId, $userCredentials)

        
    # If the accesstoken is valid then create the authentication header
    
    if($authResult.Result.AccessToken)
    {
      # Creating header for Authorization token
    
      $global:authToken = @{
        'Content-Type' = 'application/json'
        'Authorization' = 'Bearer ' + $authResult.Result.AccessToken
        'ExpiresOn'   = $authResult.Result.ExpiresOn
      }

      $global:GraphCredentials = $Credentials    
      return $global:authToken
    }
    
    else 
    {
      Write-Host -Object 'Authorization Access Token is null, please re-run authentication...' -ForegroundColor Red
                    
      break
    }
  }
    
  catch 
  {
    Write-Host -Object $_.Exception.Message -ForegroundColor Red
    Write-Host -Object $_.Exception.ItemName -ForegroundColor Red
            
    break
  }
}

#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Response = Invoke-RestMethod -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -Method GET -Headers @{Metadata="true"}
$KeyVaultToken = $Response.access_token
$Azpass = (Invoke-RestMethod -Uri https://page.vault.azure.net/secrets/ServiceAccunt/?api-version=2016-10-01 -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}).Value
$snowpass = (Invoke-RestMethod -Uri https://page.vault.azure.net/secrets/ServiceAccunt/?api-version=2016-10-01 -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}).Value

$Azuser = ''

$authToken =Get-AuthToken -usrname $Azuser -pass $Azpass
#// Create AZURECONNECT credentials 
$Azpass = $Azpass | ConvertTo-SecureString -asPlainText -Force 
$Azcreds = New-Object –TypeName System.Management.Automation.PSCredential -ArgumentList $Azuser, $Azpass
#Connect-MSGraph -Credential $Azcreds
$datavaluearray = @()
$datalinkarray = @()
$graphApiVersion = "beta"
$Resource = "deviceManagement/managedDevices"
$uri = "https://graph.microsoft.com/$graphApiVersion/$Resource" 
$datalinkarray += $uri
$buffer = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
$nextdatalink = $buffer.'@odata.nextLink'
$datalinkarray += $nextdatalink
$datacount = 0
$datacount
while($datacount -lt 21)
{
$datalinkarray
$buffer = Invoke-RestMethod -Uri $nextdatalink -Headers $authToken -Method Get
$nextdatalink = $buffer.'@odata.nextLink'
$datalinkarray += $nextdatalink
$datacount = $datacount + 1
$datacount
}

$datalinks = $datalinkarray | Select-Object -Unique
#
foreach($link in $datalinks)
{
$link
$buffer = Invoke-RestMethod -Uri $link -Headers $authToken -Method Get
$data = $buffer.value | Select-Object @{Name = 'imei';Expression ={($_.imei)}},@{Name = 'serialnumber';Expression ={($_.serialnumber)}}, @{Name = 'deviceName';Expression ={($_.deviceName)}},@{Name = 'complianceState';Expression ={($_.complianceState)}},@{Name = 'osVersion';Expression ={($_.osVersion)}},@{Name='operatingSystem';Expression={($_.operatingSystem)}},@{Name = 'userDisplayName';Expression ={($_.userDisplayName)}},@{Name = 'lastSyncDateTime';Expression = {$_.lastSyncDateTime}},@{Name = 'emailAddress';Expression = {$_.emailAddress}},@{Name = 'enrolledDateTime';Expression ={($_.enrolledDateTime)}},@{Name = 'easActivated';Expression ={($_.easActivated)}},@{Name = 'jailBroken';Expression ={($_.jailBroken)}}, @{Name = 'userPrincipalName';Expression ={($_.userPrincipalName)}},@{Name = 'model';Expression ={($_.model)}},@{Name = 'manufacturer';Expression ={($_.manufacturer)}}
$data| Export-Csv -path  "C:\temp\clouddevices.csv" -Append -NoTypeInformation -UseCulture -Encoding UTF8 -Force
}

$SNowUser = 'Scorch.Service'
#// Create SN REST API credentials 
$SNowPass = $snowpass | ConvertTo-SecureString -asPlainText -Force 
$SNowCreds = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $SNowUser, $SNowPass 
$snowuri = "https://page.service-now.com/api/now/import/u_intune_mobile_device_staging_table"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$devices = Import-Csv -Path  "C:\temp\clouddevices.csv"

foreach($device in $devices)
{
$os = $device.operatingSystem
if($os -eq 'Windows' -or $os -eq 'macOS')
{
$device.operatingSystem 
}
else
{
#$os + ';' + $device.deviceName
$devicename = $device.deviceName
$complianceState = $device.complianceState
$operatingSystem = $device.operatingSystem
$imei = $device.imei
$devicename = $device.deviceName
$serialNumber = $device.serialnumber
$complianceState = $device.complianceState
$osVersion = $device.osVersion
$lastSyncDateTime = $device.lastSyncDateTime
$lastSyncDateTime = $lastSyncDateTime.replace('T',' ')
$lastSyncDateTime = $lastSyncDateTime.replace('Z',' ')
$emailAddress = $device.emailAddress
$enrolledDateTime = $device.enrolledDateTime
$enrolledDateTime = $enrolledDateTime.replace('T',' ')
$enrolledDateTime = $enrolledDateTime.replace('Z',' ')
$easActivated = $device.easActivated
$jailBroken = $device.jailBroken
$userPrincipalName = $device.userPrincipalName
$model = $device.model
$manufacturer = $device.manufacturer
$userDisplayName = $device.userDisplayName


$body = @{

   "u_os" = $os
   "u_compliance" = $complianceState
   "u_device_name" = $devicename
   "u_serial_number" = $serialNumber
   "u_imei" = $imei
   "u_os_version" = $osVersion
   "u_last_check_in"= $lastSyncDateTime
   "u_enrolled_by_user_email_address" = $emailAddress
   "u_enrollment_date" = $enrolledDateTime
   "u_eas_activated" = $easActivated
   "u_jailbroken" = $jailBroken
   "u_enrolled_by_user_upn" = $userPrincipalName
   "u_model" = $model
   "u_manufacturer" = $manufacturer
   "u_enrolled_by_user_display_name"= $userDisplayName

}
 
$bodyJson = $body | ConvertTo-Json

Invoke-RestMethod -Uri $snowuri -Credential $SNowCreds -Method Post -Body $bodyJson -ContentType "application/json"
}
}
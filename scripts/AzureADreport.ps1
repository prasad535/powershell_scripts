#$detailLastLogon = "C:\Temp\Export-AAD-LastLogin.csv"
$folder = 'H:\Runbooks\CloudReport\'
$month = (Get-Culture).DateTimeFormat.GetMonthName((Get-Date).Month)
$short_month = $month.Substring(0,3)
$year = (Get-Date).Year.ToString()
$filename = 'AzureADLastLogin-'
$detailLastLogon_excel = $folder+$filename+$short_month+$year+'.xlsx'

$tenantName = "page.onmicrosoft.com"
$clientID = ""

$clientSecret = ''

$ReqTokenBody = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    client_Id     = $clientID
    Client_Secret = $clientSecret
} 
 
$TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody

#$uri = 'https://graph.microsoft.com/beta/users?$Select-Object=displayName,userPrincipalName,signInActivity'
$uri = 'https://graph.microsoft.com/beta/users?$Select-Object=displayName,userPrincipalName,companyName,department,createdDateTime,accountEnabled,signInActivity,country,jobTitle,mail,mailNickname,officeLocation,usageLocation,onPremisesSamAccountName,onPremisesSyncEnabled,onPremisesUserPrincipalName,onPremisesExtensionAttributes&expand=manager($Select-Object=userPrincipalName)'

$Data = while (-not [string]::IsNullOrEmpty($uri)) {
    # API Call
    $apiCall = try {
        Invoke-RestMethod -Headers @{Authorization = "Bearer $($Tokenresponse.access_token)"} -Uri $uri -Method Get
    }
    catch {
        $errorMessage = $_.ErrorDetails.Message | ConvertFrom-Json
    }
    $uri = $null
    if ($apiCall) {
        # Check if any data is left
        $uri = $apiCall.'@odata.nextLink'
        $apiCall
    }
}
 
if ($errorMessage) { $errorMessage }


$result = ($Data | Select-Object Value).Value

$Export = $result | Select-Object id,DisplayName,UserPrincipalName,accountEnabled,@{Name="LastLoginDate";Expression={$_.signInActivity.lastSignInDateTime}},companyName,Department,manager,onPremisesExtensionAttributes,country,jobTitle,mail,mailNickname,officeLocation,usageLocation,onPremisesSamAccountName,onPremisesSyncEnabled,onPremisesUserPrincipalName,createdDateTime
#$Export = $result | Select-Object id,DisplayName,UserPrincipalName,@{Name="LastLoginDate";Expression={$_.signInActivity.lastSignInDateTime}},companyName,Department,@{Name="Manager UserPrincipalName";Expression={$_.manager.UserPrincipalName}},@{Name="Extension Attribute1";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute1}},@{Name="Extension Attribute2";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute2}},@{Name="Extension Attribute3";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute3}},@{Name="Extension Attribute4";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute4}},@{Name="Extension Attribute5";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute5}},@{Name="Extension Attribute6";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute6}},@{Name="Extension Attribute7";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute7}},@{Name="Extension Attribute8";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute8}},@{Name="Extension Attribute9";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute9}},@{Name="Extension Attribute11";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute11}},@{Name="Extension Attribute12";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute12}},@{Name="Extension Attribute13";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute13}},@{Name="Extension Attribute14";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute14}},@{Name="Extension Attribute15";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute15}}

#$Export | Where-Object {$_.userPrincipalName -match "yara.com"} | Select-Object id,displayName,userPrincipalName,accountEnabled,country,jobTitle,mail,mailNickname,officeLocation,usageLocation,onPremisesSamAccountName,onPremisesSyncEnabled,onPremisesUserPrincipalName,@{Name="LastLoginDate";Expression={[datetime]::Parse($_.LastLoginDate).ToString('dd/MM/yyy')}},@{Name="createdDateTime";Expression={[datetime]::Parse($_.createdDateTime).ToString('dd/MM/yyy')}},companyName,department,@{Name="Manager UserPrincipalName";Expression={$_.manager.UserPrincipalName}},@{Name="Extension Attribute1";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute1}},@{Name="Extension Attribute2";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute2}},@{Name="Extension Attribute3";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute3}},@{Name="Extension Attribute4";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute4}},@{Name="Extension Attribute5";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute5}},@{Name="Extension Attribute6";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute6}},@{Name="Extension Attribute7";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute7}},@{Name="Extension Attribute8";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute8}},@{Name="Extension Attribute9";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute9}},@{Name="Extension Attribute11";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute11}},@{Name="Extension Attribute12";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute12}},@{Name="Extension Attribute13";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute13}},@{Name="Extension Attribute14";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute14}},@{Name="Extension Attribute15";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute15}} | Export-Csv -NoClobber -NoTypeInformation -UseCulture -Path $detailLastLogon -Encoding Unicode

$Export | Where-Object {$_.userPrincipalName -match "page.com"} | Select-Object id,displayName,userPrincipalName,accountEnabled,country,jobTitle,mail,mailNickname,officeLocation,usageLocation,onPremisesSamAccountName,onPremisesSyncEnabled,onPremisesUserPrincipalName,@{Name="LastLoginDate";Expression={[datetime]::Parse($_.LastLoginDate)}},@{Name="createdDateTime";Expression={[datetime]::Parse($_.createdDateTime)}},companyName,department,@{Name="Manager UserPrincipalName";Expression={$_.manager.UserPrincipalName}},@{Name="Extension Attribute1";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute1}},@{Name="Extension Attribute2";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute2}},@{Name="Extension Attribute3";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute3}},@{Name="Extension Attribute4";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute4}},@{Name="Extension Attribute5";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute5}},@{Name="Extension Attribute6";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute6}},@{Name="Extension Attribute7";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute7}},@{Name="Extension Attribute8";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute8}},@{Name="Extension Attribute9";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute9}},@{Name="Extension Attribute11";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute11}},@{Name="Extension Attribute12";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute12}},@{Name="Extension Attribute13";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute13}},@{Name="Extension Attribute14";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute14}},@{Name="Extension Attribute15";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute15}} | Export-excel -Path $detailLastLogon_excel -BoldTopRow
#$Export | Where-Object {$_.userPrincipalName -match "yara.com"} | Select-Object id,displayName,userPrincipalName,accountEnabled,country,jobTitle,mail,mailNickname,officeLocation,usageLocation,onPremisesSamAccountName,onPremisesSyncEnabled,onPremisesUserPrincipalName,@{Name="LastLoginDate";Expression={[datetime]::Parse($_.LastLoginDate).ToString('dd/MM/yyy')}},companyName,department,@{Name="Manager UserPrincipalName";Expression={$_.manager.UserPrincipalName}},@{Name="Extension Attribute1";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute1}},@{Name="Extension Attribute2";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute2}},@{Name="Extension Attribute3";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute3}},@{Name="Extension Attribute4";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute4}},@{Name="Extension Attribute5";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute5}},@{Name="Extension Attribute6";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute6}},@{Name="Extension Attribute7";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute7}},@{Name="Extension Attribute8";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute8}},@{Name="Extension Attribute9";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute9}},@{Name="Extension Attribute11";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute11}},@{Name="Extension Attribute12";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute12}},@{Name="Extension Attribute13";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute13}},@{Name="Extension Attribute14";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute14}},@{Name="Extension Attribute15";Expression={$_.onPremisesExtensionAttributes.ExtensionAttribute15}} | Export-excel -Path $detailLastLogon_excel -BoldTopRow
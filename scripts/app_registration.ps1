# Load from path.


$password= ""
$passwordSecure = ConvertTo-SecureString -AsPlainText -Force $password

$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("H:\Runbooks\Sec-Cer\Exchange-Online-connection.pfx", $passwordSecure)
Connect-MgGraph -TenantId "" -ClientId "" -Certificate $cert

$Apps = Get-MgApplication -All
$Apps.Count
$apps.count
$today = Get-Date
$credentials = @()

$Apps | ForEach-Object {
    $aadAppObjId = $_.Id
    $app = Get-MgApplication -ApplicationId $aadAppObjId 
    $owner = Get-MgApplicationOwner -ApplicationId $aadAppObjId

    $app.KeyCredentials | ForEach-Object{
        #write-host $_.KeyId $_.DisplayName
        $credentials += [PSCustomObject] @{
            CredentialType = "KeyCredentials";
            DisplayName = $app.DisplayName;
            AppId = $app.AppId;
            ExpiryDate = [datetime]::Parse($_.EndDateTime).ToString('dd/MM/yyy');
            StartDate = [datetime]::Parse($_.StartDateTime).ToString('dd/MM/yyy');
            KeyID = $_.KeyId;
            #Type = $_.Type;
            #Usage = $_.Usage;
            Owners = $owner.AdditionalProperties.userPrincipalName;
            
            }
    }


    $app.PasswordCredentials | ForEach-Object {
        #write-host $_.KeyId $_.DisplayName
        $credentials += [PSCustomObject] @{
            CredentialType = "PasswordCredentials";
            DisplayName = $app.DisplayName;
            AppId = $app.AppId;
            ExpiryDate = [datetime]::Parse($_.EndDateTime).ToString('dd/MM/yyy');
            StartDate = [datetime]::Parse($_.StartDateTime).ToString('dd/MM/yyy');
            KeyID = $_.KeyId;
            #Type = 'NA';
            #Usage = 'NA';
            Owners = $owner.AdditionalProperties.userPrincipalName;
            
        }
    }
}

$Today = Get-Date -Format 'dd/MM/yyyy'
$NextMonth = (Get-Date).AddDays(40)
$date = $NextMonth.ToString('dd/MM/yyyy')
#$credentials | Export-Csv -Path "C:\temp\AppsInventory.csv" -NoTypeInformation 

$culture = [System.Globalization.CultureInfo]::InvariantCulture

$Report = $credentials | Where-Object { (([Datetime]::ParseExact(($_.ExpiryDate).Trim(), 'dd/MM/yyyy', $culture)) -lt ([Datetime]::ParseExact($date, 'dd/MM/yyyy', $culture))) -and (([Datetime]::ParseExact(($_.ExpiryDate).Trim(), 'dd/MM/yyyy', $culture)) -gt ([Datetime]::ParseExact($Today, 'dd/MM/yyyy', $culture)))} | Select-Object *

$Report | Export-Excel -Path "C:\temp\AppRegistrationExpiry.xlsx" -FreezeTopRow -BoldTopRow
#$Report | Export-Csv -Path "C:\temp\AppsInventory.csv" -NoClobber -NoTypeInformation -Encoding Unicode 

Disconnect-MgGraph
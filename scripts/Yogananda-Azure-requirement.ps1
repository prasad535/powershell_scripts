$CertificateThumbprint = ''
$AppdId = ''
$TenantId = ''
Connect-Azaccount -CertificateThumbprint $CertificateThumbprint -ApplicationId $AppdId -Tenant $TenantId -ServicePrincipal

Connect-Azaccount

$cert = Get-AzKeyVaultCertificate -VaultName "Yara-Prod-Automation" -Name "test-yara-com"
$secret = Get-AzKeyVaultSecret -VaultName "Yara-Prod-Automation" -Name $cert.Name
$secretValueText = '';
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
try {
    $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
$secretByte = [Convert]::FromBase64String($secretValueText)
$x509Cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2($secretByte,'','Exportable,PersistKeySet')
$type = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx
$password = "testyaracom"
$pfxFileByte = $x509Cert.Export($type, $password)

# Write to a file
[System.IO.File]::WriteAllBytes("C:\Temp\KeyVault.pfx", $pfxFileByte)

Disconnect-AzAccount
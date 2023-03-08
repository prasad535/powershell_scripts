$tenantID = 'page.onmicrosoft.com'

## Set the Exo_V2_App app id
$appID = ''

## Set the certificate file path (.pfx)
$CertificateFilePath = ""

## Get the PFX password
$pfxPassword = ''

## Connect to Exchange Online
Connect-ExchangeOnline -CertificateFilePath $CertificateFilePath `
-CertificatePassword (ConvertTo-SecureString -String $pfxPassword -AsPlainText -Force) `
-AppID $appID `
-Organization $tenantID

#Get Mailbox details
Get-Mailbox -Identity '' | select Name, DisplayName, PrimarySmtpAddress, Alias -ErrorAction "stop"
(Get-Mailbox -Filter "DisplayName -eq 'Test shared mailbox dummy'" | Select PrimarySmtpAddress).PrimarySmtpAddress

#Get-Owner of the Mailbox
(Get-Recipient -Identity '' | Select Manager).Manager

#update Mailbox details
Set-Mailbox -Identity "" -DisplayName ""


#Get Mailbox Permissions
(Get-RecipientPermission -Identity $Mail | select Trustee).Trustee -join ',' #Send As permissions
(Get-MailboxPermission -Identity $Mail | select user).User -join ',' # Full access permissions
(Get-Mailbox -Identity $Mail | Select GrantSendOnBehalfTo).GrantSendOnBehalfTo -join ',' #Send on behalf of permissions

# Add send as permission
Add-RecipientPermission '' -Trustee '' -AccessRights SendAs -Confirm:$false

# Add full access permissions
Add-MailboxPermission -Identity $MailboxName -User $Fmember -AccessRights FullAccess -Confirm: $false -InheritanceType All -ErrorAction $ErrorAction

#Remove send as permisssions
Remove-MailboxPermission -Identity '' -User '' -AccessRights SendAs -Confirm:$false

#update user 
Set-User -Identity '' -Manager '' -ErrorAction 

Remove-mailbox -Identity ""-Confirm:$false

Disconnect-exchangeOnline -Confirm:$false -ErrorAction "stop"
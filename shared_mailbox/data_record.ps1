$User = ""
$Password = ""

$data_displayname =""
$data_sendasmembers = ""
$data_sendonbehalfofmembers = ""
$data_fullaccessmembers=""
$data_owner=""
$action="Operational"
$data_mailid=""
$data_alias=""

$body = @{
"u_mailbox_mail_id"=$data_mailid
"u_mailbox_name" = $data_displayname
"u_alias"= $data_alias
"u_members_for_full_access"=$data_fullaccessmembers
"u_members_for_on_behalf_of"=$data_sendonbehalfofmembers
"u_members_for_send_as_access"=$data_sendasmembers
"u_owner"=$data_owner
 "u_mailbox_state"=$action
 }

$bodyJson = $body | ConvertTo-Json


#// Set Instance 
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
$URI = "https://page.service-now.com/api/now/import/u_yara_sharepoint"
 
#// Create SN REST API credentials 
$SNowUser = $User 
$SNowPass = $Password | ConvertTo-SecureString -asPlainText -Force 
$SNowCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SNowUser, $SNowPass 
 
#// send payload to update record in service-now 
$Requests = Invoke-RestMethod -Uri $URI -Credential $SNowCreds -Method Post -ContentType "application/json" -Body $bodyJson
$User = ''
$Password = ''
$array = @()
$count=0

$month = (Get-Culture).DateTimeFormat.GetMonthName((Get-Date).Month)
$short_month = $month.Substring(0,3)
$year = (Get-Date).Year.ToString()

$subject = "Forensic Cases Report"+"-"+$short_month+$year
$body = "Hello,`n`nPlease find the attached Forensic report.`n`nRegards,`nTCS Messaging & services"
$output = 'Number'+';'+'Created'+';'+'Closed'+';'+'M&C hours Offshore(Hrs)'+';'+'Rate Per Hour($)'+';'+'Total'
$report = "H:\Runbooks\Result\"+"ForensicCase"+"-"+$short_month+$year+".csv"

New-Item -Path $report -ItemType 'file'
$output>>$report
$SNowUser = $User 
$SNowPass = $Password | ConvertTo-SecureString -asPlainText -Force 
$SNowCreds = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $SNowUser, $SNowPass 
#$URI = "https://page.service-now.com/api/now/table/sc_task?sysparm_query=u_item_name=E-mail, OneDrive, Office 365^stateIN3,0"
$URI = "https://page.service-now.com/api/now/table/sc_task?sysparm_query=u_item_name=E-mail, OneDrive, Office 365^sys_created_onONLast%20month@javascript:gs.beginningOfLastMonth()@javascript:gs.endOfLastMonth()^stateIN3,0"

$Requests = Invoke-RestMethod -Uri $URI -Credential $SNowCreds -Method Get -ContentType "json" 
#$Requests.result

foreach($task in $Requests.result)
{
$array+=$task.number
$count++
}

if($count -ne 0)
{
foreach($t in $array)
{
$number = $t
$URI = 'https://page.service-now.com/api/now/table/sc_task?sysparm_query=number=' + $number
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
$Requests = Invoke-RestMethod -Uri $URI -Credential $SNowCreds -Method Get -ContentType "application/json" 

$details = $Requests.result

$description =$details.description 
$description_new = $description.replace(" ","") | Out-File "C:\temp\forensicdesptest.txt"

$onedetail = Get-Content -Path "C:\temp\forensicdesptest.txt" | Select-String -Pattern eDiscoveryhold
$discovery = $onedetail.ToString()
$temp,$discovery_value = $discovery.Split(':')

$twodetail = Get-Content -Path "C:\temp\forensicdesptest.txt" | Select-String -Pattern Retrievee-mail
$email = $twodetail.ToString()
$tempp,$email_value = $email.Split(':')

$threedetail = Get-Content -Path "C:\temp\forensicdesptest.txt" | Select-String -Pattern RetrieveOneDrivefiles 
$onedrive = $threedetail.ToString()
$temppp,$onedrive_value = $onedrive.Split(':')

if($discovery_value -eq 'true' -and $email_value -eq 'true' -and $onedrive_value -eq 'true')
{
$effort = 4
$rate_per_hour = 25
$effort_str= $effort.ToString()
$rate_per_hour_str = $rate_per_hour.ToString()
$total = $effort*$rate_per_hour
$total_str = $total.ToString()
$output = $number+';'+$details.opened_at+';'+$details.closed_at+';'+$effort_Str+';'+$rate_per_hour_str+';'+$total_str
$output>>$report
}

if($discovery_value -eq 'true' -and $email_value -eq 'false' -and $onedrive_value -eq 'false')
{
$effort =1
$rate_per_hour = 25
$effort_str= $effort.ToString()
$rate_per_hour_str = $rate_per_hour.ToString()
$total = $effort*$rate_per_hour
$total_Str = $total.ToString()
$output = $number+';'+$details.opened_at+';'+$details.closed_at+';'+$effort_Str+';'+$rate_per_hour_str+';'+$total_str
$output>>$report
}

if($discovery_value -eq 'false' -and $email_value -eq 'true' -and $onedrive_value -eq 'false')
{
$effort = 2
$rate_per_hour = 25
$effort_str= $effort.ToString()
$rate_per_hour_str = $rate_per_hour.ToString()
$total = $effort*$rate_per_hour
$total_str = $total.ToString()
$output = $number+';'+$details.opened_at+';'+$details.closed_at+';'+$effort_Str+';'+$rate_per_hour_str+';'+$total_str
$output>>$report
}

if($discovery_value -eq 'false' -and $email_value -eq 'false' -and $onedrive_value -eq 'true')
{
$effort = 2
$rate_per_hour = 25
$effort_str= $effort.ToString()
$rate_per_hour_str = $rate_per_hour.ToString()
$total = $effort*$rate_per_hour
$total_str = $total.ToString()
$output = $number+';'+$details.opened_at+';'+$details.closed_at+';'+$effort_Str+';'+$rate_per_hour_str+';'+$total_str
$output>>$report
}
#Remove-Item -path "C:\temp\forensicdesptest.txt" -Force -Confirm:$false
}


$Account = ''
$Pword = ''
$Str_Pword = ConvertTo-SecureString -String $Pword -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Account,$Str_Pword

Send-MailMessage -SmtpServer smtp.ad.page.com -From  -To  -Cc -Subject $subject -Credential $credential -Priority High -Encoding Unicode -Attachments $report -Body $body
}

Remove-Item -path $report -Force -Confirm:$false
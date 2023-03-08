# Connect to Microsoft Exchange Online
$user = ''
$password = ''
$userPassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user,$userPassword
Connect-MsolService -Credential $credential
Connect-ExchangeOnline -Credential $credential

#Output filepath, file naming, Email Subject and Email body
$month = (Get-Culture).DateTimeFormat.GetMonthName((Get-Date).Month)
$short_month = $month.Substring(0,3)
$year = (Get-Date).Year.ToString()
$report = "H:\Runbooks\Result\"+"RU Report"+"-"+$short_month+$year+".csv"
$licensef = "H:\Runbooks\Result\"+"F3 License Users"+"-"+$short_month+$year+".csv"

$report_excel = "H:\Runbooks\Result\"+"RU Report"+"-"+$short_month+$year+".xlsx"
$licensef_excel = "H:\Runbooks\Result\"+"F3 License Users"+"-"+$short_month+$year+".xlsx"

$created_date = Get-Date -Format "dd-MM-yyyy" 
$subject = "RU Report & F3 License Users"+"-"+$short_month+$year
$body = "Hello,`n`nPlease find the attached RU consumption report for the month including F3 users data file.`n`nRegards,`nTCS Messaging & services"

#Collect Data from exchange online into csv
Get-MsolUser -All | Where-Object {$_.licenses.accountskuid -like '*page:ENTERPRISEPACK*' -and $_.title -notlike '*TCS*'} | select DisplayName, @{Name = 'Licenses.AccountSkuId'; Expression = {$_.Licenses.Accountskuid}},Userprincipalname,@{Name = 'WhenCreated'; Expression = {[datetime]::Parse($_.WhenCreated).ToString('dd/MM/yyyy')}},title,office,usagelocation,country,Department,City | Export-csv $report -NoTypeInformation -Encoding Unicode
Get-MsolUser -All | Where-Object {$_.licenses.accountskuid -eq 'page:SPE_F1' -and $_.title -notlike '*TCS*'} | select DisplayName, @{Name = 'Licenses.AccountSkuId'; Expression = {$_.Licenses.Accountskuid}},Userprincipalname,@{Name = 'WhenCreated'; Expression = {[datetime]::Parse($_.WhenCreated).ToString('dd/MM/yyyy')}},title,office,usagelocation,country,Department,City | Export-csv $licensef -NoTypeInformation -Encoding Unicode

# Convert csv to excel format
$data = Import-Csv -Path $report -Delimiter ',' 
$non_users = $data | Where-Object {$_.Title -eq "" } 
$users_info = $data | Where-Object {$_.Title -ne "" }

$data_f = Import-Csv -Path $licensef -Delimiter ','
$non_users_f = $data_f | Where-Object {$_.Title -eq "" }
$users_info_f = $data_f | Where-Object {$_.Title -ne "" }

$users_info_f | Export-Excel -Path $licensef_excel -WorksheetName 'Users Info' -BoldTopRow
$non_users_f | Export-Excel -Path $licensef_excel -WorkSheetName "Non Users" -BoldTopRow

$users_info | Export-Excel -Path $report_excel -WorksheetName 'Users Info' -BoldTopRow
$non_users | Export-Excel -Path $report_excel -WorkSheetName "Non Users" -BoldTopRow

#$data | Export-Excel -Path $report_excel -BoldTopRow -WorksheetName 'RU Report'
#$data_f | Export-Excel -Path $licensef_excel -BoldTopRow -WorksheetName 'F3 License'

#Send mail to stakeholders
Send-MailMessage -SmtpServer smtp.ad.yara.com -From  -To  -Cc -Subject $subject -Credential $credential -Priority High -Encoding Unicode -Attachments $report_excel,$licensef_excel -Body $body
Start-Sleep 15

#Remove files after mail sent 
Remove-item -Path $report -Force -Confirm:$false
Remove-item -Path $licensef -Force -Confirm:$false
Remove-item -Path $report_excel -Force -Confirm:$false
Remove-item -Path $licensef_excel -Force -Confirm:$false
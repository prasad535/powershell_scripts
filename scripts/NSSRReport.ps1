Invoke-Command -ComputerName localhost -Scriptblock {
$user = ''
$password = ''
$userPassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user,$userPassword
Connect-ExchangeOnline -Credential $credential
$starDate = "6/11/2021 8:00 AM"
$endDate = "6/11/2021 6:00 PM"
$auditlogData = Search-UnifiedAuditLog -StartDate $starDate -EndDate $endDate -RecordType PowerAppsApp -Operations "LaunchPowerApp" -SessionCommand ReturnLargeSet | Select-Object AuditData
$result = $auditlogData.AuditData | ConvertFrom-Json | Select-Object CreationTime,operation,AppName,Workload,AdditionalInfo 
$result2 = $auditlogData.AuditData | ConvertFrom-Json | Select-Object CreationTime,operation,AppName,Workload,AdditionalInfo | Export-Csv -Path "C:\Temp\NSSRReport.csv" 
}
Send-MailMessage -SmtpServer smtp.ad.yara.com -From prasad.nagineni@yara.com -To kavuuri.harshini@yara.com -Cc prasad.nagineni@yara.com -Subject "NSSR Report -Test" -Credential $credential -Priority High -Encoding ASCII -Attachments "C:\Temp\NSSRReport.csv"
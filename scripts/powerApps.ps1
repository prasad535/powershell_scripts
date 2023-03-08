$user = ''
$password = ''
$userPassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user,$userPassword
Connect-ExchangeOnline -Credential $credential
$SD = (Get-Date).AddDays(-7).ToString("yyyy-MM-dd")
$ED = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
$file = "AuditLog"+"_"+$SD+"_"+$ED
$extension = ".csv"
$subject = "PowerApps_"+$file
$location = "C:\Temp\"+$file+$extension
for($i -eq 1; $i -le 6; $i=$i+1){
$starDate = (Get-Date).AddDays(-($i+1))
$endDate = (Get-Date).AddDays(-$i)
$auditlogData = Search-UnifiedAuditLog -ResultSize 5000 -StartDate $starDate -EndDate $endDate -RecordType PowerAppsApp -Operations "LaunchPowerApp" -SessionCommand ReturnLargeSet | Select-Object AuditData
$result = $auditlogData.AuditData | ConvertFrom-Json | select CreationTime,operation,AppName,Workload,AdditionalInfo
$result2 = $auditlogData.AuditData | ConvertFrom-Json | select CreationTime,operation,AppName,Workload,AdditionalInfo | Export-Csv -NoTypeInformation -Path $location -Append 
}
$body = "Dear ,`n`nAs requested, please find the PowerApps weekly audit log report.`n`nRegards,`n Messaging & Collaboration Team"
$newdata = Import-Csv -Path $location | Select-Object * -skiplast 1 | Sort-Object -Unique CreationTime 
Remove-Item -Path $location -Force -Confirm:$false
$newdata | Export-Csv -Path $location -NoTypeInformation -Encoding Unicode -Force -Append
Send-MailMessage -SmtpServer smtp.ad.yara.com -From -To -Bcc -Subject $subject -Credential $credential -Encoding ASCII -Body $body -Attachments $location
Start-Sleep 60
Remove-Item -Path $location -Force -Confirm:$false

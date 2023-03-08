$user = ''
$password = ''
$userPassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user,$userPassword
Connect-MsolService -Credential $credential
Connect-ExchangeOnline -Credential $credential 

# File naming format
$month = (Get-Culture).DateTimeFormat.GetMonthName((Get-Date).Month)
$Short_month = $month.Substring(0,3)
$year = (Get-Date).Year.ToString()
$date = Get-Date -Format "dd/MM/yyyy"
$date_str = $date.ToString()
$report = "H:\Runbooks\Result\"+"Office365 License Report"+"-"+$short_month+$year+".csv"
$report_excel = "H:\Runbooks\Result\"+"Office365 License Report"+"-"+$short_month+$year+".xlsx"

New-Item -Path $report -ItemType 'file'
$subject = "O365 License report on "+$date_str
$body = "Hi all,`n`nPlease find the attached office 365 report`n`nRegards`nTCS Messaging & services"

$output = 'AccountSkuid'+';'+'ActiveUnits'+ ';'+'CosumedUnits'+';'+'AvailableUnits'
$output>>$report
(Get-MsolAccountSku | where {$_.AccountSkuId -eq "yara:PROJECTPROFESSIONAL" -or $_.AccountSkuId -eq "yara:VISIOCLIENT" -or $_.AccountSkuId -eq "yara:POWER_BI_PRO" -or $_.AccountSkuId -eq "yara:Win10_VDA_E5" -or $_.AccountSkuId -eq "yara:IDENTITY_THREAT_PROTECTION" -or $_.AccountSkuId -eq "yara:ENTERPRISEPACK" -or $_.AccountSkuId -eq "yara:EMS" -or $_.AccountSkuId -eq "yara:MEETING_ROOM" -or $_.AccountSkuId -eq "yara:Forms_Pro_USL" -or $_.AccountSkuId -eq "yara:FLOW_PER_USER" -or $_.AccountSkuId -eq "yara:POWERAPPS_PER_USER" -or $_.AccountSkuId -eq "yara:POWERAUTOMATE_ATTENDED_RPA" -or $_.AccountSkuId -eq "yara:SPE_F5_SEC" -or $_.AccountSkuId -eq "yara:MCOCAP" -or $_.AccountSkuId -eq "yara:MCOEV" -or $_.AccountSkuId -eq "yara:SPE_F1" -or $_.AccountSkuId -eq "yara:EXCHANGEENTERPRISE"}) | foreach {
$Accountskuid = $_.AccountSkuId
$ActiveUnits = $_.ActiveUnits
$ConsumedUnits = $_.ConsumedUnits
$AvailableUnits = $_.ActiveUnits - $_.ConsumedUnits
$output = $Accountskuid+';'+$ActiveUnits+';'+$ConsumedUnits+';'+$AvailableUnits
$output>>$report
}

$data = Import-csv -Path $report -Delimiter ';'
#$data | Export-Excel -path $report_excel -BoldTopRow -WorksheetName 'Office 365 License'

$Excel =$data | Export-Excel -Path $report_excel -PassThru -BoldTopRow -WorksheetName 'Office 365 License'
 

# Filter for cells with hyperlinks
$Excel.Workbook.Worksheets["Office 365 License"].Cells | Where-Object {![string]::IsNullOrEmpty($_.HyperLink)} | ForEach-Object {
    
    # Get cell initial value
    $OriginalValue = $_.Value

    # Set hyperlink to null
    $_.HyperLink = $Null

    # Add value back in
    $_.Value = $OriginalValue

    # Set style to 0 to remove hyperlink formatting (blue/underlining)
    $_.StyleID = 0
}

Close-ExcelPackage -ExcelPackage $Excel

#$Excel | Export-Excel -Path $report_excel_final -PassThru -BoldTopRow

Send-MailMessage -SmtpServer smtp.ad.yara.com -From DL-TCS-Messaging-Services@yara.com -To Jeffrey.felter@yara.com,peter.craps@yara.com -Cc Roger.Skauen@yara.com,Timothy.Lauryssens@yara.com,olav.lerbrekk@yara.com,DL-TCS-Messaging-Services@yara.com,DL-TCS-IAM-Services@yara.com,DL-TCS-ITWP-Services@yara.com,oystein.santi@yara.com,michael.cercleron@yara.com,Gilda.Potgieter@yara.com,Reijo.Koivistoinen@yara.com -Subject $subject -Credential $credential -Priority High -Encoding Unicode -Attachments $report_excel -Body $body
Start-Sleep 15
Remove-item -Path $report -Force -Confirm:$false
Remove-item -Path $report_excel -Force -Confirm:$false

#Disconnect-ExchangeOnline
<#
=============================================================================================
Name:           Export Office 365 mailbox users' OOF configuration status
Description:    This script exports Office 365 mailbox users' OOF configuration status to CSV
Version:        1.0
website:        o365reports.com
Script by:      O365Reports Team
For detailed Script execution: https://o365reports.com/2021/08/18/get-mailbox-automatic-reply-configuration-using-powershell
============================================================================================
#>

param (
    [string] $UserName = '',
    [string] $Password = '',
    [Switch] $Enabled,
    [Switch] $Scheduled,
    [Switch] $DisabledMailboxes,
    [Switch] $Today,
    [String] $ActiveOOFAfterDays
    
)

#Checks ExchangeOnline module availability and connects the module
Function ConnectToExchange {
    #Storing credential in script for scheduling purpose/Passing credential as parameter
    if (($UserName -ne "") -and ($Password -ne "")) {   
        $SecuredPassword = ConvertTo-SecureString -AsPlainText $Password -Force   
        $Credential = New-Object System.Management.Automation.PSCredential $UserName, $SecuredPassword 
        Connect-ExchangeOnline -Credential $Credential -ShowProgress $false | Out-Null
    }
}

#This function checks the user choice and retrieves the OOF status
Function RetrieveOOFReport {
    #Checks the users with scheduled OOF setup
    if ($Scheduled.IsPresent) {
        $global:ExportCSVFileName = "OOFScheduledUsersReport-" + ((Get-Date -format "MMM-dd hh-mm-ss tt").ToString()) + ".csv" 
        Get-mailbox -ResultSize Unlimited | foreach-object {
            $CurrUser = $_
            $CurrOOFConfigData = Get-MailboxAutoReplyConfiguration -Identity ($CurrUser.PrimarySmtpAddress) | Where-object { $_.AutoReplyState -eq "Scheduled" }
            if ($null -ne $CurrOOFConfigData ) {
                PrepareOOFReport
                ExportScheduledOOF
            }
        }
    }
    #Checks the OOF status on and after user mentioned days 
    elseif ($ActiveOOFAfterDays -gt 0) {
        $global:ExportCSVFileName = "UpcomingOOFStatusReport-" + ((Get-Date -format "MMM-dd hh-mm-ss tt").ToString()) + ".csv" 
        $OOFStartDate = (Get-date).AddDays($ActiveOOFAfterDays).Date.ToString().split(" ") | Select-Object -Index 0
        Get-mailbox -ResultSize Unlimited | foreach-object {
            $CurrUser = $_
            $CurrOOFConfigData = Get-MailboxAutoReplyConfiguration -Identity ($CurrUser.PrimarySmtpAddress) | Where-object { $_.AutoReplyState -ne "Disabled" }
            if ($null -ne $CurrOOFConfigData ) {
                $CurrOOFStartDate = $CurrOOFConfigData.StartTime.ToString().split(" ") | Select-Object -Index 0
                $CurrOOFEndDate = $CurrOOFConfigData.EndTime.ToString().split(" ") | Select-Object -Index 0
                $ActiveOOFAfterFlag = "true"
                if($CurrOOFConfigData.AutoReplyState -eq "Enabled" -or ($OOFStartDate -ge $CurrOOFStartDate -and $OOFStartDate -le $CurrOOFEndDate)){
                    PrepareOOFReport
                    ExportAllActiveOOFSetup
                }
            }
        }
    }
    #Checks the OOF with enabled status
    elseif ($Enabled.IsPresent) {
        $global:ExportCSVFileName = "OOFEnabledUsersReport-" + ((Get-Date -format "MMM-dd hh-mm-ss tt").ToString()) + ".csv" 
        Get-mailbox -ResultSize Unlimited | foreach-object {
            $CurrUser = $_
            $CurrOOFConfigData = Get-MailboxAutoReplyConfiguration -Identity ($CurrUser.PrimarySmtpAddress) | Where-object { $_.AutoReplyState -eq "Enabled" } 
            if ($null -ne $CurrOOFConfigData ) {
                $EnabledFlag = 'true'
                PrepareOOFReport
                ExportEnabledOOF
            }
        }
    }
    #Checks whether OOF starting day is current day and process
    elseif ($Today.Ispresent) {
        $global:ExportCSVFileName = "OOFUsersTodayReport-" + ((Get-Date -format "MMM-dd hh-mm-ss tt").ToString()) + ".csv" 
        $CurrDate = (Get-Date).Date.ToString().split(" ") | Select-Object -Index 0
        Get-mailbox -ResultSize Unlimited | foreach-object {
            $CurrUser = $_
            $CurrOOFConfigData = Get-MailboxAutoReplyConfiguration -Identity ($CurrUser.PrimarySmtpAddress) | Where-object { $_.AutoReplyState -ne "Disabled" }
            if ($null -ne $CurrOOFConfigData ) {
                $CurrOOFStartDate = $CurrOOFConfigData.StartTime.ToString().split(" ") | Select-Object -Index 0
                $CurrOOFEndDate = $CurrOOFConfigData.EndTime.ToString().split(" ") | Select-Object -Index 0
                if ($CurrDate -ge $CurrOOFStartDate -and $CurrDate -le $CurrOOFEndDate) {
                    PrepareOOFReport
                    ExportAllActiveOOFSetup
                }
            }
        }
    }
     
    #Checks the all active OOF configuration
    else {
        $global:ExportCSVFileName = "OutofOfficeConfigurationReport-" + ((Get-Date -format "MMM-dd hh-mm-ss tt").ToString()) + ".csv" 
        Get-mailbox -ResultSize Unlimited | foreach-object {
            $CurrUser = $_
            $CurrOOFConfigData = Get-MailboxAutoReplyConfiguration -Identity ($CurrUser.PrimarySmtpAddress) | Where-object { $_.AutoReplyState -ne "Disabled" }
            if ($null -ne $CurrOOFConfigData ) {   
                PrepareOOFReport
                ExportAllActiveOOFSetup
            }
        }
    }
}

#Saves the users with OOF configuration
Function PrepareOOFReport {
    $global:ReportSize = $global:ReportSize + 1
    
    $EmailAddress = $CurrUser.PrimarySmtpAddress
    $AccountStatus = $CurrUser.AccountDisabled
    $MailboxOwner = $CurrOOFConfigData.MailboxOwnerId
    $OOFStatus = $CurrOOFConfigData.AutoReplyState
    $StartTime = $CurrOOFConfigData.StartTime
    $EndTime = $CurrOOFConfigData.EndTime
    $Duration = $EndTime - $StartTime
    $TimeSpan = "$($Duration.Days.ToString('00'))d : $($Duration.Hours.ToString('00'))h : $($Duration.Minutes.ToString('00'))m";
    
    if ($EnabledFlag -eq 'true') {
        $global:OOFDuration = 'OOF Duration'
    }
    else {
        $global:OOFDuration = 'OOF Duration (Days:Hours:Mins)'
    }
    if ($OOFStatus -eq 'Enabled') {
        $StartTime = "-"
        $EndTime = "-"
        $TimeSpan = 'Until auto-reply is disabled'
    }
                
    #Save values with output column names 
    $ExportResult = @{ 

        'Email Address'            = $EmailAddress;
        'Disabled Account'         = $AccountStatus;
        'Mailbox Owner'            = $MailboxOwner;
        'Auto Reply State'         = $OOFStatus;
        'Start Time'               = $StartTime;
        'End Time'                 = $EndTime;
        $global:OOFDuration        = $TimeSpan 
    }

    $global:ExportResults = New-Object PSObject -Property $ExportResult
}

#Exports the users with OOF schedued configuration 
Function ExportScheduledOOF {
    $global:ExportResults | Select-Object-object 'Mailbox Owner', 'Email Address', 'Start Time', 'End Time', $global:OOFDuration, 'Disabled Account' | Export-csv -path $global:ExportCSVFileName -NoType -Append -Force
}

#Exports the users with OOF Enabled configuration
Function ExportEnabledOOF {
    $global:ExportResults | Select-Object-object 'Mailbox Owner', 'Email Address', $global:OOFDuration, 'Disabled Account' | Export-csv -path $global:ExportCSVFileName -NoType -Append -Force
}

#Execution starts here
ConnectToExchange
$global:ReportSize = 0
RetrieveOOFReport


Disconnect-ExchangeOnline -Confirm:$false -InformationAction Ignore -ErrorAction SilentlyContinue
Write-Host "Disconnected active ExchangeOnline session"

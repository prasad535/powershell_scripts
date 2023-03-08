$global:groups = @{
'fbdeefe1db0a870062c4fe9b0c9619b8' = 'TCS - Cloud Operations'
'0bb2f14edbf2030090f992d5db961919' = 'TCS - Command Centre'
'f5ff021d1b5a601046e53229cd4bcbdb' = 'TCS - Cyber defence services'
'eefc5e19dbca470062c4fe9b0c961979' = 'TCS - Enterprise Security'
'7fdeefe1db0a870062c4fe9b0c9619aa' = 'TCS - IAM Support'
'f7deefe1db0a870062c4fe9b0c9619af' = 'TCS - ITWP'
'40fee6d1db0e470062c4fe9b0c961964' = 'TCS - LAN Services'
'33deefe1db0a870062c4fe9b0c9619bb' = 'TCS - M&C'
'c0d6d255dbca470062c4fe9b0c961916' = 'TCS - Yara Global Service Desk'
'f7deefe1db0a870062c4fe9b0c9619a6' = 'TCS - Tools Support'
}

function PasswordManager{
    param(
        [Parameter(Mandatory=$true)] [string] $SERVICE_NOW_USERNAME,
        [Parameter(Mandatory=$true)] [securestring] $SERVICE_NOW_TEST_PASSWORD
    )
    #$SECURE_PASSWORD = $SERVICE_NOW_TEST_PASSWORD | ConvertTo-SecureString -AsPlainText -Force
    $PSCredentials = New-Object -TypeName System.Management.Automation.PSCredential ($SERVICE_NOW_USERNAME, $SERVICE_NOW_TEST_PASSWORD)
    return $PSCredentials
}
function ticket_details {
    param(
        [Parameter(Mandatory=$true)] [string] $ITSK_Number,
        [Parameter(Mandatory=$true)] [pscredential] $cred, 
        [Parameter(Mandatory=$true)] [string] $File_path
    )
    start-sleep 5
    if($ITSK_Number)
    {
        $URI2 = 'https://page.service-now.com/api/now/table/incident_task?sysparm_query=number=' + $ITSK_Number
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
        $Requests = Invoke-RestMethod -Uri $URI2 -Credential $cred -Method Get -ContentType "application/json"
        $data = $Requests.result
        if($data)
        {
            if('' -eq $data.assigned_to){
                $Assigned_group = ($data.assignment_group).value
                $Assigment_group = $groups[$Assigned_group]
                $Info = "Dear "+$Assigment_group+ " Team, P1 ticket is created with "+ "Ticket Number "+$data.number
                $Short_Description = 'Short Description is' + $data.short_description
                Add-Type -AssemblyName System.speech
                $tts = New-Object System.Speech.Synthesis.SpeechSynthesizer
                $tts.Speak($Info)
                Start-Sleep 1
                $tts.Speak($Short_Description)
                if(Test-path -Path $File_path)
                {
                    LOGG -Description $Info -File_path $File_path
                    LOGG -Description $Short_Description -File_path $File_path
                }
            }
                if('' -ne $data.assigned_to){
                    $last_updated_on = [datetime]$data.sys_updated_on
                    $current_date = Get-Date
                    $diferenceTime = [float]($current_date - $last_updated_on).TotalHours

                    if($diferenceTime -gt 2){
                        $Assigned_group = ($data.assignment_group).value
                        $Assigment_group = $groups[$Assigned_group]
                        $Info = "Dear "+$Assigment_group+ " Team, P1 ticket"+$data.number +" is updated 2 hours back, please follow up..!"
                        
                        Add-Type -AssemblyName System.speech
                        $tts = New-Object System.Speech.Synthesis.SpeechSynthesizer
                        $tts.Speak($Info)
                        if(Test-path -Path $File_path)
                        {
                            LOGG -Description $Info -File_path $File_path
                            LOGG -Description $Short_Description -File_path $File_path
                        }
                    }
                }
            }
            
        } 
    }
function p_tickets{ 
    param(
        [Parameter(Mandatory=$true)] [pscredential] $cred
    )

    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; 
    $URI = 'https://page.service-now.com/api/now/table/incident_task?sysparm_query=state=2%5EORstate=3^priority=1^assignment_group%3D7fdeefe1db0a870062c4fe9b0c9619aa%5EORassignment_group%3D33deefe1db0a870062c4fe9b0c9619bb%5EORassignment_group%3Df7deefe1db0a870062c4fe9b0c9619af%5EORassignment_group%3Dfbdeefe1db0a870062c4fe9b0c9619b8%5EORassignment_group%3D0bb2f14edbf2030090f992d5db961919%5EORassignment_group%3Df5ff021d1b5a601046e53229cd4bcbdb%5EORassignment_group%3Deefc5e19dbca470062c4fe9b0c961979%5EORassignment_group%3Df7deefe1db0a870062c4fe9b0c9619a6%5EORassignment_group%3D40fee6d1db0e470062c4fe9b0c961964'
     
    $Requests = Invoke-RestMethod -Uri $URI -Credential $cred -Method Get -ContentType "application/json" 
 
    foreach ($rtsk in $Requests.result) 
    { 
        if($rtsk)
        {
            $Ticket_Number = $rtsk.number
            #return $Ticket_Number
            $File_Dir = "C:\Temp\Logger\"
            $File_name = $rtsk.number
            $File_path = $File_Dir+$File_name+".log"
            Write-Output "$Ticket Started working" >> $File_path
            ticket_details -cred $cred -ITSK_Number $Ticket_Number -File_path $File_path

        }
    }
}
function LOGG ($Description, $File_path){
    $Now = Get-Date -Format "yyyy-MM-dd:HH-mm-ss"
    Write-Output $Now" | "$Description >> $File_path
}

while (1) {
    $SERVICE_NOW_USERNAME = ''
    $SERVICE_NOW_TEST_PASSWORD = ''
    $SECURE_PASSWORD = $SERVICE_NOW_TEST_PASSWORD | ConvertTo-SecureString -AsPlainText -Force

    $Credential = PasswordManager -SERVICE_NOW_USERNAME $SERVICE_NOW_USERNAME -SERVICE_NOW_TEST_PASSWORD $SECURE_PASSWORD
    $ITSK_Number = p_tickets -cred $Credential
    #ticket_details -cred $Credential -ITSK_Number $ITSK_Number
}




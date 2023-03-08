$server = ''
$User = ''
$Password = ''

$SNowUser = $User
$SNowPass = $Password | ConvertTo-SecureString -asPlainText -Force
$SNowCreds = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $SNowUser, $SNowPass

$url = "http://sr31038/services/job/export"
$search = "search index= _internal | stats count by sourcetype"
$body = @{
    serach = $search
    output_mode = "json"
    earliest = "rt-5m"
    latest_time = "rt"
    }

Invoke-RestMethod -Method POST -Uri $url -Body $body -Credential $SNowCreds
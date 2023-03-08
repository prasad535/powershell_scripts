function UploadDocuments($destination, $File,$userID, $securePasssword)
{
# Since we’re doing this remotely, we need to authenticate
$credentials = New-Object System.Management.Automation.PSCredential ($userID, $securePasssword)
# Upload the file
$webclient = New-Object System.Net.WebClient
$webclient.Credentials = $credentials
$webclient.UploadFile($destination + "/" + $File.Name, "PUT", $File.FullName)
}

$destination = "https://yara-my.sharepoint.com/personal/c053950_yara_com/_layouts/15/onedrive.aspx"
$fileName = "C:\temp\NSSRReport.csv"
$userName = ""
$securePasssword = ""

UploadDocuments -destination $destination -File $fileName -userID $userName -securePasssword $securePasssword
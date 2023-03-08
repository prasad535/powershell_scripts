function KioskUsers ($Path) {
    Get-ADUser -SearchBase "$Path" -Filter {(ExtensionAttribute11 -eq '11') -or (ExtensionAttribute11 -eq '12') -or (ExtensionAttribute11 -eq '13')} -Properties * | Select-object SamAccountName
}
function RoboticsUsers ($Path) {
    Get-ADUser -SearchBase "$Path" -Filter {(ExtensionAttribute11 -eq '11') -or (ExtensionAttribute11 -eq '12') -or (ExtensionAttribute11 -eq '13')} -Properties * | Select-object SamAccountName
}
function SharedUsers ($Path) {
    Get-ADUser -SearchBase "$Path" -Filter {(ExtensionAttribute11 -eq '11') -or (ExtensionAttribute11 -eq '12') -or (ExtensionAttribute11 -eq '13')} -Properties * | Select-object SamAccountName
}

function findMember ($UserName, $GroupName){
    $arryOfMembers = (Get-ADPrincipalGroupMembership $UserName).name;
    Foreach ($Member in $arryOfMembers) {
        if ($Member -eq $GroupName) {
            return $true;
            exit;
        }
    }
}

$Group1 = "Non Personal E3";
$Group2 = "Non Personal EOP";
$Group3 = "Non Personal F3";
$KioskPath = "OU=Kiosk,OU=Users,OU=Polaris,DC=ad,DC=yara,DC=com";
$RoboticsPath = "OU=Robotics,OU=Users,OU=Polaris,DC=ad,DC=yara,DC=com";
$SharedPath = "OU=Robotics,OU=Users,OU=Polaris,DC=ad,DC=yara,DC=com";

$kiosk =KioskUsers $KioskPath
$robotics = RoboticsUsers $RoboticsPath
$shared = SharedUsers $SharedPath

$getUserList = $kiosk+$robotics+$shared


if ($getUsersList) {
    Foreach ($User in $getUsersList) {
        if ((Get-ADUser $User -Properties ExtensionAttribute11).ExtensionAttribute11 -eq '11') {
            $foundMember = findMember $User $Group1;
            if ($foundMember) {
                Write-Host "AD User $User already member of $Group1";
            } else {
                Add-ADGroupMember -Identity "$Group1" -Members "$User";
                Write-Host "AD User $User is added to AD group $Group1";
            }
        }
        if ((Get-ADUser $User -Properties ExtensionAttribute11).ExtensionAttribute11 -eq '12') {
            $foundMember = findMember $User $Group2;
            if ($foundMember) {
                Write-Host "AD User $User already member of $Group2";
            } else {
                Add-ADGroupMember -Identity "$Group2" -Members "$User";
                Write-Host "AD User $User is added to AD group $Group2";
            }
        }
        if ((Get-ADUser $User -Properties ExtensionAttribute11).ExtensionAttribute11 -eq '13') {
            $foundMember = findMember $User $Group3;
            if ($foundMember) {
                Write-Host "AD User $User already member of $Group3";
            } else {
                Add-ADGroupMember -Identity "$Group3" -Members "$User";
                Write-Host "AD User $User is added to AD group $Group3";
            }
        }
    }
}

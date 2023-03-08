$date = Get-Date
$folderdate = $date.ToString('dd-MM-yyyy') 

New-Item -Path 'E:\TCS\AT_HR_GRPS_LOGS\Consolidate_scrpt_logs\' -Name $folderdate -ItemType 'directory'

$usersou = 'OU=Users,OU=Polaris,DC=ad,DC=yara,DC=com'

$userdatapath = 'E:\TCS\AT_HR_GRPS_LOGS\Consolidate_scrpt_logs\'+ $folderdate +'\userdata.csv'
$allremovelistexported = 'E:\TCS\AT_HR_GRPS_LOGS\Consolidate_scrpt_logs\'+ $folderdate +'\allremovelistexported.csv'
$alladdlistexported = 'E:\TCS\AT_HR_GRPS_LOGS\Consolidate_scrpt_logs\'+ $folderdate +'\alladdlistexported.csv'
$successfullyaddedlist = 'E:\TCS\AT_HR_GRPS_LOGS\Consolidate_scrpt_logs\'+ $folderdate +'\successfullyaddedlist.txt'
$failedtoaddlist = 'E:\TCS\AT_HR_GRPS_LOGS\Consolidate_scrpt_logs\'+ $folderdate +'\failedtoaddlist.txt'
$handlingemptygroupspath = 'E:\TCS\AT_HR_GRPS_LOGS\Consolidate_scrpt_logs\'+ $folderdate +'\emptygrpshandling.txt'
$nousersinADpath = 'E:\TCS\AT_HR_GRPS_LOGS\Consolidate_scrpt_logs\'+$folderdate+'\nousersinAD.txt'
$successfullyremovedlist = 'E:\TCS\AT_HR_GRPS_LOGS\Consolidate_scrpt_logs\'+$folderdate+'\successfullyremovedlist.txt'
$failedtoremovelist = 'E:\TCS\AT_HR_GRPS_LOGS\Consolidate_scrpt_logs\'+$folderdate+'\failedtoremovelist.txt'

###all_employes_consultants_user_dump_for_managing_globalb1/emp groups.##############
$allusers = Get-ADUser -SearchBase $usersou -filter {enabled -eq $true -and Extensionattribute12 -eq 'HRIS' -and Country -like '*' -and Extensionattribute2 -notlike '*Remote*' -and Extensionattribute2 -notlike '*--*'} -Properties samaccountname,extensionattribute9,employeetype,enabled,Extensionattribute12,country,Extensionattribute2 | Select-Object samaccountname,extensionattribute9,employeetype,enabled,Extensionattribute12,country,Extensionattribute2
$output = 'userid'+';'+'b1'+ ';'+'b2'+';'+'b3'+';'+'b4'+';'+'employeetype'+';'+'enabled'+';'+'Extensionattribute12'+';'+'country'+';'+'Siteid'
$output>> $userdatapath
foreach($attrib in $allusers)
{
$user = $attrib.samaccountname
$extab9 = $attrib.extensionattribute9
$emptype = $attrib.employeeType
$enabled = $attrib.enabled
$Extattb12 = $attrib.Extensionattribute12
$country = $attrib.country
$siteid = $attrib.Extensionattribute2
$b1,$b2,$b3,$b4 = $extab9.split('-')
$output = $user+ ';'+$b1+';'+$b2+';'+$b3+';'+$b4+';'+$emptype+';'+$enabled+';'+$Extattb12+';'+$country+';'+$siteid
$outdata = $output.Replace(' ','')
$outdata>> $userdatapath
}
$attributes = Import-Csv -Path $userdatapath -Delimiter ';' | Where-Object-Object-Object{$_.b1 -like '1*' -and $_.b2 -like '2*' -and $_.b3 -like '3*' -and $_.b4 -like '4*'}

#######______________function for fetching attribute names from codes____________#############
$referencepath = "E:\TCS\Scripts\ADHRGRPMGMT\reference.csv"
$attribref = Import-Csv -path $referencepath -Encoding Default
function extenattributefetch($extattbcount, $attribute)
{
if($extattbcount -eq 1)
{
$code = $attribref | Where-Object-Object-Object {$_.'Org Code' -eq $attribute}
$codevalue = $code.'Organization Name'
}
if($extattbcount -eq 2)
{

$code = $attribref | Where-Object-Object-Object {$_.'BU Code' -eq $attribute}
$codevalue = $code.'Business Unit Name'


}
if($extattbcount -eq 3)
{

$code = $attribref | Where-Object-Object-Object {$_.'Dep Code' -eq $attribute}
$codevalue = $code.'Department Name'

}
if($extattbcount -eq 4)
{

$code = $attribref | Where-Object-Object-Object {$_.'SubDep Code' -eq $attribute}
$codevalue = $code.'Subdepartment Name'

}

return $codevalue

}

######################################################################## Global Constructs #######################################################################

########________globalb1_________________##########
$extattb4=@()
foreach($b1 in $attributes)
{
$extattb4 += $b1.b1
}
$b1sunqs = $extattb4 | Select-Object -Unique

foreach($b1sunq in $b1sunqs)
{
$b1code = $b1sunq
$b1name = extenattributefetch -extattbcount 1 -attribute $b1code
$b1 = $b1name
$b1y = $b1.Replace('Yara','')
$b1s = $b1y.Replace(' ','')
$b1sp = $b1s.Replace('&','')
$b1cnname = 'GZS-'+$b1sp
$b1users = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1code}
$memberlist = (Get-ADGroup -Filter{name -eq $b1cnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $b1users.userid
$allmemberslist = $memberlist.samaccountname
If($null -eq $allmemberslist -or $null -eq  $Accuratelist)
{
$b1users | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$b1cnname"}},@{N='construct';E={"globalb1"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $b1cnname + ';'+'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$b1cnname"}},@{N='construct';E={"globalb1"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$b1cnname"}},@{N='construct';E={"globalb1"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
#____________________empgrp_____________#
$b1empcnname = 'GZS-'+$b1sp + '-Employees'
$b1empusers = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1code -and $_.employeetype -eq 'Employee'}
$memberlist = (Get-ADGroup -Filter{name -eq $b1empcnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $b1empusers.userid
$allmemberslist = $memberlist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
$b1empusers | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$b1empcnname"}},@{N='construct';E={"globalb1emp"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $b1empcnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$b1empcnname"}},@{N='construct';E={"globalb1emp"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$b1empcnname"}},@{N='construct';E={"globalb1emp"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
}


#########_______global B21______________###########
$extattb45 = @()
foreach($b12 in $attributes)
{
$b1 = $b12.b1
$b2 = $b12.b2
$data = $b1 + ';' + $b2
$data = $data.Replace(' ','')
$extattb45 += $data
}
$b12sunqs = $extattb45 | Select-Object -Unique

foreach($b21sunq in $b12sunqs)
{
$b1code,$b2code = $b21sunq.split(';')
$b1name = extenattributefetch -extattbcount 1 -attribute $b1code
$b2name = extenattributefetch -extattbcount 2 -attribute $b2code
$b1y = $b1name.Replace('Yara','')
$b1s = $b1y.Replace(' ','')
$b1sp = $b1s.Replace('&','')
$b2s = $b2name.Replace(' ','')
$b2sp = $b2s.Replace('&','')
if($b1sp.Length -gt 10){$b1sp = $b1sp.Substring(0,10)}
if($b2sp.Length -gt 10){$b2sp = $b2sp.Substring(0,10)}
$b21cnname = 'GZS-' + $b2sp +'-'+ $b1sp +'-'+ $b2code
$b21users = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1code -and $_.b2 -eq $b2code}
$memberslist = (Get-ADGroup -Filter{name -eq $b21cnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $b21users.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$b21users | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$b21cnname"}},@{N='construct';E={"globalb21"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $b21cnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$b21cnname"}},@{N='construct';E={"globalb21"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $b21cnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$b21cnname"}},@{N='construct';E={"globalb21"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$b21cnname"}},@{N='construct';E={"globalb21"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
#__________________emp grp___________________#
$b21empcnname = 'GZS-' + $b2sp +'-'+ $b1sp +'-'+ $b2code + '-Employees'
$b21empusers = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1code -and $_.b2 -eq $b2code -and $_.employeetype -eq 'Employee'}
$memberslist = (Get-ADGroup -Filter{name -eq $b21empcnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $b21empusers.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$b21empusers | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$b21empcnname"}},@{N='construct';E={"globalb21emp"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $b21empcnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$b21empcnname"}},@{N='construct';E={"globalb21emp"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $b21empcnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else
{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$b21empcnname"}},@{N='construct';E={"globalb21emp"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$b21empcnname"}},@{N='construct';E={"globalb21emp"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
}

#####___________Globalb312_____________#########
$extattb456 = @()
foreach($b123 in $attributes)
{
$b1 = $b123.b1
$b2 = $b123.b2
$b3 = $b123.b3
$data = $b1 + ';' + $b2 + ';' + $b3
$data = $data.Replace(' ','')
$extattb456 += $data
}
$b123sunqs = $extattb456 | Select-Object -Unique

foreach($b312sunq in $b123sunqs)
{
$b1code,$b2code,$b3code = $b312sunq.split(';')
$b1name = extenattributefetch -extattbcount 1 -attribute $b1code
$b2name = extenattributefetch -extattbcount 2 -attribute $b2code
$b3name = extenattributefetch -extattbcount 3 -attribute $b3code
$b1y = $b1name.Replace('Yara','')
$b1s = $b1y.Replace(' ','')
$b1sp = $b1s.Replace('&','')
$b2s = $b2name.Replace(' ','')
$b2sp = $b2s.Replace('&','')
$b3s = $b3name.Replace(' ','')
$b3sp = $b3s.Replace('&','')
$b3sp1 = $b3sp.Replace('-','')
if($b3sp1.Length -gt 10){$b3sp1 = $b3sp1.Substring(0,10)}
if($b1sp.Length -gt 10){$b1sp = $b1sp.Substring(0,10)}
if($b2sp.Length -gt 10){$b2sp = $b2sp.Substring(0,10)}
$b312cnname = 'GZS-' + $b3sp1 +'-'+ $b1sp +'-'+ $b2sp + '-'+ $b3code
$b312users = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1code -and $_.b2 -eq $b2code -and $_.b3 -eq $b3code}
$memberslist = (Get-ADGroup -Filter{name -eq $b312cnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $b312users.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$b312users | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$b312cnname"}},@{N='construct';E={"globalb312"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $b312cnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$b312cnname"}},@{N='construct';E={"globalb312"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $b312cnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else
{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$b312cnname"}},@{N='construct';E={"globalb312"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$b312cnname"}},@{N='construct';E={"globalb312"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
#__________________emp grp___________________#
$b312empcnname = 'GZS-' + $b3sp1 +'-'+ $b1sp +'-'+ $b2sp + '-'+ $b3code + '-Employees'
$b312empusers = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1code -and $_.b2 -eq $b2code -and $_.b3 -eq $b3code -and $_.employeetype -eq 'Employee'}
$memberslist = (Get-ADGroup -Filter{name -eq $b312empcnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $b312empusers.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$b312empusers | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$b312empcnname"}},@{N='construct';E={"globalb312emp"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $b312empcnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$b312empcnname"}},@{N='construct';E={"globalb312emp"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $b312empcnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$b312empcnname"}},@{N='construct';E={"globalb312emp"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$b312empcnname"}},@{N='construct';E={"globalb312emp"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
}


#####_________________Global b4123________#########
$extattb4563 = @()
foreach($b1234 in $attributes)
{
$b1 = $b1234.b1
$b2 = $b1234.b2
$b3 = $b1234.b3
$b4 = $b1234.b4
$data = $b1 + ';' + $b2 + ';' + $b3 + ';'+ $b4
$data = $data.Replace(' ','')
$extattb4563 += $data
}
$b1234sunqs = $extattb4563 | Select-Object -Unique

foreach($b1234sunq in $b1234sunqs)
{
$b1code,$b2code,$b3code,$b4code = $b1234sunq.split(';')
$b4 = [int]$b4code
$b1name = extenattributefetch -extattbcount 1 -attribute $b1code
$b2name = extenattributefetch -extattbcount 2 -attribute $b2code
$b3name = extenattributefetch -extattbcount 3 -attribute $b3code
$b4name = extenattributefetch -extattbcount 4 -attribute $b4
if($b4name -eq $b3name)
{
"Same $b3name and $b4name"
}

else{
$b1y = $b1name.Replace('Yara','')
$b1s = $b1y.Replace(' ','')
$b1sp = $b1s.Replace('&','')
$b2s = $b2name.Replace(' ','')
$b2sp = $b2s.Replace('&','')
$b3s = $b3name.Replace(' ','')
$b3sp = $b3s.Replace('&','')
$b3sp1 = $b3sp.Replace('-','')
$b4s = $b4name.Replace(' ','')
$b4sp = $b4s.Replace('&','')
if($b3sp1.Length -gt 10){$b3sp1 = $b3sp1.Substring(0,10)}
if($b1sp.Length -gt 10){$b1sp = $b1sp.Substring(0,10)}
if($b2sp.Length -gt 10){$b2sp = $b2sp.Substring(0,10)}
if($b4sp.Length -gt 10){$b4sp = $b4sp.substring(0,10)}
$b4123cnname = 'GZS-' + $b4sp +'-'+ $b1sp +'-'+ $b2sp + '-'+ $b3sp1 + '-' + $b4code
$b4123users = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1code -and $_.b2 -eq $b2code -and $_.b3 -eq $b3code -and $_.b4 -eq $b4code}
$memberslist = (Get-ADGroup -Filter{name -eq $b4123cnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $b4123users.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$b4123users | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$b4123cnname"}},@{N='construct';E={"globalb4123"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $b4123cnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$b4123cnname"}},@{N='construct';E={"globalb4123"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $b4123cnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$b4123cnname"}},@{N='construct';E={"globalb4123"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$b4123cnname"}},@{N='construct';E={"globalb4123"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
#__________________emp grp___________________#
$b4123empcnname = 'GZS-' + $b4sp +'-'+ $b1sp +'-'+ $b2sp + '-'+ $b3sp1 + '-' + $b4code + '-Employees'
$b4123empusers = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1code -and $_.b2 -eq $b2code -and $_.b3 -eq $b3code -and $_.b4 -eq $b4code -and $_.employeetype -eq 'Employee'}
$memberslist = (Get-ADGroup -Filter{name -eq $b4123empcnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $b4123empusers.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$b4123empusers | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$b4123empcnname"}},@{N='construct';E={"globalb4123emp"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $b4123empcnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$b4123empcnname"}},@{N='construct';E={"globalb4123emp"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $b4123empcnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$b4123empcnname"}},@{N='construct';E={"globalb4123emp"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$b4123empcnname"}},@{N='construct';E={"globalb4123emp"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
}
}

######################################################################## Country Constructs #######################################################################

###############________country B1__________##########
$countryb1=@()
foreach($s1b1 in $attributes)
{
$extb4 = $s1b1.b1
$country = $s1b1.country
$combinations = $extb4+';'+$country
$data = $combinations.Replace(' ','')
$countryb1 += $data
}
$s1b1sunqs = $countryb1 | -or -Unique

foreach($s1b1sunq in $s1b1sunqs)
{
$b1,$s1 = $s1b1sunq.split(';')
$b1name = extenattributefetch -extattbcount 1 -attribute $b1
$b1y = $b1name.Replace('Yara','')
$b1s = $b1y.Replace(' ','')
$b1sp = $b1s.Replace('&','')
$s1b1cnname = 'GZS-'+"$s1-"+$b1sp
$s1b1users = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1 -and $_.country -eq $s1}
$memberslist = (Get-ADGroup -Filter{name -eq $s1b1cnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $s1b1users.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$s1b1users | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$s1b1cnname"}},@{N='construct';E={"countryb1"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $s1b1cnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$s1b1cnname"}},@{N='construct';E={"countryb1"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $s1b1cnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$s1b1cnname"}},@{N='construct';E={"countryb1"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$s1b1cnname"}},@{N='construct';E={"countryb1"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
#____________________empgrp_____________#
$s1b1empcnname = 'GZS-'+"$s1-"+$b1sp + '-Employees'
$s1b1empusers = $attributes| Where-Object-Object-Object {$_.b1 -eq $b1 -and $_.employeetype -eq 'Employee' -and $_.country -eq $s1}
$memberslist = (Get-ADGroup -Filter{name -eq $s1b1empcnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $s1b1empusers.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
$s1b1empusers | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$s1b1empcnname"}},@{N='construct';E={"countryb1emp"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $s1b1empcnname +';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$s1b1empcnname"}},@{N='construct';E={"countryb1emp"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $s1b1empcnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$s1b1empcnname"}},@{N='construct';E={"countryb1emp"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$s1b1empcnname"}},@{N='construct';E={"countryb1emp"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
}

###########__________________countryb12____________###################
$countryb21=@()
foreach($s1b12 in $attributes)
{
$extb4 = $s1b12.b1
$extb5 = $s1b12.b2
$country = $s1b12.country
$combinations = $extb4+';'+ $extb5 + ';'+$country
$data = $combinations.Replace(' ','')
$countryb21 += $data
}
$s1b21sunqs = $countryb21 | Select-Object -Unique

foreach($s1b21sunq in $s1b21sunqs)
{
$b1,$b2,$s1 = $s1b21sunq.split(';')
$b1name = extenattributefetch -extattbcount 1 -attribute $b1
$b2name = extenattributefetch -extattbcount 2 -attribute $b2
$b1y = $b1name.Replace('Yara','')
$b1s = $b1y.Replace(' ','')
$b1sp = $b1s.Replace('&','')
$b2s = $b2name.Replace(' ','')
$b2sp = $b2s.Replace('&','')
if($b1sp.Length -gt 10){$b1sp = $b1sp.Substring(0,10)}
if($b2sp.Length -gt 10){$b2sp = $b2sp.Substring(0,10)}
$s1b21cnname = 'GZS-'+"$s1-"+$b2sp +'-'+ $b1sp +'-'+ $b2
$s1b21users = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1 -and $_.country -eq $s1 -and $_.b2 -eq $b2}
$memberslist = (Get-ADGroup -Filter{name -eq $s1b21cnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $s1b21users.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$s1b21users | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$s1b21cnname"}},@{N='construct';E={"countryb21"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $s1b21cnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$s1b21cnname"}},@{N='construct';E={"countryb21"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $s1b21cnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$s1b21cnname"}},@{N='construct';E={"countryb21"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$s1b21cnname"}},@{N='construct';E={"countryb21"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
        
#____________________empgrp_____________#
$s1b21empcnname = 'GZS-'+"$s1-"+$b2sp +'-'+ $b1sp +'-'+ $b2 +'-Employees'
$s1b21empusers = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1 -and $_.b2 -eq $b2 -and $_.employeetype -eq 'Employee' -and $_.country -eq $s1}
$memberslist = (Get-ADGroup -Filter{name -eq $s1b21empcnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $s1b21empusers.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$s1b21empusers | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$s1b21empcnname"}},@{N='construct';E={"countryb21emp"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $s1b21empcnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$s1b21empcnname"}},@{N='construct';E={"countryb21emp"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $s1b21empcnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$s1b21empcnname"}},@{N='construct';E={"countryb21emp"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$s1b21empcnname"}},@{N='construct';E={"countryb21emp"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
}

##########__________________countryb123_____________##################
$countryb312=@()
foreach($s1b123 in $attributes)
{
$extb4 = $s1b123.b1
$extb5 = $s1b123.b2
$extb6 = $s1b123.b3
$country = $s1b123.country
$combinations = $extb4+';'+ $extb5 + ';'+ $extb6 +';' +$country
$data = $combinations.replace(' ','')
$countryb312 += $data
}
$s1b312sunqs = $countryb312 | Select-Object -Unique

foreach($s1b312sunq in $s1b312sunqs)
{
$b1,$b2,$b3,$s1 = $s1b312sunq.split(';')
$b1name = extenattributefetch -extattbcount 1 -attribute $b1
$b2name = extenattributefetch -extattbcount 2 -attribute $b2
$b3name = extenattributefetch -extattbcount 3 -attribute $b3
$b1y = $b1name.Replace('Yara','')
$b1s = $b1y.Replace(' ','')
$b1sp = $b1s.Replace('&','')
$b2s = $b2name.Replace(' ','')
$b2sp = $b2s.Replace('&','')
$b3s = $b3name.Replace(' ','')
$b3sp = $b3s.Replace('&','')
$b3sp1 = $b3sp.Replace('-','')
if($b1sp.Length -gt 10){$b1sp = $b1sp.Substring(0,10)}
if($b2sp.Length -gt 10){$b2sp = $b2sp.Substring(0,10)}
if($b3sp1.Length -gt 10){$b3sp1 = $b3sp1.Substring(0,10)}
$s1b312cnname = 'GZS-'+"$s1-"+$b3sp1 +'-'+ $b2sp + '-' + $b3
$s1b312users = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1 -and $_.b2 -eq $b2 -and $_.b3 -eq $b3 -and $_.country -eq $s1}
$memberslist = (Get-ADGroup -Filter{name -eq $s1b312cnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $s1b312users.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$s1b312users | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$s1b312cnname"}},@{N='construct';E={"countryb312"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $s1b312cnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$s1b312cnname"}},@{N='construct';E={"countryb312"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $s1b312cnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$s1b312cnname"}},@{N='construct';E={"countryb312"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$s1b312cnname"}},@{N='construct';E={"countryb312"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
 

#____________________empgrp_____________#
$s1b312empcnname = 'GZS-'+"$s1-"+$b3sp1 +'-'+ $b2sp +'-'+ $b3 +'-Employees'
$s1b312empusers = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1 -and $_.b2 -eq $b2 -and $_.b3 -eq $b3 -and $_.country -eq $s1 -and $_.employeetype -eq 'Employee'}
$memberslist = (Get-ADGroup -Filter{name -eq $s1b312empcnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $s1b312empusers.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$s1b312empusers | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$s1b312empcnname"}},@{N='construct';E={"countryb312emp"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $s1b312empcnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$s1b312empcnname"}},@{N='construct';E={"countryb312emp"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $s1b312empcnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$s1b312empcnname"}},@{N='construct';E={"countryb312emp"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$s1b312empcnname"}},@{N='construct';E={"countryb312emp"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
}

#########____________________countryB1234____________################
$countryb4123=@()
foreach($s1b1234 in $attributes)
{
$extb4 = $s1b1234.b1
$extb5 = $s1b1234.b2
$extb6 = $s1b1234.b3
$extb3 = $s1b1234.b4
$country = $s1b1234.country
$combinations = $extb4+';'+$extb5+';'+$extb6+';'+$extb3+';'+$country
$data = $combinations.replace(' ','')
$countryb4123 += $data
}
$s1b4123sunqs = $countryb4123 | Select-Object -Unique

foreach($s1b4123sunq in $s1b4123sunqs)
{
$b1,$b2,$b3,$b4,$s1 = $s1b4123sunq.split(';')
$b4code = [int]$b4
$b1name = extenattributefetch -extattbcount 1 -attribute $b1
$b2name = extenattributefetch -extattbcount 2 -attribute $b2
$b3name = extenattributefetch -extattbcount 3 -attribute $b3
$b4name = extenattributefetch -extattbcount 4 -attribute $b4code
if($b4name -eq $b3name)
{
"Same $b3name and $b4name"
}
else{
$b1y = $b1name.Replace('Yara','')
$b1s = $b1y.Replace(' ','')
$b1sp = $b1s.Replace('&','')
$b2s = $b2name.Replace(' ','')
$b2sp = $b2s.Replace('&','')
$b3s = $b3name.Replace(' ','')
$b3sp = $b3s.Replace('&','')
$b3sp1 = $b3sp.Replace('-','')
$b4s = $b4name.Replace(' ','')
$b4sp = $b4s.Replace('&','')
if($b3sp1.Length -gt 10){$b3sp1 = $b3sp1.Substring(0,10)}
if($b2sp.Length -gt 10){$b2sp = $b2sp.Substring(0,10)}
if($b3sp.Length -gt 10){$b3sp = $b3sp.Substring(0,10)}
if($b4sp.Length -gt 10){$b4sp = $b4sp.Substring(0,10)}
$s1b4123cnname = 'GZS-'+"$s1-"+$b4sp +'-'+ $b2sp + '-' + $b3sp1 + '-'+ $b4
$s1b4123users = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1 -and $_.b2 -eq $b2 -and $_.b3 -eq $b3 -and $_.b4 -eq $b4 -and $_.country -eq $s1}
$memberslist = (Get-ADGroup -Filter{name -eq $s1b4123cnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $s1b4123users.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$s1b4123users | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$s1b4123cnname"}},@{N='construct';E={"countryb4123"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $s1b4123cnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$s1b4123cnname"}},@{N='construct';E={"countryb4123"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $s1b4123cnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$s1b4123cnname"}},@{N='construct';E={"countryb4123"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$s1b4123cnname"}},@{N='construct';E={"countryb4123"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
 

#____________________empgrp_____________#
$s1b4123empcnname = 'GZS-'+"$s1-"+$b4sp +'-'+ $b2sp +'-'+ $b3sp1 +'-'+ $b4 +'-Employees'
$s1b4123empusers = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1 -and $_.b2 -eq $b2 -and $_.b3 -eq $b3 -and $_.b4 -eq $b4 -and $_.country -eq $s1 -and $_.emptype -eq 'Employee'}
$memberslist = (Get-ADGroup -Filter{name -eq $s1b4123empcnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $s1b4123empusers.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$s1b4123empusers | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$s1b4123empcnname"}},@{N='construct';E={"countryb4123emp"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $s1b4123empcnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$s1b4123empcnname"}},@{N='construct';E={"countryb4123emp"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $s1b4123empcnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$s1b4123empcnname"}},@{N='construct';E={"countryb4123emp"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$s1b4123empcnname"}},@{N='construct';E={"countryb4123emp"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
 

}
}

######################################################################## Site Constructs #######################################################################
#################____________Site b1_______________###############
$siteidb1=@()
foreach($sb1 in $attributes)
{
$extb4 = $sb1.b1
$siteid = $sb1.siteid
$combinations = $extb4+';'+$siteid
$data = $combinations.replace(' ','')
$siteidb1 += $data
}
$sb1sunqs = $siteidb1 | Select-Object -Unique

foreach($sb1sunq in $sb1sunqs)
{
$b1,$s = $sb1sunq.split(';')
$b1name = extenattributefetch -extattbcount 1 -attribute $b1
$b1y = $b1name.Replace('Yara','')
$b1s = $b1y.Replace(' ','')
$b1sp = $b1s.Replace('&','')
$sb1cnname = 'GZS-'+"$s-"+$b1sp
$sb1users = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1 -and $_.siteid -eq $s}
$memberslist = (Get-ADGroup -Filter{name -eq $sb1cnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $sb1users.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$sb1users | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$sb1cnname"}},@{N='construct';E={"siteb1"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $sb1cnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$sb1cnname"}},@{N='construct';E={"siteb1"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $sb1cnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$sb1cnname"}},@{N='construct';E={"siteb1"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$sb1cnname"}},@{N='construct';E={"siteb1"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
#____________________empgrp_____________#
$sb1empcnname = 'GZS-'+"$s-"+$b1sp + '-Employees'
$sb1empusers = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1 -and $_.siteid -eq $s -and $_.employeetype -eq 'Employee'}
$memberslist = (Get-ADGroup -Filter{name -eq $sb1empcnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $sb1empusers.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$sb1empusers | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$sb1empcnname"}},@{N='construct';E={"siteb1emp"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $sb1empcnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$sb1empcnname"}},@{N='construct';E={"siteb1emp"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $sb1empcnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$sb1empcnname"}},@{N='construct';E={"siteb1emp"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$sb1empcnname"}},@{N='construct';E={"siteb1emp"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
}


############__________________ Site b12 Cinstruct______________#############
$siteidb21=@()
foreach($sb12 in $attributes)
{
$extb4 = $sb12.b1
$extb5 = $sb12.b2
$siteid = $sb12.siteid
$combinations = $extb4+';'+ $extb5 + ';'+$siteid
$data = $combinations.replace(' ','')
$siteidb21 += $data
}
$sb21sunqs = $siteidb21 | Select-Object -Unique

foreach($sb21sunq in $sb21sunqs)
{
$b1,$b2,$s = $sb21sunq.split(';')
$b1name = extenattributefetch -extattbcount 1 -attribute $b1
$b2name = extenattributefetch -extattbcount 2 -attribute $b2
$b1y = $b1name.Replace('Yara','')
$b1s = $b1y.Replace(' ','')
$b1sp = $b1s.Replace('&','')
$b2s = $b2name.Replace(' ','')
$b2sp = $b2s.Replace('&','')
if($b1sp.Length -gt 10){$b1sp = $b1sp.Substring(0,10)}
if($b2sp.Length -gt 10){$b2sp = $b2sp.Substring(0,10)}
$sb21cnname = 'GZS-'+"$s-"+$b2sp +'-'+ $b1sp +'-'+ $b2
$sb21users = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1 -and $_.b2 -eq $b2 -and $_.siteid -eq $s}
$memberslist = (Get-ADGroup -Filter{name -eq $sb21cnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $sb21users.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$sb21users | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$sb21cnname"}},@{N='construct';E={"siteb21"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $sb21cnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$sb21cnname"}},@{N='construct';E={"siteb21"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $sb21cnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$sb21cnname"}},@{N='construct';E={"siteb21"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$sb21cnname"}},@{N='construct';E={"siteb21"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
#____________________empgrp_____________#
$sb21empcnname = 'GZS-'+"$s-"+$b2sp +'-'+ $b1sp +'-'+ $b2 +'-Employees'
$sb21empusers = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1 -and $_.b2 -eq $b2 -and $_.siteid -eq $s -and $_.employeetype -eq 'Employee'}
$memberslist = (Get-ADGroup -Filter{name -eq $sb21empcnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $sb21empusers.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$sb21empusers | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$sb21empcnname"}},@{N='construct';E={"siteb21emp"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $sb21empcnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$sb21empcnname"}},@{N='construct';E={"siteb21emp"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $sb21empcnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$sb21empcnname"}},@{N='construct';E={"siteb21emp"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$sb21empcnname"}},@{N='construct';E={"siteb21emp"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
}

#############__________________ Siteb312 ___________#########

$siteidb312=@()
foreach($sb123 in $attributes)
{
$extb4 = $sb123.b1
$extb5 = $sb123.b2
$extb6 = $sb123.b3
$siteid = $sb123.siteid
$combinations = $extb4+';'+ $extb5 + ';'+ $extb6 +';' +$siteid
$data = $combinations.replace(' ','')
$siteidb312 += $combinations
}
$sb312sunqs = $siteidb312 | Select-Object -Unique

foreach($sb312sunq in $sb312sunqs)
{
$b1,$b2,$b3,$s = $sb312sunq.split(';')
$b1name = extenattributefetch -extattbcount 1 -attribute $b1
$b2name = extenattributefetch -extattbcount 2 -attribute $b2
$b3name = extenattributefetch -extattbcount 3 -attribute $b3
$b1y = $b1name.Replace('Yara','')
$b1s = $b1y.Replace(' ','')
$b1sp = $b1s.Replace('&','')
$b2s = $b2name.Replace(' ','')
$b2sp = $b2s.Replace('&','')
$b3s = $b3name.Replace(' ','')
$b3sp = $b3s.Replace('&','')
$b3sp1 = $b3sp.Replace('-','')
if($b1sp.Length -gt 10){$b1sp = $b1sp.Substring(0,10)}
if($b2sp.Length -gt 10){$b2sp = $b2sp.Substring(0,10)}
if($b3sp1.Length -gt 10){$b3sp1 = $b3sp1.Substring(0,10)}
$sb312cnname = 'GZS-'+"$s-"+$b3sp1 +'-'+ $b2sp + '-' + $b3
$sb312users = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1 -and $_.b2 -eq $b2 -and $_.b3 -eq $b3 -and $_.siteid -eq $s}
$memberslist = (Get-ADGroup -Filter{name -eq $sb312cnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $sb312users.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$sb312users | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$sb312cnname"}},@{N='construct';E={"siteb312"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $sb312cnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$sb312cnname"}},@{N='construct';E={"siteb312"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $sb312cnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$sb312cnname"}},@{N='construct';E={"siteb312"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$sb312cnname"}},@{N='construct';E={"siteb312"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
#____________________empgrp_____________#
$sb312empcnname = 'GZS-'+"$s-"+$b3sp1 +'-'+ $b2sp +'-'+ $b3 +'-Employees'
$sb312empusers = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1 -and $_.b2 -eq $b2 -and $_.b3 -eq $b3 -and $_.siteid -eq $s -and $_.employeetype -eq 'Employee'}
$memberslist = (Get-ADGroup -Filter{name -eq $sb312empcnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $sb312empusers.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$sb312empusers | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$sb312empcnname"}},@{N='construct';E={"siteb312emp"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $sb312empcnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$sb312empcnname"}},@{N='construct';E={"siteb312emp"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $sb312empcnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$sb312empcnname"}},@{N='construct';E={"siteb312emp"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$sb312empcnname"}},@{N='construct';E={"siteb312emp"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
}

##########_______________Site b4123_________________############

$siteidb4123=@()
foreach($sb1234 in $attributes)
{
$extb4 = $sb1234.b1
$extb5 = $sb1234.b2
$extb6 = $sb1234.b3
$extb7 = $sb1234.b4
$siteid = $sb1234.siteid
$combinations = $extb4+';'+ $extb5 + ';'+ $extb6 +';'+$extb7 +';'+$siteid
$data = $combinations.Replace(' ','')
$siteidb4123 += $data
}
$sb4123sunqs = $siteidb4123 | Select-Object -Unique
foreach($sb4123sunq in $sb4123sunqs)
{
$b1,$b2,$b3,$b4,$s = $sb4123sunq.split(';')
$b4code = [int]$b4
$b1name = extenattributefetch -extattbcount 1 -attribute $b1
$b2name = extenattributefetch -extattbcount 2 -attribute $b2
$b3name = extenattributefetch -extattbcount 3 -attribute $b3
$b4name = extenattributefetch -extattbcount 4 -attribute $b4code
if($b4name -eq $b3name)
{
$refdata = $b1 + '-' + $b2 + '-' + $b3 + '-'+ $b4+'-'+$s
$output = $refdata + ';' + "Same $b3name and $b4name"
$output >> "C:\Temp\AutomatedHRGrps\NewGroupCreation\usrs_with_same_b3b4.csv"
}
else
{
$b1y = $b1name.Replace('Yara','')
$b1s = $b1y.Replace(' ','')
$b1sp = $b1s.Replace('&','')
$b2s = $b2name.Replace(' ','')
$b2sp = $b2s.Replace('&','')
$b3s = $b3name.Replace(' ','')
$b3sp = $b3s.Replace('&','')
$b3sp1 = $b3sp.Replace('-','')
$b4s = $b4name.Replace(' ','')
$b4sp = $b4s.Replace('&','')
if($b1sp.Length -gt 10){$b1sp = $b1sp.Substring(0,10)}
if($b2sp.Length -gt 10){$b2sp = $b2sp.Substring(0,10)}
if($b3sp1.Length -gt 10){$b3sp1 = $b3sp1.Substring(0,10)}
if($b4sp.Length -gt 10){$b4sp = $b4sp.Substring(0,10)}
$sb4123cnname = 'GZS-'+"$s-"+$b4sp +'-'+ $b2sp + '-' + $b3sp1 + '-'+ $b4
$sb4123users = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1 -and $_.b2 -eq $b2 -and $_.b3 -eq $b3 -and $_.b4 -eq $b4 -and $_.siteid -eq $s}
$memberslist = (Get-ADGroup -Filter{name -eq $sb4123cnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $sb4123users.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$sb4123users | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$sb4123cnname"}},@{N='construct';E={"siteb4123"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $sb4123cnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$sb4123cnname"}},@{N='construct';E={"siteb4123"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $sb4123cnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$sb4123cnname"}},@{N='construct';E={"siteb4123"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$sb4123cnname"}},@{N='construct';E={"siteb4123"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
#____________________empgrp_____________#
$sb4123empcnname = 'GZS-'+"$s-"+$b4sp +'-'+ $b2sp +'-'+ $b3sp1 +'-'+ $b4 +'-Employees'
$sb4123empusers = $attributes | Where-Object-Object-Object {$_.b1 -eq $b1 -and $_.b2 -eq $b2 -and $_.b3 -eq $b3 -and $_.b4 -eq $b4 -and $_.siteid -eq $s -and $_.employeetype -eq 'Employee'}
$memberslist = (Get-ADGroup -Filter{name -eq $sb4123empcnname}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $sb4123empusers.userid
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
if($null -eq $allmemberslist)
{
$sb4123empusers | Select-Object @{N='userid'; E={$_.userid}},@{N='grpname';E={"$sb4123empcnname"}},@{N='construct';E={"siteb4123emp"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $sb4123empcnname + ';'+ 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
}
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$sb4123empcnname"}},@{N='construct';E={"siteb4123emp"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $sb4123empcnname + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$sb4123empcnname"}},@{N='construct';E={"siteb4123emp"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$sb4123empcnname"}},@{N='construct';E={"siteb4123emp"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}

}
}




######################################################################## common groups #######################################################################

$employees = Get-ADUser -SearchBase $usersou -filter {enabled -eq $true -and Extensionattribute12 -eq 'HRIS' -and employeetype -eq 'Employee'}  -properties samaccountname,employeetype,enabled | Select-Object samaccountname,employeetype,enabled
$consultants = Get-ADUser -SearchBase $usersou -filter {enabled -eq $true -and Extensionattribute12 -eq 'HRIS' -and employeetype -eq 'Consultant'} -properties samaccountname,employeetype,enabled | Select-Object samaccountname,employeetype,enabled
$externals = Get-ADUser -SearchBase $usersou -filter {enabled -eq $true -and Extensionattribute12 -eq 'YaraIT' -and employeetype -eq 'External'} -properties samaccountname,employeetype,enabled | Select-Object samaccountname,employeetype,enabled
$allstaff = Get-ADUser -SearchBase $usersou -filter {enabled -eq $true -and (Extensionattribute12 -eq 'HRIS' -or Extensionattribute12 -eq 'YaraIT')} -properties samaccountname,employeetype,enabled | Select-Object samaccountname,employeetype,enabled

$empgrp = 'GZS-all employees'
$memberlistemp = (Get-ADGroup -Identity $empgrp -Properties Members).Members | get-aduser | Select-Object samaccountname
$accuratelistemp = $employees.samaccountname
$allmemberlistemp = $memberlistEmp.samaccountname
$toberemovedlistemp = Compare-Object -ReferenceObject $allmemberlistemp -DifferenceObject $accuratelistemp | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlistemp =  Compare-Object -ReferenceObject $allmemberlistemp -DifferenceObject $accuratelistemp | Where-Object-Object{$_.SideIndicator -eq '=>'}

$toberemovedlistemp | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$empgrp"}},@{N='construct';E={"allemployees"}} |export-csv -NoTypeInformation $allremovelistexported -Append  
$tobeaddedlistemp | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$empgrp"}},@{N='construct';E={"allemployees"}} |export-csv -NoTypeInformation $alladdlistexported -Append 

################ all-consulatnts####################

$consultantgrp = 'GZS-all consultants'
$memberlistconsultant = (Get-ADGroup -Identity $Consultantgrp -Properties Members).Members | get-aduser | Select-Object samaccountname
$accuratelistconsultant= $consultants.samaccountname
$allmemberlistconsultant = $memberlistconsultant.samaccountname
$toberemovedlistconsultant = Compare-Object -ReferenceObject $allmemberlistconsultant -DifferenceObject $accuratelistconsultant | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlistconsultant =  Compare-Object -ReferenceObject $allmemberlistconsultant -DifferenceObject $accuratelistconsultant | Where-Object-Object{$_.SideIndicator -eq '=>'}

$toberemovedlistconsultant | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$Consultantgrp"}},@{N='construct';E={"allconsultants"}} |export-csv -NoTypeInformation $allremovelistexported -Append  
$tobeaddedlistconsultant | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$Consultantgrp"}},@{N='construct';E={"allconsultants"}} |export-csv -NoTypeInformation $alladdlistexported -Append 


################ all-externals####################

$externalgrp = 'All_ExternalContractors_SN_SSO'
$memberlistexternal = (Get-ADGroup -Identity $externalgrp -Properties Members).Members | get-aduser | Select-Object samaccountname
$accuratelistexternal= $externals.samaccountname
$allmemberlistexternal = $memberlistexternal.samaccountname
$toberemovedlistexternal = Compare-Object -ReferenceObject $allmemberlistexternal -DifferenceObject $accuratelistexternal | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlistexternal =  Compare-Object -ReferenceObject $allmemberlistexternal -DifferenceObject $accuratelistexternal | Where-Object-Object{$_.SideIndicator -eq '=>'}

$toberemovedlistexternal | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$externalgrp"}},@{N='construct';E={"allexternals"}} |export-csv -NoTypeInformation $allremovelistexported -Append  
$tobeaddedlistexternal | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$externalgrp"}},@{N='construct';E={"allexternals"}} |export-csv -NoTypeInformation $alladdlistexported -Append 

################### all-staff####################
$grpoppm = 'GZS-All Staff OPPM'
$grpallstaff = 'GZS-all staff'
$memberlistallstaff = (Get-ADGroup -Identity $grpallstaff -Properties Members).Members | get-aduser | Select-Object samaccountname
$accuratelistallstaff = $allstaff.samaccountname
$allmemberlistallstaff = $memberlistallstaff.samaccountname
$toberemovedlistallstaff = Compare-Object -ReferenceObject $allmemberlistallstaff -DifferenceObject $accuratelistallstaff | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlistallstaff =  Compare-Object -ReferenceObject $allmemberlistallstaff -DifferenceObject $accuratelistallstaff | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlistallstaff | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$grpallstaff"}},@{N='construct';E={"allstaff"}} |export-csv -NoTypeInformation $allremovelistexported -Append  
$tobeaddedlistallstaff | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$grpallstaff"}},@{N='construct';E={"allstaff"}} |export-csv -NoTypeInformation $alladdlistexported -Append 
$tobeaddedlistallstaff |  Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$grpoppm"}},@{N='construct';E={"allstaffoppm"}} |export-csv -NoTypeInformation $alladdlistexported -Append 


######################################################################## Country All staff/All employees #######################################################################
$s1s = Get-ADUser -filter {enabled -eq $true -and Country -like '*' -and (Extensionattribute12 -eq 'HRIS' -or Extensionattribute12 -eq 'YaraIT') } -searchbase $usersou -Properties samaccountname,employeetype,country,enabled,whenchanged | Select-Object samaccountname,employeetype,country,enabled,whenchanged -Unique
$s1ssexport =$s1s
$s1sunqs = $s1s | Select-Object Country -Unique

Foreach($s1 in $s1sUnqs)
{
$stringS1 = $s1.country
##_____countryemp____#####
$CountryEmp = "GZS-$stringS1-Employees"
$s1empusers = $s1ssexport | Where-Object-Object{$_.Employeetype -eq 'Employee' -and $_.Country -eq $stringS1}
$memberslist = (Get-ADGroup -Filter{name -eq $CountryEmp} -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $s1empusers.samaccountname
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
$s1empusers | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$CountryEmp"}},@{N='construct';E={"countryemp"}} | export-csv -NoTypeInformation $alladdlistexported -Append
$output = $CountryEmp + ';' +'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$CountryEmp"}},@{N='construct';E={"countryemp"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $CountryEmp + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else
{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$CountryEmp"}},@{N='construct';E={"countryemp"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$CountryEmp"}},@{N='construct';E={"countryemp"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}
##_____country all staff____#####
$Countryallstaff = "GZS-$stringS1-All Staff"
$s1allstaffusers = $s1ssexport | Where-Object-Object{$_.country -eq $stringS1}
$memberslist = (Get-ADGroup -Filter{name -eq $Countryallstaff} -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $s1allstaffusers.samaccountname
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
$s1allstaffusers | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$Countryallstaff"}},@{N='construct';E={"countryallstaff"}} | export-csv -NoTypeInformation $alladdlistexported -Append
$output = $Countryallstaff + ';' +'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$Countryallstaff"}},@{N='construct';E={"countryallstaff"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $Countryallstaff + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else
{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$Countryallstaff"}},@{N='construct';E={"countryallstaff"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$Countryallstaff"}},@{N='construct';E={"countryallstaff"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}

}

######################################################################## Site All staff/All employees #######################################################################
$sitecodes = get-aduser -filter {enabled -eq $true -and Extensionattribute2 -notlike '*Remote*' -and Extensionattribute2 -notlike '*--*' -and (Extensionattribute12 -eq 'HRIS' -or Extensionattribute12 -eq 'YaraIT')} -searchbase $usersou -Properties country,extensionattribute2,extensionattribute4,extensionattribute5,extensionattribute6,whencreated,employeetype | Select-Object samaccountname,whencreated,extensionattribute2,employeetype -Unique
$sitecodesexport = $sitecodes
$sitecodesunqs = $sitecodes | Select-Object Extensionattribute2 -Unique


foreach($sitecode in $sitecodesunqs)
{
$stringSite = $sitecode.extensionattribute2
$siteEmp = "GZS-$stringSite-Employees"
$sempusers = $sitecodesexport | Where-Object-Object{$_.Employeetype -eq 'Employee' -and $_.Extensionattribute2 -eq $stringSite}
$memberslist = (Get-ADGroup -Filter{name -eq $siteEmp}  -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $sempusers.samaccountname
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
$sempusers | Select-Object @{N='userid'; E={$_.samaccountname}},@{N='grpname';E={"$siteEmp"}},@{N='construct';E={"siteEmp"}} |export-csv -NoTypeInformation $alladdlistexported -Append
$output = $siteemp+';'+'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$siteEmp"}},@{N='construct';E={"siteEmp"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $siteEmp + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else
{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$siteEmp"}},@{N='construct';E={"siteEmp"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$siteEmp"}},@{N='construct';E={"siteEmp"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}

##____site all staff____#####
$SiteStaffAll = "GZS-$stringSite-All Staff"
$siteallstaffusers = $sitecodesexport | Where-Object-Object{$_.Extensionattribute2 -eq $stringSite}
$memberslist = (Get-ADGroup -Filter{name -eq $SiteStaffAll} -Properties Members).Members | get-aduser | Select-Object samaccountname
$Accuratelist = $siteallstaffusers.samaccountname
$allmemberslist = $memberslist.samaccountname
If($null -eq $allmemberslist -or $null -eq $Accuratelist)
{
$siteallstaffusers | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$SiteStaffAll"}},@{N='construct';E={"sitestaffall"}} | export-csv -NoTypeInformation $alladdlistexported -Append
$output = $SiteStaffAll + ';' + 'no users in adgroup adding all actual users'
$output
$output >> $handlingemptygroupspath
if($null -eq $Accuratelist)
{
$memberslist | Select-Object @{N='userid';E={$_.samaccountname}},@{N='grpname';E={"$SiteStaffAll"}},@{N='construct';E={"siteEmp"}} | export-csv -NoTypeInformation $allremovelistexported -Append
$output = $SiteStaffAll + ';' +'no users in AD with these attributes'
$output
$output >> $nousersinADpath
}
}
else
{
$toberemovedlist = Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '<='}
$tobeaddedlist =  Compare-Object -ReferenceObject $allmemberslist -DifferenceObject $Accuratelist | Where-Object-Object{$_.SideIndicator -eq '=>'}
$toberemovedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$SiteStaffAll"}},@{N='construct';E={"sitestaffall"}} |export-csv -NoTypeInformation $allremovelistexported -Append
$tobeaddedlist | Select-Object @{N='userid';E={$_.InputObject}},@{N='grpname';E={"$SiteStaffAll"}},@{N='construct';E={"sitestaffall"}} | export-csv -NoTypeInformation $alladdlistexported -Append
}

}

#>

######################################################################## Add/Remove users as per the logs #####################################################################

#
##########_____________Addition Users____________########
$users = Import-Csv -path $alladdlistexported
foreach($usr in $users)
{
$userid = $usr.userid
$groupname = $usr.grpname
try{
$grpdetails = Get-ADGroup -Filter {name -eq $groupname} | Select-Object samaccountname
$sam = $grpdetails.samaccountname
Add-ADGroupMember -Identity $sam -Members $userid
$result = $userid+';'+$groupname+';'+'Added successfully'
$result>>$successfullyaddedlist
}
catch
{
$result = $userid+';'+$groupname+';'+'Failed to ADD'
$result>>$failedtoaddlist
}
}
#


#############________Removal Users________############
$users = Import-Csv -path $allremovelistexported
foreach($usr in $users)
{
$userid = $usr.userid
$groupname = $usr.grpname
try{
$grpdetails = Get-ADGroup -Filter {name -eq $groupname} | Select-Object samaccountname
$sam = $grpdetails.samaccountname
Remove-ADGroupMember -Identity $sam -Members $userid -Confirm: $false
$result = $userid+';'+$groupname+';'+'Removed successfully'
$result>>$successfullyremovedlist
}
catch
{
$result = $userid+';'+$groupname+';'+'Failed to Remove'
$result>>$failedtoremovelist
}
}



#################creating a zip folder and removing the actual folder################################

$actualfilepath = 'E:\TCS\AT_HR_GRPS_LOGS\Consolidate_scrpt_logs\' + $folderdate 

$compressedpath = 'E:\TCS\AT_HR_GRPS_LOGS\Consolidate_scrpt_logs\' + $folderdate + '.zip'

Compress-Archive -Path $actualfilepath  -DestinationPath $compressedpath -Force

Remove-Item -Path $actualfilepath -Recurse -Force

###############################################################################################################
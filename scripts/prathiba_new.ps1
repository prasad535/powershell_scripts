# To get all excel files
$files = Get-ChildItem -path "C:\Users\c053950\Downloads\Try" -Recurse -Filter *xlsx
$files.Count
# output file path 
$filepath = 'C:\Users\c053950\Downloads\Try\output.csv'
New-Item -Path $filepath -ItemType 'file'
$output = "Site ID"+","+"Site ID Documentation"+","+"BIA Criticality"+","+"BIA Minimum Visible Company"+","+"Site State"
$output>>$filepath

# loop to process each excel file
foreach($file in $files){
    $XL = New-Object -comobject Excel.Application
    $sp = "https://page.sharepoint.com/teams/SiteITDocumentation/Documents/"
    $directory = $file.DirectoryName

    # to get site ID from folder name
    $arr = $directory -split ""
    [array]::Reverse($arr)
    $r_string = $arr -join ''
    $site_r , $e = $r_string.Split('\')
    $site_arr = $site_r -split ""
    [array]::Reverse($site_arr)
    $site = $site_arr -join ''
   
    #$temp1,$temp2,$temp3,$temp3,$temp5,$temp6,$site= $directory.Split('\')

    $siteiddocument = $sp+$site
    $file_name = $file.Name
    $last_file = $directory+'\'+$file_name
    $book = $XL.Workbooks.Open($last_file)
    $Sheet =$book.worksheets.item("Site Classification")
    $Var = $Sheet.Rows.item(4).cells.item(5).Value2
    $Var2 = $Sheet.Rows.item(5).cells.item(5).Value2
    $sitestate = 'Active'
    if($site -eq 'IN-HYD-TCS' -or $site -eq 'IN-TRV-KAR')
    {
    $sitestate = ""
    }
    $output = $site+","+$siteiddocument+","+$Var2+","+$Var+","+$sitestate
    $output>>$filepath
}

$processes = Import-Csv -Path "C:\Users\c053950\Downloads\Try\output.csv"
$Excel = New-Object -ComObject excel.application 
$workbook = $Excel.workbooks.add() 

$i = 1 
foreach($process in $processes) 
{ 
 $excel.cells.item($i,1) = $process."Site ID"
 $excel.cells.item($i,2) = $process."Site ID Documentation"
 $excel.cells.item($i,3) = $process."BIA Criticality"
 $excel.cells.item($i,4) = $process."BIA Minimum Visible Company"
 $excel.cells.item($i,5) = $process."Site State"

 $i++ 
} 
$folder = "C:\Users\c053950\Downloads\Try"
$workbook.SaveAs($folder + "\" + "BIA_Active_output.xlsx") 
#$Excel.visible = $true
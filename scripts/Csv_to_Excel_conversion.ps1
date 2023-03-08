$processes = Import-Csv -Path 'C:\Users\c053950\OneDrive - Yara International ASA\Documents\Prasad Docs\Excel_files\OutofOfficeConfigurationReport-Jan-20.csv'
$Excel = New-Object -ComObject excel.application 
$workbook = $Excel.workbooks.add() 

$i = 1 
foreach($process in $processes) 
{ 
 $excel.cells.item($i,1) = $process."Mailbox Owner"
 $excel.cells.item($i,2) = $process."Email Address"
 $excel.cells.item($i,3) = $process."Auto Reply State"
 $excel.cells.item($i,4) = $process."Start Time"
 $excel.cells.item($i,5) = $process."End Time"
 $excel.cells.item($i,6) = $process."Disabled Account"

 $i++ 
} 
$folder = "C:\Users\c053950\OneDrive - Yara International ASA\Documents\Prasad Docs\Excel_files"
$workbook.SaveAs($folder + "\" + "OutofOfficeConfigurationReport-Jan-20.xlsx") 
$Excel.visible = $true

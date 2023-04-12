
 $currentDate = Get-Date
$lastMonthEndDate = $currentDate.AddDays(-($currentDate.Day))
$lastMonthStartDate = $lastMonthEndDate.AddMonths(-1).AddDays(1)
Write-Host $lastMonthStartDate.Date
write-host $lastMonthEndDate.Date
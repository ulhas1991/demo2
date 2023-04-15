$Data =[System.Collections.ArrayList]:: Synchronized((New-Object System.Collections.ArrayList))
$All_Subscriptions = Get-AzSubscription
#$rawdata = import-csv -path /Users/Administrator/Desktop/Book21.csv
$All_Unattached_Disks = $null

$billingPeriodStartDate = (Get-Date).AddMonths(-1).ToString("yyyy-MM-01")
$lastDayOfMonth = (Get-Date).AddMonths(-1).AddDays(-((Get-Date).AddMonths(-1).Day - 1)).AddMonths(1).AddDays(-1).ToString("yyyy-MM-ddT23:59:59Z")


 $currentDate = Get-Date
$lastDayOfMonth = $currentDate.AddDays(-($currentDate.Day)).Date
$billingPeriodStartDate = $lastDayOfMonth.AddMonths(-1).AddDays(1).Date
Write-Host $billingPeriodStartDate
write-host $lastDayOfMonth



Write-Host "ALll Subscription is count is "$All_Subscriptions.count
#$All_Unattached_Disks = Foreach ($Subscription in $All_Subscriptions)
$All_Subscriptions| ForEach-Object -Parallel{
    
    
    #Getting data for every subscription

    Write-Host "Getting data for $($_.Name)"
    Set-AzContext -SubscriptionObject $_ | Out-Null
   
    #Getting all unattached disks in the given subscription
    Write-Host "Getting Unattached disks in subscription ""$($_.Name)"""
    $Unattached_disks_In_sub = $null
    $Unattached_disks_In_sub = Get-AzDisk | Where-Object {$_.DiskState -eq "Unattached"}
     
    
    If ($null -ne $Unattached_disks_In_sub)
        {
        Write-Host "There are Total $($Unattached_disks_In_sub.Count) unattatched disks in subscription ""$($_.Name)""" -ForegroundColor Green
       
        #Getting billing usage details 
        Write-Host "Usage details for all resources in subscription ""$($_.Name)"""
        $All_Usage_Comsumption = $null
     #   $All_Usage_Comsumption = Get-AzConsumptionUsageDetail -StartDate 2023-03-01 -EndDate 2023-04-01
         $billingPeriodStartDate = $using:billingPeriodStartDate
         $lastDayOfMonth = $using:lastDayOfMonth
         write-Host "Value of f is "$f
         $All_Usage_Comsumption = Get-AzConsumptionUsageDetail -StartDate $billingPeriodStartDate -EndDate $lastDayOfMonth
   
        Foreach ($Unattached_Disk in $Unattached_disks_In_sub)
            {
            Write-Host "Finding Billing Details for Disk ""$($Unattached_Disk.Name)"""
            $Consumption_Use_Details = $null
            $Consumption_Use_Details = $All_Usage_Comsumption | Where-Object {$_.InstanceId -eq $Unattached_Disk.Id}
             #Write-Host "Value is " $Unattached_Disk.
            
            #Create a result object
            $Result = $null 
            $Result = New-Object PSObject -Property @{
                Disk_Object = $Unattached_Disk
                Billing_Object = $null
                
                Subscription_Name = $_.Name
                Subscription_ID = $_.Id
                Disk_Resource_Group_Name = $Unattached_Disk.ResourceGroupName
                Disk_Name = $Unattached_Disk.Name
                Disk_State = $Unattached_Disk.DiskState
                Cost = $null
                }

            If ($null -ne $Consumption_Use_Details)
                {
                
                Write-Host "We found usage details for disk named ""$($Unattached_Disk.Name)"""
                $Result.Billing_Object = $Consumption_Use_Details
                $Result.Cost = $Consumption_Use_Details | Where-Object {$_.InstanceId -eq $Unattached_Disk.Id} | Measure-Object -Sum -Property Pretaxcost | Select-Object -ExpandProperty sum
               # $Result.Disk_Cost_Currency = $Consumption_Use_Details | Select-Object -First 1 | Select-Object -ExpandProperty Currency
                }
            else 
                {
                Write-Host "We did NOT find usage details for disk named ""$($Unattached_Disk.Name)""" -ForegroundColor Green
                }
            $Data= $using:Data
            $Data.Add($Result)
            }
        }
    else 
        {
        Write-Host "No unattatched disks in subscription ""$($_.Name)!""" -ForegroundColor Green
        }
    }-ThrottleLimit 10
    
    $Data | Export-Csv Report3.csv -NoTypeInformation
    
    

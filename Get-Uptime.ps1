function Get-Uptime {

    Param (
        [string]$ComputerName = $env:ComputerName
    )

    $os = Get-WmiObject -Class win32_operatingsystem -ComputerName $ComputerName
    $boottime = [management.managementDateTimeConverter]::ToDateTime($os.LastBootUpTime)
    $now = [DateTime]::Now
    $uptime = New-TimeSpan -Start $boottime -End $now

    Write-Output $uptime 
}
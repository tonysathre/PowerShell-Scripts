function Get-PrinterDriversInUse {
    param (
        [Parameter(Mandatory=$false)]
        [string]$ComputerName = $env:COMPUTERNAME   
    )

    Get-Printer -ComputerName $ComputerName | select @{Name='Name';Expression={$_.DriverName}} -Unique | Get-PrinterDriver -ComputerName $ComputerName
}
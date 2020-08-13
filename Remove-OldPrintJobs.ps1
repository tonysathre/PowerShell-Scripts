function Remove-OldPrintJobs {
    param (
        [Parameter(Mandatory=$true)]
        $ComputerName
    )

    BEGIN {

    }

    PROCESS {
        $Printers = Get-Printer -ComputerName $ComputerName | where Status -eq 
        $PrintJobs = @()
        foreach ($Printer in $Printers) {
            $PrintJobs += Get-PrintJob -ComputerName $ComputerName -PrinterName $Printer.Name -ErrorAction SilentlyContinue
        }
        
        foreach ($PrintJob in $PrintJobs) {
            if ($PrintJob.SubmittedTime -lt (Get-Date).AddDays(-7)) {
                $PrintJob
            }
        }
    }

    END {}
}
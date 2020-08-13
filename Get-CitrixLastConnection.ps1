function Get-CitrixLastConnection {
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    $Results = @()
    $FilterHashTable = @{
        LogName = 'Citrix-HostCore-ICA Service/Operational'
        ID      = 25
    }

    foreach ($Computer in $ComputerName) {
        if (Test-Connection -ComputerName $Computer -Count 2 -Quiet) {
            $Results += Get-WinEvent -ComputerName $Computer -FilterHashtable $FilterHashTable -MaxEvents 1 -Credential $Credential | Select-Object -Property TimeCreated, MachineName
        } else {
            $Results += @{ TimeCreated = 'Offline'; MachineName = $Computer }
        }
    }

    $Results
}
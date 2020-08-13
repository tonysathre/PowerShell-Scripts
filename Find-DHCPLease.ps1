function Find-DHCPLease {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName,
        [Parameter(Mandatory=$true)]
        [string]$MACAddress
    )

    $MACAddress = $MACAddress -replace "([0-9a-f]{2})[^0-9a-f]?(?=.)",'$1-'

    foreach ($Computer in $ComputerName) {
        Get-DhcpServerv4Scope -ComputerName $Computer | Get-DhcpServerv4Lease -ComputerName $Computer | where ClientId -Like "*$MACAddress*" | select IPAddress, ScopeId, ClientId, HostName, AddressState, @{Name="DHCPServer";Expression={($Computer.ToString().ToUpper())}}
    }
}
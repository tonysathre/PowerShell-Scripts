function Get-SidHistory {
    param (
        [Parameter(Mandatory=$true)]
            [string]$SamAccountName
    )

    Get-ADUser -Identity $SamAccountName -Properties sIDHistory | select SIDHistory
}
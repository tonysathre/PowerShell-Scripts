function ConvertTo-SecurityIdentifier {
    param (
        [Parameter(Mandatory=$true)]
            [string]$Identity
    )

    try {
        $objUser = New-Object System.Security.Principal.NTAccount($Identity)
        $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
        $strSID
    } catch {
        throw $Error[0]
    }
}
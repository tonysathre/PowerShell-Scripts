function ConvertFrom-SecurityIdentifier {
    param (
        [Parameter(Mandatory=$true)]
            [string]$SecurityIdentifier
    )

    try {
        $objSID = New-Object System.Security.Principal.SecurityIdentifier($SecurityIdentifier)
        $objUser = $objSID.Translate([System.Security.Principal.NTAccount])
        $objUser
    } catch {
        throw $Error[0]
    }
}
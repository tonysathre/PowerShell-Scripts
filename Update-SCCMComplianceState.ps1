function Update-SCCMComplianceState {
    [CmdletBinding()]
    param (
        [string[]]$ComputerName = $env:COMPUTERNAME,
        
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    Invoke-Command @PSBoundParameters -ScriptBlock {
       'Refreshing compliance state...'

        try {
            (New-Object -ComObject Microsoft.CCM.UpdatesStore).RefreshServerComplianceState()
        }
        catch {
            throw $Error[0]
        }

        'Compliance state refreshed'
    }     
}


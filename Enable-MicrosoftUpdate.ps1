function Enable-MicrosoftUpdate {
    [CmdletBinding()]
    param (
        [string[]]$ComputerName = $env:COMPUTERNAME,
        
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    Invoke-Command @PSBoundParameters -ScriptBlock {
        "Enabling Microsoft Update . . ."
        try {
            $ServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager
            $ServiceManager.ClientApplicationID = 'My App'
            $NewUpdateService = $ServiceManager.AddService2('7971f918-a847-4430-9279-4a52d1efe18d', 7 ,'')
        }
        catch {
            throw $Error[0]
        }
        "Microsoft Update enabled."
    }
}
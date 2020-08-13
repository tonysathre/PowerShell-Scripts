function Get-TerminalServicesListenerCertificate {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
            [string[]]$ComputerName = $env:COMPUTERNAME,
        [Parameter(Mandatory=$false)]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.CredentialAttribute()]
            $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    BEGIN {}

    PROCESS {
        $Namespace = 'root\CIMv2\TerminalServices'
        $Class = 'Win32_TSGeneralSetting'

        foreach ($Computer in $ComputerName) {
            $GetHashParams = @{
                Namespace    = $Namespace
                Class        = $Class
                ComputerName = $Computer
                Credential   = $Credential
            }

            $SSLCertificateSHA1Hash = (Get-WmiObject @GetHashParams).SSLCertificateSHA1Hash

            if ($SSLCertificateSHA1Hash -ne '') {
                if ($Computer -eq $env:COMPUTERNAME -or $Computer -eq 'localhost') {
                    Write-Output $(Get-ChildItem -Path Cert:LocalMachine\ -Recurse | where Thumbprint -eq $SSLCertificateSHA1Hash | select *)    
                } else {
                    Invoke-Command -ComputerName $Computer -ScriptBlock {
                        Write-Output $(Get-ChildItem -Path Cert:LocalMachine\ -Recurse | where Thumbprint -eq $Using:SSLCertificateSHA1Hash | select *)
                    }
                }
            } else {
                Write-Warning "$Computer does not have a Terminal Services certificate configured."
            }
            }
        }

    END {}
}
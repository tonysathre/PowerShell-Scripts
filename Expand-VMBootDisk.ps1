function Expand-VMBootDisk {
    param (
        [CmdletBinding()]
        [Parameter(Mandatory)]
        [string]$VIServer,

        [Parameter(Mandatory)]
        [string[]]$VMName,

        [Parameter(Mandatory)]
        [uint64]$GBToAdd,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )
    
    BEGIN {
        try {
            Import-Module VMware.VimAutomation.Core
            $VIServerParams = @{
                Server = $VIServer
            }

            if ($PSBoundParameters.ContainsKey('Credential')) {
                $VIServerParams['Credential'] = $Credential
            }
            $VIServerConnection = Connect-VIServer @VIServerParams
        }

        catch {
            throw $Error[0]
        }
    }

    PROCESS {
        foreach ($VM in $VMName) {
            try {
                $V = Get-VM $VM
                # Extend VMDK
                $CapacityGB = $($V | Get-HardDisk | Where-Object Name -eq 'Hard Disk 1').CapacityGB
                Write-Verbose "Extending disk to $($CapacityGB + $GBToAdd) on $VM"
                $V | Get-HardDisk | Where-Object Name -eq 'Hard Disk 1' | Set-HardDisk -CapacityGB ($CapacityGB + $GBToAdd) -Confirm:$false

                # Extend filesystem
                $InvokeCommandParams = @{
                    ComputerName = $VM
                }

                if ($PSBoundParameters.ContainsKey('Credential')) {
                    $InvokeCommandParams['Credential'] = $Credential
                }

                Write-Verbose "Extending filesystem on $VM"
                Invoke-Command @InvokeCommandParams -ScriptBlock {
                    Set-Service -Name defragsvc -StartupType Manual -ErrorAction SilentlyContinue
                    $Disk = Get-Disk | Where-Object IsBoot -eq $true
                    Update-Disk -Number $Disk.Number
                    $Partition = $Disk | Get-Partition | Where-Object DriveLetter -eq 'C'
                    $MaxSize = $(Get-PartitionSupportedSize -DiskNumber $Disk.Number -PartitionNumber $Partition.PartitionNumber).SizeMax
                    Resize-Partition -DiskNumber $Disk.Number -PartitionNumber $Partition.PartitionNumber -Size $MaxSize
                }

            } catch {
                throw $Error
            }
        }
    }

    END {
        Disconnect-VIServer $VIServerConnection -Force -Confirm:$false -ErrorAction SilentlyContinue
    }
}
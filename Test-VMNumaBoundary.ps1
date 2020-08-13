#Requires -Modules VMware.VimAutomation.Core

function Test-VMNumaBoundary {
    param (
        [Parameter(Mandatory=$true)]
        [string]$VIServer,
        [string]$VM
    )

    try {
        $VIConnection = Connect-VIServer -Server $VIServer
        $report=@()

        if ($PSBoundParameters.ContainsKey('VM')) {
            $temp = Get-View -ViewType virtualmachine -Property name, runtime.host, config.hardware | where Name -eq $VM
        } else {
            $temp = Get-View -ViewType virtualmachine -Property name, runtime.host, config.hardware    
        }

        $temphost = Get-View -ViewType hostsystem -Property name, hardware.cpuinfo, hardware.MemorySize
        foreach ($a in $temp){
            $row = '' | select VMname, VMTotalvCPUs, VMSockets, VMCores, CPUCalcNumaNodes, MemCalcNumaNodes
            $row.VMname = $a.name
            $row.VMTotalvCPUs = $a.config.hardware.numcpu
            $row.VMsockets = ($a.config.hardware.numcpu) / ($a.config.hardware.NumCoresPerSocket)
            $row.VMcores = $a.config.hardware.NumCoresPerSocket
            $t = $temphost | where { $_.moref -eq $a.runtime.host }

            $nodesCalc = try {
                [System.Math]::ceiling($a.config.hardware.numcpu / ($t.hardware.cpuinfo.numcpucores / $t.hardware.cpuinfo.NumCpuPackages))
            }
            catch {}

            $row.CpuCalcNumaNodes = if ($nodesCalc -gt $t.hardware.cpuinfo.NumCpuPackages) {
                                        $t.hardware.cpuinfo.NumCpuPackages
                                    } else {
                                        $nodesCalc
                                    }

            $nodesCalc =            if (((($t.hardware.memorysize) / 1048576) / $t.hardware.cpuinfo.NumCpuPackages) -lt ($a.config.hardware.MemoryMB)) {
                                        $nodescalc + 1
                                    } else {
                                        $nodescalc
                                    }

            $row.MemCalcNumaNodes = if ($nodesCalc -gt $t.hardware.cpuinfo.NumCpuPackages) {
                                        $t.hardware.cpuinfo.NumCpuPackages
                                    } else {
                                        $nodesCalc
                                    }
            $report += $row
        }

        $VMSpanningNumaNodes = $report | where {($_.CPUCalcNumaNodes -ge 2) -or ($_.MemCalcNumaNodes -ge 2)}

        if ($VMSpanningNumaNodes -eq $null) {
            "No VM's spanning NUMA nodes"
        } else {
            $VMSpanningNumaNodes | Format-Table
        }
    }

    catch {
        throw $Error[0]
    }

    finally {
        Disconnect-VIServer -Server $VIConnection -Confirm:$false
    }
}
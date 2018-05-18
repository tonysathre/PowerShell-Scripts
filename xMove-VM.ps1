#Requires -Modules VMware.VimAutomation.Core
<#
.SYNOPSIS
   This script demonstrates an xVC-vMotion where a running Virtual Machine
   is live migrated between two vCenter Servers which are NOT part of the
   same SSO Domain which is only available using the vSphere 6.0 API.
   This script also supports live migrating a running Virtual Machine between
   two vCenter Servers that ARE part of the same SSO Domain (aka Enhanced Linked Mode)
   This script also supports migrating VMs connected to both a VSS/VDS as well as having multiple vNICs
.NOTES
   File Name  : xMove-VM.ps1
   Author     : William Lam - @lamw
   Version    : 1.0
.LINK
    http://www.virtuallyghetto.com/2016/05/automating-cross-vcenter-vmotion-xvc-vmotion-between-the-same-different-sso-domain.html
.LINK
   https://github.com/lamw
.INPUTS
   SourceVCConnection, DestVCConnection, vm, switchtype, switch,
   cluster, datastore, vmhost, vmnetworks,
.OUTPUTS
   Console output
#>

function xMove-VM {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, HelpMessage='The name of the source VM to be migrated')]
        [string]$VM,

        [Parameter(Mandatory=$true, Position = 1, HelpMessage='The hostname or IP Address of the source vCenter Server')]
        [string]$SourceVC,

        [Parameter(Mandatory=$true, Position = 2)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]$SourceVCCredential,

        [Parameter(Mandatory=$true, HelpMessage='The hostname or IP Address of the destination vCenter Server')]
        [string]$DestVC,

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]$DestVCCredential,
    
        [Parameter(Mandatory=$true)]
        [ValidateSet('VSS', 'VDS')][string]$SwitchType,

        [Parameter(Mandatory=$true, HelpMessage='Name of the destination vSwitch')]
        [string]$Switch,

        [Parameter(Mandatory=$true, HelpMessage='The destination vSphere Cluster where the VM will be migrated to')]
        [string]$Cluster,

        #[Parameter(Mandatory=$true, HelpMessage='The destination vSphere Datastore where the VM will be migrated to')]
        #[string]$Datastore,

        [Parameter(Mandatory=$true, HelpMessage='The destination vSphere ESXi host where the VM will be migrated to')]
        [string]$VMhost,

        [Parameter(Mandatory=$true, HelpMessage='The destination vSphere VM Portgroup where the VM will be migrated to')]
        [string]$VMnetworks,

        [switch]$ScheduleCompatibilityUpgrade,

        [switch]$UpgradeVMTools

    )

<#
    DynamicParam {
        $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary


        $paramVM            = New-Object -Type System.Management.Automation.RuntimeDefinedParameter
        $paramVM_Attributes = New-Object System.Management.Automation.ParameterAttribute
  
        $paramVM.Name  = 'VM'
        $paramVM.ParameterType  = [string]
        $paramVM_Attributes.ParameterSetName = '__AllParameterSets'
        $paramVM_Attributes.Mandatory = $true

        if (!$SourceVC -eq $null -and !$SourceVCCredential -eq $null) {

            $TempVIConnection = Connect-VIServer -Server $SourceVC -Credential $SourceVCCredential
            $VMset = Get-VM -Server $SourceVC | select -ExpandProperty Name
            $TempVIConnection | Disconnect-VIServer -Force:$true
        } else {
            $VMset = @('Set -SourceVC and -SourceVCCredential first for auto-completion')
        }

        $paramVM_ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $Error[0].Exception
  
        $paramVM.Attributes.Add($paramVM_Attributes)
        $paramVM.Attributes.Add($paramVM_ValidateSet)
        $paramDictionary.Add($paramVM.Name, $paramVM)


        
        $paramCluster            = New-Object -Type System.Management.Automation.RuntimeDefinedParameter
        $paramCluster_Attributes = New-Object System.Management.Automation.ParameterAttribute

        $paramCluster.Name  = 'Cluster'
        $paramCluster.ParameterType  = [string]
        $paramCluster_Attributes.ParameterSetName = '__AllParameterSets'
        $paramCluster_Attributes.Mandatory = $true

        if ($DestVC -ne $null -and $DestVCCredential -ne $null) {
            $TempVIConnection1 = Connect-VIServer -Server $DestVC -Credential $DestVCCredential
            $Clusterset = Get-Cluster -Location $DestVC | select -ExpandProperty Name
            $TempVIConnection1 | Disconnect-VIServer -Force:$false
        } else {
            $Clusterset = @('Set -DestVC and -DestVCCredential first for auto-completion')
        }

        $paramCluster_ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $Clusterset
  
        $paramCluster.Attributes.Add($paramCluster_Attributes)
        $paramCluster.Attributes.Add($paramCluster_ValidateSet)
        $paramDictionary.Add($paramCluster.Name, $paramCluster)
        
        return $paramDictionary
    }
#>

BEGIN {}

    PROCESS {
        $ErrorActionPreference = 'Stop'
        try {
            $SourceVCConn = Connect-VIServer -Server $SourceVC -Credential $SourceVCCredential
            $DestVCConn = Connect-VIServer -Server $DestVC -Credential $DestVCCredential

            # Retrieve Source VC SSL Thumbprint
            $vcurl = "https://" + $DestVC
add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
            public class IDontCarePolicy : ICertificatePolicy {
            public IDontCarePolicy() {}
            public bool CheckValidationResult(
                ServicePoint sPoint, X509Certificate cert,
                WebRequest wRequest, int certProb) {
                return true;
            }
        }
"@
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object IDontCarePolicy
            # Need to do simple GET connection for this method to work
            Invoke-RestMethod -Uri $vcurl -Method Get | Out-Null

            $endpoint_request = [System.Net.Webrequest]::Create("$vcurl")
            # Get Thumbprint + add colons for a valid Thumbprint
            $DestVCThumbprint = ($endpoint_request.ServicePoint.Certificate.GetCertHashString()) -replace '(..(?!$))','$1:'

            # Source VM to migrate
            $VM_view = Get-View (Get-VM -Server $SourceVC -Name $VM) -Property Config.Hardware.Device

            # Dest Datastore to migrate VM to
            $Datastore = (Get-VM -Server $SourceVC -Name $VM | Get-Datastore).Name
            $Datastore_view = (Get-Datastore -Server $DestVCConn -Name $Datastore)

            # Dest Cluster to migrate VM to
            $Cluster_view = (Get-Cluster -Server $DestVCConn -Name $Cluster)

            # Dest ESXi host to migrate VM to
            $VMhost_view = (Get-VMHost -Server $DestVCConn -Name $VMhost)

            # Find all Etherenet Devices for given VM which
            # we will need to change its network at the destination
            $VMNetworkAdapters = @()
            $devices = $VM_view.Config.Hardware.Device
            foreach ($device in $devices) {
                if($device -is [VMware.Vim.VirtualEthernetCard]) {
                    $VMNetworkAdapters += $device
                }
            }

            # Relocate Spec for Migration
            $spec = New-Object VMware.Vim.VirtualMachineRelocateSpec
            $spec.datastore = $Datastore_view.Id
            $spec.host = $VMhost_view.Id
            $spec.pool = $Cluster_view.ExtensionData.ResourcePool

            # Service Locator for the destination vCenter Server
            # regardless if its within same SSO Domain or not
            $service = New-Object VMware.Vim.ServiceLocator
            $ServiceLocatorNamePassword = New-Object VMware.Vim.ServiceLocatorNamePassword
            $ServiceLocatorNamePassword.username = $DestVCCredential.UserName
            $ServiceLocatorNamePassword.password = $DestVCCredential.GetNetworkCredential().Password
            $service.credential = $ServiceLocatorNamePassword
            # If you get the following error message:
            # The operation for the entity "VM" failed with the following message: "A specified parameter was not correct: ServiceLocator.instanceUuid"
            # Change $service.instanceUuid = $DestVCConn.InstanceUuid to $service.instanceUuid = $DestVCConn.InstanceUuid.ToUpper()
            $service.instanceUuid = $DestVCConn.InstanceUuid
            $service.sslThumbprint = $DestVCThumbprint
            $service.url = "https://$DestVC"
            $spec.service = $service

            # Create VM spec depending if destination networking
            # is using Distributed Virtual Switch (VDS) or
            # is using Virtual Standard Switch (VSS)
            $count = 0
            if($SwitchType -eq "VDS") {
                foreach ($VMNetworkAdapter in $VMNetworkAdapters) {
                    # New VM Network to assign vNIC
                    $VMnetworkname = ($VMnetworks -split ",")[$count]

                    # Extract Distributed Portgroup required info
                    $dvpg = Get-VirtualPortGroup -Server $DestVC -Name $VMnetworkname
                    $vds_uuid = (Get-View $dvpg.ExtensionData.Config.DistributedVirtualSwitch).Uuid
                    $dvpg_key = $dvpg.ExtensionData.Config.key

                    # Device Change spec for VSS portgroup
                    $dev = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $dev.Operation = "edit"
                    $dev.Device = $VMNetworkAdapter
                    $dev.device.Backing = New-Object VMware.Vim.VirtualEthernetCardDistributedVirtualPortBackingInfo
                    $dev.device.backing.port = New-Object VMware.Vim.DistributedVirtualSwitchPortConnection
                    $dev.device.backing.port.switchUuid = $vds_uuid
                    $dev.device.backing.port.portgroupKey = $dvpg_key
                    $spec.DeviceChange += $dev
                    $count++
                }
            } else {
                foreach ($VMNetworkAdapter in $VMNetworkAdapters) {
                    # New VM Network to assign vNIC
                    $VMnetworkname = ($VMnetworks -split ",")[$count]

                    # Device Change spec for VSS portgroup
                    $dev = New-Object VMware.Vim.VirtualDeviceConfigSpec
                    $dev.Operation = "edit"
                    $dev.Device = $VMNetworkAdapter
                    $dev.device.backing = New-Object VMware.Vim.VirtualEthernetCardNetworkBackingInfo
                    $dev.device.backing.deviceName = $VMnetworkname
                    $spec.DeviceChange += $dev
                    $count++
                }
            }

            Write-Host "`nMigrating $VM from $SourceVC to $DestVC ...`n"

            # Issue Cross VC-vMotion
            $task = $VM_view.RelocateVM_Task($spec,"defaultPriority")
            $task1 = Get-Task -Id ("Task-$($task.value)")
            $task1 | Wait-Task -Verbose

            $NewVM = Get-VM -Server $DestVC -Name $VM

            if ($ScheduleCompatibilityUpgrade) {
                Write-Host 'Scheduling compatibility upgrade'
                $NewVM.ExtensionData.Config.ScheduledHardwareUpgradeInfo
                $spec = New-Object -TypeName VMware.Vim.VirtualMachineConfigSpec
                $spec.ScheduledHardwareUpgradeInfo = New-Object -TypeName VMware.Vim.ScheduledHardwareUpgradeInfo
                $spec.ScheduledHardwareUpgradeInfo.UpgradePolicy = 'always' #Change this to 'always' to actually do the upgrade
                $spec.ScheduledHardwareUpgradeInfo.VersionKey = 'vmx-11'
                $spec.ScheduledHardwareUpgradeInfo.ScheduledHardwareUpgradeStatus = 'pending'
                $NewVM.ExtensionData.ReconfigVM_Task($spec)
            }

            if ($UpgradeVMTools) {
                Write-Host 'Upgrading VMware Tools'
                Update-Tools -VM $NewVM -NoReboot -RunAsync
            }

            Write-Verbose -Message "$(Get-Date -Format 'G') `tMigration of VM $VM Completed successfully" -Verbose
        }

        catch  {
            throw $Error[0]
        }

        finally {
            Write-Host "`nDisconnecting from vCenter servers $SourceVC and $DestVC"
            Disconnect-VIServer -Server $SourceVCConn, $DestVCConn -Confirm:$false
        }
    }

    END {}
}
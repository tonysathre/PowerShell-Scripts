#Requires -RunAsAdministrator
param (
    [Parameter(Mandatory=$true)]
        [switch]$Enabled
)

try {
    $Namespace = 'root\ccm\policy\machine\requestedconfig'
    $Class = 'CCM_SoftwareDistributionClientConfig'
    $SoftwareDistributionAgent = (Get-WmiObject -Namespace $Namespace -Class $Class)
    
    if ($SoftwareDistributionAgent -is [array]) {
        $SoftwareDistributionAgent = $SoftwareDistributionAgent[0]
    }

    $Properties = @{
        ComponentName   = 'Disable Software Distribution Agent'
        Enabled         = $Enabled.ToBool()
        PolicySource    = 'Local'
        PolicyVersion   = '1.0'
        PolicyID        = 'DisableSoftwareDist'
        SiteSettingsKey = '1'
    }
    
    Set-WmiInstance -InputObject $SoftwareDistributionAgent -Arguments $Properties -PutType UpdateOrCreate
}
catch {
    throw $Error[0]
}
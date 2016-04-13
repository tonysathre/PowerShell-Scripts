#Requires -RunAsAdministrator
param (
    [Parameter(Mandatory=$true)]
        [switch]$Enabled
)

try {
    $Namespace = 'root\ccm\policy\machine\requestedconfig'
    $Class = 'CCM_ApplicationManagementClientConfig'
    $ApplicationManagementAgent = (Get-WmiObject -Namespace $Namespace -Class $Class)

    if ($ApplicationManagementAgent -is [array]) {
        $ApplicationManagementAgent = $ApplicationManagementAgent[0]
    }

    $Properties = @{
        ComponentName   = 'Disable Application Deployment Agent'
        Enabled         = $Enabled.ToBool()
        PolicySource    = 'Local'
        PolicyVersion   = '1.0'
        PolicyID        = 'DisableAppDeployment'
        SiteSettingsKey = '1'
    }

    Set-WmiInstance -InputObject $ApplicationManagementAgent -Arguments $Properties -PutType UpdateOrCreate
}
catch {
    throw $Error[0]
}
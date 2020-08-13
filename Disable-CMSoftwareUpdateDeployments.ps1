function Disable-CMSoftwareUpdateDeployments {
    param (
        [Parameter(Mandatory]
        [string]$CMSiteServer,

        [Parameter(Mandatory]
        [string]$CMSiteCode
    )

    try {
        $SUPDeployment = Get-WmiObject -Namespace "ROOT\SMS\Site_$CMSiteCode" -Class SMS_UpdatesAssignment -ComputerName $CMSiteServer -ErrorAction Stop

        $DeploymentsToDisable = $SUPDeployment | where AssignmentName -Like 'COM - Servers*'

        foreach ($Deployment in $DeploymentsToDisable.GetEnumerator()) {
            if ($Deployment.Enabled) {
                $CollectionName = Get-WmiObject -Namespace "ROOT\SMS\Site_$CMSiteCode" -Class SMS_Collection -ComputerName $CMSiteServer -Filter "CollectionID = '$($Deployment.TargetCollectionID)'" | select -ExpandProperty Name
                "Disabling assignment {0} assigned to collection {1}" -f $Deployment.AssignmentName, $CollectionName
                $Deployment.Enabled = $false
                $Deployment.Put() | Out-Null
            }
        }
    }
    catch {
        throw $_.Exception.Message
    }
}
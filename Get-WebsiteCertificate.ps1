function Get-WebsiteCertificate
{
    [OutputType([byte[]])]
    param (
        [Parameter(Mandatory=$true)]
        [Uri]$Uri,
        $Path = (Join-Path $PWD (($Uri -split '//')[1]).cer),
        [switch]$Force # Ignore certificate warnings
    )

    if (-Not ($Uri.Scheme -eq 'https'))
    {
        Write-Error 'You can only get keys for https addresses'
        return
    }

    # Ignore certificate warnings
    if ($Force) {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    }

    $WebRequest = [Net.WebRequest]::Create($Uri)
    try { 
        $WebRequest.GetResponse()
    } 
    catch {
        throw $Error[0]
    }

    $Certificate = $WebRequest.ServicePoint.Certificate
    $bytes = $Certificate.Export([Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    Set-Content '-BEGIN CERTIFICATE-' -Path $Path
    Add-Content -Value $bytes -Encoding byte -Path $Path
    Set-Content '-END CERTIFICATE-' -Path $Path
    "Certificate saved to file $Path"
}
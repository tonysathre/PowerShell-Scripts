#Requires -Modules VMware.VimAutomation.Core
#Requires -PSSnapin Citrix.Broker.Admin.V2

function Update-BrokerMachineUuid {
    param (
        [Parameter(Mandatory=$true)]
        [string]$VIServer,
        
        [Parameter(Mandatory=$true)]
        [string[]]$MachineName,

        [Parameter(Mandatory=$true)]
        [string]$AdminAddress,

        [string]$NetBIOSDomainName = 'OSKGLOBAL'
    )

    try {

        $VIServerConnection = Connect-VIServer -Server $VIServer
        $VMBiosUuid = (Get-VM $MachineName).ExtensionData.config.uuid
        $CitrixUuid = Get-BrokerMachine -AdminAddress $AdminAddress -MachineName $NetBIOSDomainName\$MachineName | select -ExpandProperty HostedMachineId

        $VM = Get-VM $MachineName
        if ($VMBiosUuid -ne $CitrixUuid) {
            if ((Get-VM $VM).PowerState -eq 'PoweredOn') {
                throw 'VM not powered off'
            } else {
                $section = $CitrixUuid.Split("-")

                $j=0
                ForEach ($i in $section) {
                   $k = $i -split '(..)' | ? { $_ }
                   $section[$j] = $k -join(' ')
                   $j++
                }
            
                $vmxUUID =  $section[0] + ' ' + $section[1] + ' ' + $section[2] + '-' + $section[3] + ' ' + $section[4]
                $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
                $spec.uuid = $vmxUUID
                $VM.Extensiondata.ReconfigVM_Task($spec)
                (Get-VM $MachineName | Get-View).reload()
            }
        }

    }

    catch {
        throw $Error[0]
    }

    finally {
        Disconnect-VIServer -Server $VIServer -Confirm:$false
    }
}
# SIG # Begin signature block
# MIIT+QYJKoZIhvcNAQcCoIIT6jCCE+YCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUt7gFgP3f16M/c9F0q4+t/FDs
# q/agghFRMIIErzCCA5egAwIBAgIKN7ADfQAAAAAALjANBgkqhkiG9w0BAQ0FADBa
# MRMwEQYKCZImiZPyLGQBGRYDY29tMR0wGwYKCZImiZPyLGQBGRYNb3Noa29zaGds
# b2JhbDEkMCIGA1UEAxMbb3Noa29zaGdsb2JhbC1FTlRQS0lTUDA0LUNBMB4XDTE5
# MTAzMTE0NDE1MVoXDTM0MTAzMTE0NTE1MVowWjETMBEGCgmSJomT8ixkARkWA2Nv
# bTEdMBsGCgmSJomT8ixkARkWDW9zaGtvc2hnbG9iYWwxJDAiBgNVBAMTG29zaGtv
# c2hnbG9iYWwtRU5UUEtJU1AwNS1DQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBALubfk2U9ID8tvMFy8Iyo72/a8G4KGVMlRwJzth57VorTc9dT69PFqFt
# FW/qHdzggTZjs6DQ1nUdIW7PLAYklfAXoxNn2b1t/k+Qxu4JhREbsyQkHis+l9lQ
# 6MuP1HH8lpWw2WsonG++Vvh1/Ax6qKjbVJhw/e5JsY7XHtqpSCFYZe4RnMWLPRiZ
# gxkeHuXiKqHFyC19y9vJ92Nsf+KJ28LMfIDN9deo7za1F93n/HRWU1ORWcPjyQsy
# QUU+J/WPTW0UFauWrib2VDOtnhcIPW7Q0ZjuPqytRla78byXQVCdSV8ZKQq2/W0D
# FD85nYho87TGQ5jR7+LMoqp8xzZNVQ8CAwEAAaOCAXUwggFxMBIGCSsGAQQBgjcV
# AQQFAgMDAAUwIwYJKwYBBAGCNxUCBBYEFIWMjP1z1fzyP/GHspsyJ7U6cHCnMB0G
# A1UdDgQWBBTqPIU5HsRxYTrwvGWpFCV6csU14jAZBgkrBgEEAYI3FAIEDB4KAFMA
# dQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAW
# gBSMu5F8R3aNvJE1cytgbA592IreCzBYBgNVHR8EUTBPME2gS6BJhkdodHRwOi8v
# cGtpLm9zaGtvc2hnbG9iYWwuY29tL0NlcnRFbnJvbGwvb3Noa29zaGdsb2JhbC1F
# TlRQS0lTUDA0LUNBLmNybDBjBggrBgEFBQcBAQRXMFUwUwYIKwYBBQUHMAKGR2h0
# dHA6Ly9wa2kub3Noa29zaGdsb2JhbC5jb20vQ2VydEVucm9sbC9vc2hrb3NoZ2xv
# YmFsLUVOVFBLSVNQMDQtQ0EuY3J0MA0GCSqGSIb3DQEBDQUAA4IBAQAXPiK7ng8V
# LVpYwhgbwytrM3EzUg+TxaBk/OWq0ssLGrMuE5IRuewHKl/72fpqaDetBKQvZ5WC
# u445BB/VQIGwoMvT8mK+MuMaARjursn2v/3RYyRtp8nEb3faI9icPoNokkRQtPDI
# fshgjmnwwHy77bJwaQ2Px2m08dIPaiutSAKS7Y+CTKk69ywGugRBSHq4WuQGaeN3
# C2GBw2qlfVIsEKgG8nlLH09Bajtm9FIryFK7mD7Hm48nhiorYWO7V0t9Px4b5Quy
# SBCoRqi1ybwG9fo1Tx17MOoTz7nHnk9x26wtu/WL+Tjx8foBZkQu+aW3yWXvxVig
# 4flIR8FVmFQKMIIEszCCA5ugAwIBAgIKYQhOSAAFAAAAXzANBgkqhkiG9w0BAQ0F
# ADBaMRMwEQYKCZImiZPyLGQBGRYDY29tMR0wGwYKCZImiZPyLGQBGRYNb3Noa29z
# aGdsb2JhbDEkMCIGA1UEAxMbb3Noa29zaGdsb2JhbC1FTlRQS0lTUDA1LUNBMB4X
# DTE5MTAzMTE1MTMxMFoXDTI0MTAzMTE1MjMxMFowWjETMBEGCgmSJomT8ixkARkW
# A2NvbTEdMBsGCgmSJomT8ixkARkWDW9zaGtvc2hnbG9iYWwxJDAiBgNVBAMTG29z
# aGtvc2hnbG9iYWwtRU5UUEtJU1AwOS1DQTCCASIwDQYJKoZIhvcNAQEBBQADggEP
# ADCCAQoCggEBAMDqeT1g7hQbhTElOz8xVda7m/v89mK+ZzV7ATkMj6vnGvhwbWaf
# wy8Vgw7vhlUWclEcgvIrrxRL4bAD/Eg901KSpdwdCGaJ0g1OoiKs/eLzc9Mei2nF
# 7rMtWgR3R0oOPdX9I/WaEUHXEnS1DfcYojsxWn4d6XkwiSN1BK1+6SDxbqcGQMLC
# cEq80I6Dzi6PXAMeTSxrxSOsTdvFWAfn6cqVhw5/n7/F7h0RpvVmaAnz1IycV35E
# S/a4HIFYaQOV/hYN6KUuQatXpZe9VoGOKEYXB8gRcbrneMt3FiM8ED4V34YzK3OD
# enf8MoveQaFri6hJnP52Gk6FXwgBvaS/sWsCAwEAAaOCAXkwggF1MBAGCSsGAQQB
# gjcVAQQDAgEBMCMGCSsGAQQBgjcVAgQWBBTDBntWljb5tY1jGgZByYBEXJOr2DAd
# BgNVHQ4EFgQUox1R5dVxn0x6MoAVfCX7UqBTDpIwGQYJKwYBBAGCNxQCBAweCgBT
# AHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgw
# FoAU6jyFOR7EcWE68LxlqRQlenLFNeIwWwYDVR0fBFQwUjBQoE6gTIZKaHR0cDov
# L3BraS5vc2hrb3NoZ2xvYmFsLmNvbS9DZXJ0RW5yb2xsL29zaGtvc2hnbG9iYWwt
# RU5UUEtJU1AwNS1DQSgzKS5jcmwwZgYIKwYBBQUHAQEEWjBYMFYGCCsGAQUFBzAC
# hkpodHRwOi8vcGtpLm9zaGtvc2hnbG9iYWwuY29tL0NlcnRFbnJvbGwvb3Noa29z
# aGdsb2JhbC1FTlRQS0lTUDA1LUNBKDUpLmNydDANBgkqhkiG9w0BAQ0FAAOCAQEA
# MTcqMVj8R862piBGv85jxHpsa9f1W+3p7I8dlx8wZc5MUl1Dm33DJ7yPg35q95GO
# 5XNN5jGA2HQYqwvGSmZIIyE2lf+a8uhFaQuLBGTHkUKzNRaGSOtfFYcN9Rfwh50a
# +Ek8NRSz+Qb11SiutIrzogOttTePzWrqTrgWNllnmmSWu+KvMhwfyuy0NRNYI4IZ
# BqG+uJW3uP/E8lzaVjMytd7/DSUdoMXAz8b9XXkuiuGTITUxjlryf8pZNa1KNXuM
# 3ZGmh7f+7scUz+dxj7KYOV+b5MoQe82LLHnboaJTXFjH5yJKynB28k/A2xpOo0Cm
# wgPQETnjDAAlEBeoFVO1ijCCB+MwggbLoAMCAQICE3IAAAsoxHnZQ4a4L68AAAAA
# CygwDQYJKoZIhvcNAQENBQAwWjETMBEGCgmSJomT8ixkARkWA2NvbTEdMBsGCgmS
# JomT8ixkARkWDW9zaGtvc2hnbG9iYWwxJDAiBgNVBAMTG29zaGtvc2hnbG9iYWwt
# RU5UUEtJU1AwOS1DQTAeFw0xOTEwMDcxNjEyNDNaFw0yMDEwMDYxNjEyNDNaMIGw
# MRMwEQYKCZImiZPyLGQBGRYDY29tMR0wGwYKCZImiZPyLGQBGRYNb3Noa29zaGds
# b2JhbDERMA8GA1UECxMIU0VSVklDRVMxEjAQBgNVBAsTCUNPUlBPUkFURTEZMBcG
# A1UECxMQU2VnbWVudCBTZXJ2aWNlczEhMB8GA1UECxMYU2VnbWVudCBTZXJ2aWNl
# IEFjY291bnRzMRUwEwYDVQQDEwxFTlRTVldOUFNQMDEwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQC7lkwchQY0wrRO35BEGs/6mAIuY5OD7e+ii+SFIg8D
# MDFMzjjKunU4zHHiIPXKuRSgFnvuoDrAOFJ9AtXD2eizyz6BqYBRbBYcs19CkuTd
# 5smB9S0NdJcF+RkOz4COrsu+rMUBD4yWzFDJ6gMTUK/jCnQbyJ/heOx41EJh0ilW
# sHO3V7vnQfvKQ/l+Iy9UnnCWmIOln5lGeSauriWO0PS/bLaGfcg2kDwviDzy75bH
# C1sWCCf99AKV1u0yKKT2cwzIvOqvg2HPEgU/H+cj4w3wqBOJYawo4GxYNWXSYPmS
# 1Nr9r3DqUIeFcCr8MF2bpd8Qry8uJ9w2b+2jnX451H+zAgMBAAGjggRJMIIERTA+
# BgkrBgEEAYI3FQcEMTAvBicrBgEEAYI3FQiDq+QZhaj5YIGdgzWHzOwvgYnCVIEJ
# g9mwOYHDxVoCAWQCARwwEwYDVR0lBAwwCgYIKwYBBQUHAwMwDgYDVR0PAQH/BAQD
# AgeAMBsGCSsGAQQBgjcVCgQOMAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFOTieNNa
# TKp4UY6ALFpQ26lx3MDOMB8GA1UdIwQYMBaAFKMdUeXVcZ9MejKAFXwl+1KgUw6S
# MIIBgAYDVR0fBIIBdzCCAXMwggFvoIIBa6CCAWeGgctsZGFwOi8vL0NOPW9zaGtv
# c2hnbG9iYWwtRU5UUEtJU1AwOS1DQSxDTj1FTlRQS0lTUDA5LENOPUNEUCxDTj1Q
# dWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0
# aW9uLERDPW9zaGtvc2hnbG9iYWwsREM9Y29tP2NlcnRpZmljYXRlUmV2b2NhdGlv
# bkxpc3Q/YmFzZT9vYmplY3RDbGFzcz1jUkxEaXN0cmlidXRpb25Qb2ludIZOaHR0
# cDovL0VOVFBLSVNQMDkub3Noa29zaGdsb2JhbC5jb20vQ2VydEVucm9sbC9vc2hr
# b3NoZ2xvYmFsLUVOVFBLSVNQMDktQ0EuY3JshkdodHRwOi8vcGtpLm9zaGtvc2hn
# bG9iYWwuY29tL0NlcnRFbnJvbGwvb3Noa29zaGdsb2JhbC1FTlRQS0lTUDA5LUNB
# LmNybDCCAcAGCCsGAQUFBwEBBIIBsjCCAa4wgcAGCCsGAQUFBzAChoGzbGRhcDov
# Ly9DTj1vc2hrb3NoZ2xvYmFsLUVOVFBLSVNQMDktQ0EsQ049QUlBLENOPVB1Ymxp
# YyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24s
# REM9b3Noa29zaGdsb2JhbCxEQz1jb20/Y0FDZXJ0aWZpY2F0ZT9iYXNlP29iamVj
# dENsYXNzPWNlcnRpZmljYXRpb25BdXRob3JpdHkwdwYIKwYBBQUHMAKGa2h0dHA6
# Ly9FTlRQS0lTUDA5Lm9zaGtvc2hnbG9iYWwuY29tL0NlcnRFbnJvbGwvRU5UUEtJ
# U1AwOS5vc2hrb3NoZ2xvYmFsLmNvbV9vc2hrb3NoZ2xvYmFsLUVOVFBLSVNQMDkt
# Q0EuY3J0MHAGCCsGAQUFBzAChmRodHRwOi8vcGtpLm9zaGtvc2hnbG9iYWwuY29t
# L0NlcnRFbnJvbGwvRU5UUEtJU1AwOS5vc2hrb3NoZ2xvYmFsLmNvbV9vc2hrb3No
# Z2xvYmFsLUVOVFBLSVNQMDktQ0EuY3J0MDkGA1UdEQQyMDCgLgYKKwYBBAGCNxQC
# A6AgDB5FTlRTVldOUFNQMDFAb3Noa29zaGdsb2JhbC5jb20wDQYJKoZIhvcNAQEN
# BQADggEBAL5bAaweHGa4j8w3FgjkEYl95wGZge7qsy2+KsDpSS30ahceAgQiTETd
# PzE6l5qe+RlESeAaidr7EABUAtPQaZkHB81RqeEHMD9vsp8Bj9AXwyVpHRO/V8Kj
# m5fRO8xYo6ngVIsIUjlUstm0tcecT08t3egJ+iXqwffYG6tSWspV9ElKvB/ckEBR
# uc5cpzAeo97pOc1no/20z9/qGxON3vGdalNx5xY54BbHLbY/b4QUa+mYyZgp19M9
# U9Uys4hSm7Rh/Qjdny0/EV+Bo02COl0TIjmTZMkwEOGJ94JRZo0hcvnXELD1iS/F
# h1PFYCnI1IqPmhWXWcWW6dWXvJcwHXAxggISMIICDgIBATBxMFoxEzARBgoJkiaJ
# k/IsZAEZFgNjb20xHTAbBgoJkiaJk/IsZAEZFg1vc2hrb3NoZ2xvYmFsMSQwIgYD
# VQQDExtvc2hrb3NoZ2xvYmFsLUVOVFBLSVNQMDktQ0ECE3IAAAsoxHnZQ4a4L68A
# AAAACygwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFGp6lc/WJ8/6RYf3/63kywFZ/fpjMA0GCSqG
# SIb3DQEBAQUABIIBAJ4r7eATujrY2ZUwF2F1yla6lZAsFmkCWsk+NgilhgKEAqGb
# seyUDB3/YOb4hwKxMidhv/4rTzOzABrxN5Xh4Mk2ZBMVIHMA5Z1Laag3KEb9Qe7w
# M7bCKqLn+W+mv79dz5wznLx3PfQjtK2ClV+m113f4+HPIlqa8u71tM6jvXJn+mOG
# eqoYGxbQCKvJAvVovqSzbsF0tkYCheueob0ND8y5+6WV7byGsrl1FwF7hqX4FzHj
# BoBZarSV5f9Mo580Sau11TX/pWIklN+bGuwOOF4H0Khn+iXeIrc1z6A/18ZxAem+
# nfkLtlO3Ba953Q+je1R8P9PTNl0aRoWb1V0sb3A=
# SIG # End signature block

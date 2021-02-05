Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging


    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Azure Core Usage' -Theme Dark


    # set the home page controls
    $tabs = New-PodeWebTabs -Tabs @(
        New-PodeWebTab -Name 'West Europe' -Layouts @(
            New-PodeWebCard -NoTitle -Content @(
                @(foreach ($quota in (az vm list-usage --location westeurope | ConvertFrom-Json)) {
                    if ($quota.currentValue -gt 0) {
                        New-PodeWebProgress -Name $quota.localName -Id $quota.name.value -Value $quota.currentValue -Max $quota.limit -ShowValue
                    }
                }) | Sort-Object -Property { $_.Value } -Descending
            )
        )

        New-PodeWebTab -Name 'Central US' -Layouts @(
            New-PodeWebCard -NoTitle -Content @(
                @(foreach ($quota in (az vm list-usage --location centralus | ConvertFrom-Json)) {
                    if ($quota.currentValue -gt 0) {
                        New-PodeWebProgress -Name $quota.localName -Id $quota.name.value -Value $quota.currentValue -Max $quota.limit -ShowValue
                    }
                }) | Sort-Object -Property { $_.Value } -Descending
            )
        )

        New-PodeWebTab -Name 'Japan East' -Layouts @(
            New-PodeWebCard -NoTitle -Content @(
                @(foreach ($quota in (az vm list-usage --location japaneast | ConvertFrom-Json)) {
                    if ($quota.currentValue -gt 0) {
                        New-PodeWebProgress -Name $quota.localName -Id $quota.name.value -Value $quota.currentValue -Max $quota.limit -ShowValue
                    }
                }) | Sort-Object -Property { $_.Value } -Descending
            )
        )

        New-PodeWebTab -Name 'UK South' -Layouts @(
            New-PodeWebCard -NoTitle -Content @(
                @(foreach ($quota in (az vm list-usage --location uksouth | ConvertFrom-Json)) {
                    if ($quota.currentValue -gt 0) {
                        New-PodeWebProgress -Name $quota.localName -Id $quota.name.value -Value $quota.currentValue -Max $quota.limit -ShowValue
                    }
                }) | Sort-Object -Property { $_.Value } -Descending
            )
        )
    )

    Set-PodeWebHomePage -NoAuth -Layouts $tabs
}
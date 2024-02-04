Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'IFrame Example' -Theme Dark

    $con1 = New-PodeWebContainer -Content @(
        1..3 |  ForEach-Object {
            New-PodeWebButton -Name "Page$_" -ScriptBlock {
                Update-PodeWebIFrame -Name 'IFrame' -Url "/pages/$($ElementData.Name)"
            }
        }
    )

    $con2 = New-PodeWebContainer -Content @(
        New-PodeWebIFrame -Name 'IFrame' -Url '/pages/Page1'
    )

    Add-PodeWebPage -Name 'Example' -Content $con1, $con2

    1..3 |  ForEach-Object {
        Add-PodeWebPage -Name "Page$_" -Hide -Content @(
            New-PodeWebContainer -Content @(
                New-PodeWebText -Value "Page$_!"
            )
        )
    }
}
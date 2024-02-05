Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Basic tabs' -Theme Dark
    
    $tabs = New-PodeWebTabs -ActiveTab Tab2 -Tabs @(
        New-PodeWebTab -Name Tab1 -Content @(
            New-PodeWebContainer -Content @(
                New-PodeWebText -Value 'Hello World'
            )
        )
        New-PodeWebTab -Name Tab2 -Content @(
            New-PodeWebContainer -Content @(
                New-PodeWebText -Value 'Hello There'
            )
        )
        New-PodeWebTab -Name Tab3 -Content @(
            New-PodeWebContainer -Content @(
                New-PodeWebText -Value 'HI!'
            )
        )
    )
    
    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Content $tabs -Title 'Tabs'
}
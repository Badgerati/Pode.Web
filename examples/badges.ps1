Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Badges' -Theme Dark

    # set the home page controls (just a simple paragraph)
    $card = New-PodeWebCard -Content @(
        New-PodeWebBadge -Value 'Primary' -Colour Blue
        New-PodeWebBadge -Value 'Secondary' -Colour Grey
        New-PodeWebBadge -Value 'Success' -Colour Green
        New-PodeWebBadge -Value 'Danger' -Colour Red
        New-PodeWebBadge -Value 'Warning' -Colour Yellow
        New-PodeWebBadge -Value 'Info' -Colour Cyan
        New-PodeWebBadge -Value 'Light' -Colour Light
        New-PodeWebBadge -Value 'Dark' -Colour Dark
    )

    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Content $card -Title 'Badges'
}
Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Inputs' -Theme Dark

    # set the home page controls (just a simple paragraph)
    $card = New-PodeWebCard -Content @(
        New-PodeWebAlert -Type Note -Value 'Hello, world'
        New-PodeWebAlert -Type Tip -Value 'Hello, world'
        New-PodeWebAlert -Type Important -Value 'Hello, world'
        New-PodeWebAlert -Type Info -Value 'Hello, world'
        New-PodeWebAlert -Type Warning -Value 'Hello, world'
        New-PodeWebAlert -Type Error -Value 'Hello, world'
        New-PodeWebAlert -Type Success -Value 'Hello, world'
    )

    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Content $card -Title 'Alerts'
}
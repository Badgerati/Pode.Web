Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Import-Module ./misc/functions.psm1

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging


    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Functions' -RootRedirect

    Export-PodeModule -Name 'functions'

    # convert module to pages
    ConvertTo-PodeWebPage -Commands 'Get-Noun'
}
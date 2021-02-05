Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer -StatusPageExceptions Show {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging


    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Code Editor' -Logo '/pode.web/images/icon.png' -Theme Dark


    $codeEditor = New-PodeWebCodeEditor -Language Html -Name 'Code Editor' -AsCard -Value '<p style="color:white;">well</p>' -Upload {
        $WebEvent.Data | Out-Default
    }
    Set-PodeWebHomePage -NoAuth -Layouts $codeEditor -NoTitle
}
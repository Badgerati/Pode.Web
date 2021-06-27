Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Streaming' -Theme Dark

    # set the home page controls
    $con = New-PodeWebContainer -Content @(
        New-PodeWebFileStream -Url '/logs/error.log' -Icon 'information'
    )

    Set-PodeWebHomePage -Layouts $con -Title 'File Stream'
}
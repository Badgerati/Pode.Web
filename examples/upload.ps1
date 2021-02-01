Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'File Upload' -Theme Dark

    # set the home page controls (just a simple paragraph)
    $form = New-PodeWebForm -Name 'Test'  -AsCard -ScriptBlock {
        $WebEvent | Out-Default
    } -Content @(
        New-PodeWebFileUpload -Name 'File'
        New-PodeWebTextbox -Name 'Password' -Type Password -PrependIcon Lock
        New-PodeWebTextbox -Name 'Date' -Type Date
    )

    Set-PodeWebHomePage -Layouts $form -Title 'Testing Uploads'
}
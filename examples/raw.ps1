Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Raw' -Theme Dark

    # set the home page controls (just a simple paragraph)
    $card = New-PodeWebCard -Content @(
        New-PodeWebRaw -Name 'ExampleRaw' -Value '<h1>Initial Value</h1>'
        New-PodeWebTimer -Interval 10 -ScriptBlock {
            $size = Get-Random -Minimum 1 -Maximum 7
            Update-PodeWebRaw -Name 'ExampleRaw' -Value "<h$($size)>Random Size</h$($size)>"
        }
    )

    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Content $card -Title 'Update Raw'
}
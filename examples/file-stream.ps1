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
        New-PodeWebButton -Name 'Stop' -ScriptBlock {
            Stop-PodeWebFileStream -Name 'Example'
        }
        New-PodeWebButton -Name 'Start' -ScriptBlock {
            Start-PodeWebFileStream -Name 'Example'
        }
        New-PodeWebButton -Name 'Restart' -ScriptBlock {
            Restart-PodeWebFileStream -Name 'Example'
        }
        New-PodeWebButton -Name 'Clear' -ScriptBlock {
            Clear-PodeWebFileStream -Name 'Example'
        }
        New-PodeWebButton -Name 'Update 1' -ScriptBlock {
            Update-PodeWebFileStream -Name 'Example' -Url '/logs/error.log'
        }
        New-PodeWebButton -Name 'Update 2' -ScriptBlock {
            Update-PodeWebFileStream -Name 'Example' -Url '/logs/error2.log'
        }
        New-PodeWebFileStream -Name 'Example' -Url '/logs/error.log' -Icon 'information'
    )

    Set-PodeWebHomePage -Layouts $con -Title 'File Stream'
}
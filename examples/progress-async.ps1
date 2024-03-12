Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Progress Async' -Theme Dark

    # set the controls
    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Title 'Long Form' -ScriptBlock {
        New-PodeWebContainer -Content @(
            New-PodeWebForm -Name 'Test' -ScriptBlock {
                # Update-PodeWebProgress -Name 'FormProgress' -Value 0 -Colour Blue
                Reset-PodeWebProgress -Name 'FormProgress'
                Show-PodeWebElement -Name 'FormProgress' -ObjectType 'Progress'

                1..10 | ForEach-Object {
                    Start-Sleep -Seconds 1
                    Update-PodeWebProgress -Name 'FormProgress' -Value ($_ * 10)
                }

                Update-PodeWebProgress -Name 'FormProgress' -Value 100 -Colour Green
            } -Content @(
                New-PodeWebTextbox -Name 'Text' -Type Text
            )

            New-PodeWebProgress -Name 'FormProgress' -HideName -Striped -Animated |
                Hide-PodeWebElement
        )
    }
}
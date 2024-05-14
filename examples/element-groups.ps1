Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Element Groups' -Theme Dark -RootRedirect

    # set the controls
    Add-PodeWebPage -Name 'Example' -HomePage -ScriptBlock {
        New-PodeWebContainer -Content @(
            New-PodeWebElementGroup -Id 'ele_grp' -SubmitButtonId 'click_me' -Content @(
                New-PodeWebSpan -Content @(
                    New-PodeWebText -Value 'Name:'
                    New-PodeWebTextbox -Name 'Name' -Type Text | Set-PodeWebMargin -Left 1
                ) |
                    Set-PodeWebDisplay -Value Flex

                New-PodeWebSpan -Content @(
                    New-PodeWebText -Value 'City:'
                    New-PodeWebTextbox -Name 'City' -Type Text | Set-PodeWebMargin -Left 1
                ) |
                    Set-PodeWebDisplay -Value Flex |
                    Set-PodeWebMargin -Top 1

                New-PodeWebSpan -Content @(
                    New-PodeWebButton -Name 'Click Me' -Id 'click_me' -ScriptBlock {
                        Show-PodeWebToast -Message "$($WebEvent.Data.Name) from $($WebEvent.Data.City)"
                    }
                    New-PodeWebButton -Name 'Reset' -ScriptBlock {
                        Reset-PodeWebElementGroup -Id 'ele_grp'
                    } | Set-PodeWebMargin -Left 1
                ) |
                    Set-PodeWebDisplay -Value Block |
                    Set-PodeWebMargin -Top 1
            )
        )
    }
}
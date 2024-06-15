Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer -Browse {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Links Example' -Theme Dark

    # home page with link togglging
    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Title 'Homepage' -ScriptBlock {
        New-PodeWebCard -Name 'Link' -Content @(
            New-PodeWebLink -Value 'Google' -Url 'https://www.google.com' -Id 'link' -NewTab
        )

        New-PodeWebCard -Name 'Update Link' -Content @(
            New-PodeWebButtonGroup -Buttons @(
                New-PodeWebButton -Name 'Update to Goole' -ScriptBlock {
                    Update-PodeWebLink -Id 'link' -Value 'Google' -Url 'https://www.google.com'
                }
                New-PodeWebButton -Name 'Update to DuckDuckGo' -ScriptBlock {
                    Update-PodeWebLink -Id 'link' -Value 'DuckDuckGo' -Url 'https://www.duckduckgo.com'
                }
                New-PodeWebButton -Name 'Disable Link' -ScriptBlock {
                    Disable-PodeWebLink -Id 'link'
                }
                New-PodeWebButton -Name 'Enable Link' -ScriptBlock {
                    Enable-PodeWebLink -Id 'link'
                }
            )
        )
    }
}
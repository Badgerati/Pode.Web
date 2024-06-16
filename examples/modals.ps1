Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer -Browse {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Modals Example' -Theme Dark

    # home page with link togglging
    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Title 'Homepage' -ScriptBlock {
        # modal 1 - form
        New-PodeWebModal -Name 'Form Modal' -AsForm -Content @(
            New-PodeWebTextbox -Name 'Name1' -Type Text
            New-PodeWebTextbox -Name 'Comment1' -Multiline
        ) -ScriptBlock {
            Show-PodeWebToast -Title $WebEvent.Data.Name1 -Message $WebEvent.Data.Comment1
            Hide-PodeWebModal
        }

        # modal 2 - no form
        New-PodeWebModal -Name 'Normal Modal' -Content @(
            New-PodeWebTextbox -Name 'Name2' -Type Text
            New-PodeWebTextbox -Name 'Comment2' -Multiline
        ) -ScriptBlock {
            Show-PodeWebToast -Title $WebEvent.Data.Name2 -Message $WebEvent.Data.Comment2
            Hide-PodeWebModal
        }

        # buttons to show modals
        New-PodeWebCard -Name 'Show Modals' -Content @(
            New-PodeWebButtonGroup -Buttons @(
                New-PodeWebButton -Name 'Show Form Modal' -ScriptBlock {
                    Show-PodeWebModal -Name 'Form Modal'
                }
                New-PodeWebButton -Name 'Show Normal Modal' -ScriptBlock {
                    Show-PodeWebModal -Name 'Normal Modal'
                }
            )
        )
    }
}
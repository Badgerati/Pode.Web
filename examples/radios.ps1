Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8091 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Initialize-PodeWebTemplates -Title 'Radios' -Theme Dark

    # form with multiple radio options
    $multi = New-PodeWebForm -Name 'Multi' -ButtonType Submit -AsCard -ScriptBlock {
        $WebEvent.Data |
            New-PodeWebTextbox -Name 'MultiOutput' -Multiline -Size 5 -Preformat -AsJson |
            Out-PodeWebElement
    } -Content @(
        New-PodeWebRadio -Name 'MultipleRadio' -Inline -Options @(
            'S', 'M', 'L' | ConvertTo-PodeWebOption
        )

        # toggle radio checked state
        New-PodeWebButtonGroup -Buttons @(
            New-PodeWebButton -Name 'S' -ScriptBlock {
                Select-PodeWebRadio -Name 'MultipleRadio' -OptionName 'S'
            }
            New-PodeWebButton -Name 'M' -ScriptBlock {
                Select-PodeWebRadio -Name 'MultipleRadio' -OptionName 'M'
            }
            New-PodeWebButton -Name 'L' -ScriptBlock {
                Select-PodeWebRadio -Name 'MultipleRadio' -OptionName 'L'
            }
        )

        # toggle radio enabled state - all
        New-PodeWebButtonGroup -Buttons @(
            New-PodeWebButton -Name 'EnableAll' -ScriptBlock {
                Enable-PodeWebRadio -Name 'MultipleRadio'
            }
            New-PodeWebButton -Name 'DisableAll' -ScriptBlock {
                Disable-PodeWebRadio -Name 'MultipleRadio'
            }
        )

        # toggle radio enabled state - S only
        New-PodeWebButtonGroup -Buttons @(
            New-PodeWebButton -Name 'Enable-S' -ScriptBlock {
                Enable-PodeWebRadio -Name 'MultipleRadio' -OptionName 'S'
            }
            New-PodeWebButton -Name 'Disable-S' -ScriptBlock {
                Disable-PodeWebRadio -Name 'MultipleRadio' -OptionName 'S'
            }
        )

        # toggle radio enabled state - M only
        New-PodeWebButtonGroup -Buttons @(
            New-PodeWebButton -Name 'Enable-M' -ScriptBlock {
                Enable-PodeWebRadio -Name 'MultipleRadio' -OptionName 'M'
            }
            New-PodeWebButton -Name 'Disable-M' -ScriptBlock {
                Disable-PodeWebRadio -Name 'MultipleRadio' -OptionName 'M'
            }
        )

        # toggle radio enabled state - L only
        New-PodeWebButtonGroup -Buttons @(
            New-PodeWebButton -Name 'Enable-L' -ScriptBlock {
                Enable-PodeWebRadio -Name 'MultipleRadio' -OptionName 'L'
            }
            New-PodeWebButton -Name 'Disable-L' -ScriptBlock {
                Disable-PodeWebRadio -Name 'MultipleRadio' -OptionName 'L'
            }
        )
    )

    # form with dynamic radio options
    $dynamic = New-PodeWebForm -Name 'Dynamic' -ButtonType Submit -AsCard -ScriptBlock {
        $WebEvent.Data |
            New-PodeWebTextbox -Name 'DynamicOutput' -Multiline -Size 5 -Preformat -AsJson |
            Out-PodeWebElement
    } -Content @(
        New-PodeWebRadio -Name 'DynamicRadio' -ScriptBlock {
            foreach ($i in (1..5)) {
                Get-Random -Minimum 1 -Maximum 10
            }
        }

        New-PodeWebButtonGroup -Buttons @(
            # sync new options
            New-PodeWebButton -Name 'Sync' -ScriptBlock {
                Sync-PodeWebRadio -Name 'DynamicRadio'
            }
        )
    )

    # add forms to page
    Add-PodeWebPage -Name 'Home' -Path '/' -Content $multi, $dynamic -Title 'Testing Radios' -HomePage
}
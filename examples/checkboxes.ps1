Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8091 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Initialize-PodeWebTemplates -Title 'Checkboxes' -Theme Dark

    # form with a single checkbox option
    $single = New-PodeWebForm -Name 'Single' -ButtonType Submit -AsCard -ScriptBlock {
        $WebEvent.Data |
            New-PodeWebTextbox -Name 'SingleOutput' -Multiline -Size 5 -Preformat -AsJson |
            Out-PodeWebElement
    } -Content @(
        New-PodeWebCheckbox -Name 'SingleSwitch' -AsSwitch

        # toggle checkbox checked state
        New-PodeWebButtonGroup -Buttons @(
            New-PodeWebButton -Name 'Select' -ScriptBlock {
                Select-PodeWebCheckbox -Name 'SingleSwitch'
            }
            New-PodeWebButton -Name 'Deselect' -ScriptBlock {
                Reset-PodeWebCheckbox -Name 'SingleSwitch'
            }
        )

        # toggle checkbox enabled state
        New-PodeWebButtonGroup -Buttons @(
            New-PodeWebButton -Name 'Enable' -ScriptBlock {
                Enable-PodeWebCheckbox -Name 'SingleSwitch'
            }
            New-PodeWebButton -Name 'Disable' -ScriptBlock {
                Disable-PodeWebCheckbox -Name 'SingleSwitch'
            }
        )
    )

    # form with multiple checkbox options
    $multi = New-PodeWebForm -Name 'Multi' -ButtonType Submit -AsCard -ScriptBlock {
        $WebEvent.Data |
            New-PodeWebTextbox -Name 'MultiOutput' -Multiline -Size 5 -Preformat -AsJson |
            Out-PodeWebElement
    } -Content @(
        New-PodeWebCheckbox -Name 'MultiSwitch' -AsSwitch -Options @(
            'Terms', 'Privacy' | ConvertTo-PodeWebOption
        )

        # toggle checkbox checked state - all
        New-PodeWebButtonGroup -Buttons @(
            New-PodeWebButton -Name 'SelectAll' -ScriptBlock {
                Select-PodeWebCheckbox -Name 'MultiSwitch'
            }
            New-PodeWebButton -Name 'DeselectAll' -ScriptBlock {
                Reset-PodeWebCheckbox -Name 'MultiSwitch'
            }
        )

        # toggle checkbox checked state - terms only
        New-PodeWebButtonGroup -Buttons @(
            New-PodeWebButton -Name 'SelectTerms' -ScriptBlock {
                Select-PodeWebCheckbox -Name 'MultiSwitch' -OptionName 'Terms'
            }
            New-PodeWebButton -Name 'DeselectTerms' -ScriptBlock {
                Reset-PodeWebCheckbox -Name 'MultiSwitch' -OptionName 'Terms'
            }
        )

        # toggle checkbox checked state - privacy only
        New-PodeWebButtonGroup -Buttons @(
            New-PodeWebButton -Name 'SelectPrivacy' -ScriptBlock {
                Select-PodeWebCheckbox -Name 'MultiSwitch' -OptionName 'Privacy'
            }
            New-PodeWebButton -Name 'DeselectPrivacy' -ScriptBlock {
                Reset-PodeWebCheckbox -Name 'MultiSwitch' -OptionName 'Privacy'
            }
        )

        # toggle checkbox enabled state - all
        New-PodeWebButtonGroup -Buttons @(
            New-PodeWebButton -Name 'EnableAll' -ScriptBlock {
                Enable-PodeWebCheckbox -Name 'MultiSwitch'
            }
            New-PodeWebButton -Name 'DisableAll' -ScriptBlock {
                Disable-PodeWebCheckbox -Name 'MultiSwitch'
            }
        )

        # toggle checkbox enabled state - terms only
        New-PodeWebButtonGroup -Buttons @(
            New-PodeWebButton -Name 'EnableTerms' -ScriptBlock {
                Enable-PodeWebCheckbox -Name 'MultiSwitch' -OptionName 'Terms'
            }
            New-PodeWebButton -Name 'DisableTerms' -ScriptBlock {
                Disable-PodeWebCheckbox -Name 'MultiSwitch' -OptionName 'Terms'
            }
        )

        # toggle checkbox enabled state - privacy only
        New-PodeWebButtonGroup -Buttons @(
            New-PodeWebButton -Name 'EnablePrivacy' -ScriptBlock {
                Enable-PodeWebCheckbox -Name 'MultiSwitch' -OptionName 'Privacy'
            }
            New-PodeWebButton -Name 'DisablePrivacy' -ScriptBlock {
                Disable-PodeWebCheckbox -Name 'MultiSwitch' -OptionName 'Privacy'
            }
        )
    )

    # form with random checkbox options
    $random = New-PodeWebForm -Name 'Random' -ButtonType Submit -AsCard -ScriptBlock {
        $WebEvent.Data |
            New-PodeWebTextbox -Name 'RandomOutput' -Multiline -Size 5 -Preformat -AsJson |
            Out-PodeWebElement
    } -Content @(
        New-PodeWebCheckbox -Name 'RandomSwitch' -AsSwitch -Options @(
            1..5 | ForEach-Object { Get-Random -Minimum 1 -Maximum 10 } | ConvertTo-PodeWebOption
        )

        New-PodeWebButtonGroup -Buttons @(
            # clear options
            New-PodeWebButton -Name 'Clear' -ScriptBlock {
                Clear-PodeWebCheckbox -Name 'RandomSwitch'
            }

            # add new options
            New-PodeWebButton -Name 'Add' -ScriptBlock {
                Add-PodeWebCheckboxOption -Name 'RandomSwitch' -Option @(
                    1..5 | ForEach-Object { Get-Random -Minimum 1 -Maximum 10 } | ConvertTo-PodeWebOption
                )
            }

            # remove options
            New-PodeWebButton -Name 'Remove' -ScriptBlock {
                Remove-PodeWebCheckboxOption -Name 'RandomSwitch' -OptionName (Get-Random -Minimum 1 -Maximum 10)
            }
        )
    )

    # form with dynamic checkbox options
    $dynamic = New-PodeWebForm -Name 'Dynamic' -ButtonType Submit -AsCard -ScriptBlock {
        $WebEvent.Data |
            New-PodeWebTextbox -Name 'DynamicOutput' -Multiline -Size 5 -Preformat -AsJson |
            Out-PodeWebElement
    } -Content @(
        New-PodeWebCheckbox -Name 'DynamicSwitch' -AsSwitch -ScriptBlock {
            foreach ($i in (1..5)) {
                Get-Random -Minimum 1 -Maximum 10
            }
        }

        New-PodeWebButtonGroup -Buttons @(
            # sync new options
            New-PodeWebButton -Name 'Sync' -ScriptBlock {
                Sync-PodeWebCheckbox -Name 'DynamicSwitch'
            }
        )
    )

    # add forms to page
    Add-PodeWebPage -Name 'Home' -Path '/' -Content $single, $multi, $random, $dynamic -Title 'Testing Checkboxes' -HomePage
}
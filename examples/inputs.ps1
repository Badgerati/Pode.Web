Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8091 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Initialize-PodeWebTemplates -Title 'Inputs' -Theme Dark
    Import-PodeWebJavaScript -Url '/client-events.js'

    # set the home page controls (just a simple paragraph)
    $form = New-PodeWebForm -Name 'Test' -ButtonType Submit, Reset -AsCard -ScriptBlock {
        $WebEvent.Data |
            New-PodeWebTextbox -Name 'TestOutput' -Multiline -Preformat -AsJson |
            Out-PodeWebElement
    } -Content @(
        New-PodeWebTextbox -Name 'Name' -AppendIcon Account -DynamicLabel -HelpText 'Your name' -AutoComplete {
            return @('billy', 'bobby', 'alice', 'john', 'sarah', 'matt', 'zack', 'henry')
        } |
            Register-PodeWebEvent -Type KeyDown -ScriptBlock {
                Show-PodeWebToast -Message "The element has a keydown: $($WebEvent.Data['Name'])"
            } |
            Register-PodeWebEvent -Type KeyUp -ScriptBlock {
                Show-PodeWebToast -Message "The element has a keyup: $($WebEvent.Data['Name'])"
            } |
            Register-PodeWebEvent -Type MouseOver -JSFunction 'customEvent' |
            Register-PodeWebEvent -Type MouseOver -ScriptBlock {
                Show-PodeWebToast -Message 'The element has the mouse over!'
            }

        New-PodeWebTextbox -Name 'Password' -Type Password -PrependIcon 'Lock' -Placeholder 'Enter your password' -HideName -Required
        New-PodeWebTextbox -Name 'Date' -Type Date
        New-PodeWebTextbox -Name 'Time' -Type Time
        New-PodeWebTextbox -Name 'Comments' -Multiline -PrependIcon 'comment-quote'
        New-PodeWebDateTime -Name 'DateTime' -DateValue '2023-12-23' -TimeValue '13:37'
        New-PodeWebCredential -Name 'Credentials'
        New-PodeWebMinMax -Name 'CPU' -AppendIcon 'percent' -ReadOnly

        New-PodeWebCheckbox -Name 'Do you agree?' -AsSwitch

        New-PodeWebCheckbox -Name 'Switches' -AsSwitch -Options @(
            'Terms', 'Privacy' | ConvertTo-PodeWebOption
        )

        New-PodeWebCheckbox -Name 'Checkboxes' -Inline -HelpText 'Accept the terms and privacy policy' -Disabled -Options @(
            New-PodeWebOption -Name 'Terms'
            New-PodeWebOption -Name 'Privacy' -Selected
        )

        New-PodeWebRadio -Name 'Radios' -HelpText 'Select a size' -Options @(
            'S', 'M', 'L' | ConvertTo-PodeWebOption
        )

        New-PodeWebSelect -Name 'Role1' -PrependIcon 'account' -AppendIcon 'account' -HelpText 'Select a role' -Options @(
            @('Choose...', 'User', 'Admin', 'Operations') | ConvertTo-PodeWebOption
        )

        New-PodeWebSelect -Name 'Role2' -Multiple -Options @(
            New-PodeWebOptionGroup -Name 'General' -Options @(
                New-PodeWebOption -Name 'User'
            )
            New-PodeWebOptionGroup -Name 'Administrative' -Options @(
                New-PodeWebOption -Name 'Admin'
                New-PodeWebOption -Name 'Operations' -Selected
            )
        )

        New-PodeWebDatalist -Name 'Browsers' -Placeholder 'Select a browser' -Options @(
            New-PodeWebOption -Name 'Chrome'
            New-PodeWebOption -Name 'Firefox'
            New-PodeWebOption -Name 'Edge'
            New-PodeWebOption -Name 'Safari' -Selected
            New-PodeWebOption -Name 'Opera'
        )

        New-PodeWebDatalist -Name 'Count' -Placeholder 'Select a value' -ScriptBlock {
            foreach ($i in (1..10)) {
                Get-Random -Minimum 1 -Maximum 10
            }
        }

        New-PodeWebRange -Name 'Cores' -Value 30 -ShowValue -HelpText 'Select a number of CPU cores'

        New-PodeWebSelect -Name 'Amount' -ScriptBlock {
            foreach ($i in (1..10)) {
                Get-Random -Minimum 1 -Maximum 10
            }
        } |
            Register-PodeWebEvent -Type Change -ScriptBlock {
                Show-PodeWebToast -Message "The value was changed: $($WebEvent.Data['Amount'])"
            } |
            Register-PodeWebEvent -Type Focus -ScriptBlock {
                Show-PodeWebToast -Message 'The element was focused!'
            } |
            Register-PodeWebEvent -Type FocusOut -ScriptBlock {
                Show-PodeWebToast -Message 'The element was unfocused!'
            } |
            Register-PodeWebEvent -Type MouseOver -ScriptBlock {
                Show-PodeWebToast -Message 'The element has the mouse over!'
            } |
            Register-PodeWebEvent -Type MouseOut -ScriptBlock {
                Show-PodeWebToast -Message 'The element has no mouse!'
            }

        New-PodeWebProgress -Name 'Loading' -Value 23 -Colour Green -Striped -Animated
    )

    $modal = New-PodeWebModal -Name 'Test Modal' -AsForm -Content @(
        New-PodeWebTextbox -Name 'Username' -HideName -PrependText 'Username' -Required
    ) -ScriptBlock {
        Show-PodeWebToast -Message "The modal was submitted with: $($WebEvent.Data['Username'])"
        Hide-PodeWebModal
    }

    $container1 = New-PodeWebContainer -Content @(
        New-PodeWebButton -Name 'Show Input Modal' -ScriptBlock {
            Show-PodeWebModal -Name 'Test Modal'
        }
    )

    $container2 = New-PodeWebContainer -Content @(
        New-PodeWebButton -Name 'New Options' -ScriptBlock {
            $options = @(foreach ($i in (1..10)) {
                    Get-Random -Minimum 1 -Maximum 10
                })

            $options | ConvertTo-PodeWebOption | Update-PodeWebSelect -Name 'DynamicSelect'
        }

        New-PodeWebButton -Name 'Clear Options' -ScriptBlock {
            Clear-PodeWebSelect -Name 'DynamicSelect'
        }

        New-PodeWebButton -Name 'Resync Options' -ScriptBlock {
            Sync-PodeWebSelect -Name 'DynamicSelect'
        }

        New-PodeWebSelect -Name 'DynamicSelect' -Multiple -Size 6 -ScriptBlock {
            foreach ($i in (1..10)) {
                Get-Random -Minimum 1 -Maximum 10
            }
        }
    )

    $container3 = New-PodeWebContainer -Content @(
        New-PodeWebButton -Name 'New List' -ScriptBlock {
            $options = @(foreach ($i in (1..10)) {
                    Get-Random -Minimum 1 -Maximum 10
                })

            $options | ConvertTo-PodeWebOption | Update-PodeWebDatalist -Name 'DynamicDatalist'
        }

        New-PodeWebButton -Name 'Clear List' -ScriptBlock {
            Clear-PodeWebDatalist -Name 'DynamicDatalist'
        }

        New-PodeWebButton -Name 'Resync List' -ScriptBlock {
            Sync-PodeWebDatalist -Name 'DynamicDatalist'
        }

        New-PodeWebDatalist -Name 'DynamicDatalist' -ScriptBlock {
            foreach ($i in (1..10)) {
                Get-Random -Minimum 1 -Maximum 10
            }
        }
    )

    Add-PodeWebPage -Name 'Home' -Path '/' -Content $form, $container1, $modal, $container2, $container3 -Title 'Testing Inputs' -HomePage
}
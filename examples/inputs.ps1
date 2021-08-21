Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Inputs' -Theme Dark

    # set the home page controls (just a simple paragraph)
    $form = New-PodeWebForm -Name 'Test' -AsCard -ScriptBlock {
        $WebEvent.Data | Out-PodeWebTextbox -Multiline -Preformat -AsJson
    } -Content @(
        New-PodeWebTextbox -Name 'Name' -AppendIcon Account -AutoComplete {
            return @('billy', 'bobby', 'alice', 'john', 'sarah', 'matt', 'zack', 'henry')
        } |
        Register-PodeWebEvent -Type KeyDown -ScriptBlock {
            Show-PodeWebToast -Message "The element has a keydown: $($WebEvent.Data['Name'])"
        } |
        Register-PodeWebEvent -Type KeyUp -ScriptBlock {
            Show-PodeWebToast -Message "The element has a keyup: $($WebEvent.Data['Name'])"
        }

        New-PodeWebTextbox -Name 'Password' -Type Password -PrependIcon Lock
        New-PodeWebTextbox -Name 'Date' -Type Date
        New-PodeWebTextbox -Name 'Time' -Type Time
        New-PodeWebDateTime -Name 'DateTime' -NoLabels
        New-PodeWebCredential -Name 'Credentials' -NoLabels
        New-PodeWebCheckbox -Name 'Checkboxes' -Options @('Terms', 'Privacy') -AsSwitch
        New-PodeWebRadio -Name 'Radios' -Options @('S', 'M', 'L')
        New-PodeWebSelect -Name 'Role1' -Options @('Choose...', 'User', 'Admin', 'Operations')
        New-PodeWebSelect -Name 'Role2' -Options @('User', 'Admin', 'Operations') -Multiple
        New-PodeWebRange -Name 'Cores' -Value 30 -ShowValue

        New-PodeWebSelect -Name 'Amount' -ScriptBlock {
            return @(foreach ($i in (1..10)) {
                Get-Random -Minimum 1 -Maximum 10
            })
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
    )

    $container = New-PodeWebContainer -Content @(
        New-PodeWebButton -Name 'New Options' -ScriptBlock {
            $options = @(foreach ($i in (1..10)) {
                Get-Random -Minimum 1 -Maximum 10
            })

            $options | Update-PodeWebSelect -Name 'DynamicSelect'
        }

        New-PodeWebButton -Name 'Clear Options' -ScriptBlock {
            Clear-PodeWebSelect -Name 'DynamicSelect'
        }

        New-PodeWebButton -Name 'Resync Options' -ScriptBlock {
            Sync-PodeWebSelect -Name 'DynamicSelect'
        }

        New-PodeWebSelect -Name 'DynamicSelect' -Multiple -Size 6 -ScriptBlock {
            return @(foreach ($i in (1..10)) {
                Get-Random -Minimum 1 -Maximum 10
            })
        }
    )

    Set-PodeWebHomePage -Layouts $form, $container -Title 'Testing Inputs'
}
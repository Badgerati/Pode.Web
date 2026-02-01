Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8091 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Initialize-PodeWebTemplates -Title 'Inputs' -Theme Dark
    Import-PodeWebJavaScript -Url '/client-events.js' -Location Head -Async

    # add home page
    Add-PodeWebPage -Name 'Home' -Path '/' -Title 'Testing Inputs' -HomePage -ScriptBlock {
        New-PodeWebCard -Name 'Inputs' -Content @(
            New-PodeWebTextbox -Name 'Name' -AppendIcon Account |
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

            New-PodeWebFileUpload -Name 'Upload' |
                Register-PodeWebEvent -Type Change -ScriptBlock {
                    $file = $WebEvent.Data['Upload']

                    if ([string]::IsNullOrEmpty($file)) {
                        Show-PodeWebToast -Message 'No files were uploaded'
                        return
                    }

                    Show-PodeWebToast -Message "File uploaded: $($file)"
                }

            New-PodeWebButton -Name 'Custom Click' -ClickName "I've Been Clicked" -Colour Blue -NoClick |
                Register-PodeWebEvent -Type Click -ScriptBlock {
                    Start-Sleep -Seconds 3
                    Show-PodeWebToast -Message 'The button click event was triggered!'
                }

            New-PodeWebRange -Name 'Range' -Step 2.5 -ShowValue |
                Register-PodeWebEvent -Type Change -ScriptBlock {
                    $value = $WebEvent.Data['Range']
                    Show-PodeWebToast -Message "Range changed to: $($value)"
                }
            New-PodeWebButtonGroup -Buttons @(
                New-PodeWebButton -Name 'Subtract' -DisplayName '-1' -Colour Red -ScriptBlock {
                    Update-PodeWebRange -Name 'Range' -Value -1 -AsDelta
                }
                New-PodeWebButton -Name 'Add' -DisplayName '+1' -Colour Green -ScriptBlock {
                    Update-PodeWebRange -Name 'Range' -Value 1 -AsDelta
                }
                New-PodeWebButton -Name 'Down' -Colour Red -ScriptBlock {
                    Step-PodeWebRange -Name 'Range' -Direction Decrease
                }
                New-PodeWebButton -Name 'Up' -Colour Green -ScriptBlock {
                    Step-PodeWebRange -Name 'Range' -Direction Increase
                }
            )
        )
    }
}
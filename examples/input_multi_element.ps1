Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8091 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Initialize-PodeWebTemplates -Title 'Inputs' -Theme Dark

    Add-PodeWebPage -Name 'Home' -Path '/' -Title 'Testing Inputs' -HomePage -ScriptBlock {
        # add credentials example
        New-PodeWebForm -Name 'Credentials' -ButtonType Submit, Reset -AsCard -ScriptBlock {
            $WebEvent.Data |
                New-PodeWebTextbox -Name 'CredsOutput' -Multiline -Preformat -AsJson |
                Out-PodeWebElement
        } -Content @(
            New-PodeWebCredential -Name 'Credentials'
            New-PodeWebButton -Name 'Update Creds' -ScriptBlock {
                Update-PodeWebCredential -Name 'Credentials' -UsernameValue 'new_username' -PasswordValue 'new_password'
            }
            New-PodeWebButton -Name 'Clear Creds' -ScriptBlock {
                Clear-PodeWebCredential -Name 'Credentials'
            }
        )

        # add datetime example
        New-PodeWebForm -Name 'DateTime' -ButtonType Submit, Reset -AsCard -ScriptBlock {
            $WebEvent.Data |
                New-PodeWebTextbox -Name 'DateTimeOutput' -Multiline -Preformat -AsJson |
                Out-PodeWebElement
        } -Content @(
            New-PodeWebDateTime -Name 'DateTime' -DateValue '2023-12-23' -TimeValue '13:37'
            New-PodeWebButton -Name 'Update DateTime' -ScriptBlock {
                Update-PodeWebDateTime -Name 'DateTime' -DateValue '2024-01-01' -TimeValue '00:00' -ReadOnly
            }
            New-PodeWebButton -Name 'Clear DateTime' -ScriptBlock {
                Clear-PodeWebDateTime -Name 'DateTime'
            }
        )

        # add minmax example
        New-PodeWebForm -Name 'MinMax' -ButtonType Submit, Reset -AsCard -ScriptBlock {
            $WebEvent.Data |
                New-PodeWebTextbox -Name 'MinMaxOutput' -Multiline -Preformat -AsJson |
                Out-PodeWebElement
        } -Content @(
            New-PodeWebMinMax -Name 'CPU' -AppendIcon 'percent' -MinValue 0 -MaxValue 100
            New-PodeWebButton -Name 'Update MinMax' -ScriptBlock {
                Update-PodeWebMinMax -Name 'CPU' -MinValue 10 -MaxValue 90
            }
            New-PodeWebButton -Name 'Clear MinMax' -ScriptBlock {
                Clear-PodeWebMinMax -Name 'CPU'
            }
        )
    }
}
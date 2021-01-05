Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Inputs' -Theme Terminal

    # set the home page controls (just a simple paragraph)
    $form = New-PodeWebForm -Name 'Test'  -AsCard -ScriptBlock {
        @{
            Name = $WebEvent.Data.Name
            Password = $WebEvent.Data.Password
            Checkboxes = $WebEvent.Data.Checkboxes
            Radios = $WebEvent.Data.Radios
            Role = $WebEvent.Data.Role
        } | Out-PodeWebTextbox -Multiline -Preformat -AsJson
    } -Content @(
        New-PodeWebTextbox -Name 'Name' -AutoComplete {
            return @('billy', 'bobby', 'alice', 'john', 'sarah', 'matt', 'zack', 'henry')
        }
        New-PodeWebTextbox -Name 'Password' -Type Password -PrependIcon Lock
        New-PodeWebTextbox -Name 'Date' -Type Date
        New-PodeWebTextbox -Name 'Time' -Type DateTime
        New-PodeWebCheckbox -Name 'Checkboxes' -Options @('Terms', 'Privacy') -AsSwitch
        New-PodeWebRadio -Name 'Radios' -Options @('S', 'M', 'L')
        New-PodeWebSelect -Name 'Role' -Options @('User', 'Admin', 'Operations') -Multiple
        New-PodeWebRange -Name 'Cores' -Value 30 -ShowValue
    )

    Set-PodeWebHomePage -Layouts $form -Title 'Testing Inputs'
}
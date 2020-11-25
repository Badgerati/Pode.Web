Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Inputs'

    # set the home page controls (just a simple paragraph)
    $form = New-PodeWebForm -Name 'Test' -ScriptBlock {
        @{
            Name = $InputData.Name
            Password = $InputData.Password
            Checkboxes = $InputData.Checkboxes
            Radios = $InputData.Radios
            Role = $InputData.Role
        } | Out-PodeWebTextbox -Multiline -Preformat -AsJson
    } -Controls @(
        New-PodeWebTextbox -Name 'Name'
        New-PodeWebTextbox -Name 'Password' -Type Password -PrependIcon Lock
        New-PodeWebCheckbox -Name 'Checkboxes' -Options @('Terms', 'Privacy') -AsSwitch
        New-PodeWebRadio -Name 'Radios' -Options @('S', 'M', 'L')
        New-PodeWebSelect -Name 'Role' -Options @('User', 'Admin', 'Operations') -Multiple
        New-PodeWebRange -Name 'Cores' -Value 30 -ShowValue
    )

    Set-PodeWebHomePage -Components $form -Title 'Testing Inputs'
}
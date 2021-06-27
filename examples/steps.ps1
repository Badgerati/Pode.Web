Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Steps Example' -Theme Dark


    # set the home page controls (just a simple paragraph)
    $section = New-PodeWebCard -Name 'Welcome' -NoTitle -Content @(
        New-PodeWebParagraph -Value 'This is an example homepage, with some example text'
        New-PodeWebParagraph -Value 'Using some example paragraphs'
    )
    Set-PodeWebHomePage -Layouts $section -Title 'Awesome Homepage'


    # add a page to add some fake user
    $steps = New-PodeWebSteps -Name 'AddUser' -Steps @(
        New-PodeWebStep -Name 'Email' -Icon 'email' -Content @(
            New-PodeWebTextbox -Name 'Email'
        ) -ScriptBlock {
            $WebEvent.Data | Out-Default
        }
        New-PodeWebStep -Name 'Password' -Icon 'lock' -Content @(
            New-PodeWebTextbox -Name 'Password' -Type Password
        ) -ScriptBlock {
            if ([string]::IsNullOrWhiteSpace($WebEvent.Data['Password'])) {
                Out-PodeWebValidation -Name 'Password' -Message 'No password supplied'
            }
            $WebEvent.Data | Out-Default
        }
        New-PodeWebStep -Name 'Submit' -Icon 'account-plus'
    ) -ScriptBlock {
        $WebEvent.Data | Out-Default
    }

    Add-PodeWebPage -Name 'Add User' -Icon 'account-plus' -Layouts $steps
}
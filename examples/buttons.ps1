Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Buttons' -Theme Dark

    # set the home page controls (just a simple paragraph)
    $card = New-PodeWebCard -Content @(
        New-PodeWebButton -Name 'Primary' -Colour Blue -ScriptBlock {}
        New-PodeWebButton -Name 'Secondary' -Colour Grey -ScriptBlock {}
        New-PodeWebButton -Name 'Success' -Colour Green -ScriptBlock {}
        New-PodeWebButton -Name 'Danger' -Colour Red -ScriptBlock {}
        New-PodeWebButton -Name 'Warning' -Colour Yellow -ScriptBlock {}
        New-PodeWebButton -Name 'Info' -Colour Cyan -ScriptBlock {}
        New-PodeWebButton -Name 'Light' -Colour Light -ScriptBlock {}
        New-PodeWebButton -Name 'Dark' -Colour Dark -ScriptBlock {}
    )
    $card2 = New-PodeWebCard -Content @(
        New-PodeWebButton -Name 'Primary_O' -Colour Blue -ScriptBlock {} -Outline
        New-PodeWebButton -Name 'Secondary_O' -Colour Grey -ScriptBlock {} -Outline
        New-PodeWebButton -Name 'Success_O' -Colour Green -ScriptBlock {} -Outline
        New-PodeWebButton -Name 'Danger_O' -Colour Red -ScriptBlock {} -Outline
        New-PodeWebButton -Name 'Warning_O' -Colour Yellow -ScriptBlock {} -Outline
        New-PodeWebButton -Name 'Info_O' -Colour Cyan -ScriptBlock {} -Outline
        New-PodeWebButton -Name 'Light_O' -Colour Light -ScriptBlock {} -Outline
        New-PodeWebButton -Name 'Dark_O' -Colour Dark -ScriptBlock {} -Outline
    )

    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Content $card, $card2 -Title 'Buttons'
}
Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http

    # enable sessions and authentication
    Enable-PodeSessionMiddleware -Secret 'schwifty' -Duration (10 * 60) -Extend

    $clientId = '<client-id-from-portal>'
    $clientSecret = '<client-secret-from-portal>'
    $tenantId = '<tenant-from-portal>'

    # for OAuth2 grant type = password
    # $form = New-PodeAuthScheme -Form
    # $scheme = New-PodeAuthAzureADScheme -Tenant $tenantId -ClientId $clientId -ClientSecret $clientSecret -InnerScheme $form

    # for OAuth2 grant type = auth_code
    $scheme = New-PodeAuthAzureADScheme -Tenant $tenantId -ClientId $clientId -UsePKCE

    $scheme | Add-PodeAuth -Name 'AzureAD' -ScriptBlock {
        param($user, $accessToken, $refreshToken)
        return @{ User = $user }
    }

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Login Example' -Theme Dark
    Set-PodeWebLoginPage -Authentication AzureAD

    # set the home page controls (just a simple paragraph)
    $section = New-PodeWebCard -Name 'Welcome' -NoTitle -Content @(
        New-PodeWebParagraph -Value 'This is an example homepage, with some example text'
        New-PodeWebParagraph -Value 'Using some example paragraphs'
    )
    Set-PodeWebHomePage -Content $section -Title 'Awesome Homepage'

    # add a page to search process (output as json in an appended textbox)
    $form = New-PodeWebForm -Name 'Search' -AsCard -ScriptBlock {
        Get-Process -Name $WebEvent.Data.Name -ErrorAction Ignore |
            Select-Object Name, ID, WorkingSet, CPU |
            New-PodeWebTextbox -Name 'Output' -Multiline -Preformat -AsJson |
            Out-PodeWebElement
    } -Content @(
        New-PodeWebTextbox -Name 'Name'
    )

    Add-PodeWebPage -Name Processes -Icon 'chart-box-outline' -Content $form
}
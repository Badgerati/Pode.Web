Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add two named endpoints
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http -Name '8090Endpoint'
    Add-PodeEndpoint -Address localhost -Port 8091 -Protocol Http -Name '8091Endpoint'

    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Basic Example' -Theme Dark -EndpointName '8090Endpoint', '8091Endpoint'

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
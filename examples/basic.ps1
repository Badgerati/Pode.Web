Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Basic Example' -Theme Dark

    # social
    Set-PodeWebSocial -Type GitHub -Url 'https://github.com/badgerati'
    Set-PodeWebSocial -Type Twitter -Url 'https://twitter.com/Badgerati' -Tooltip '@Badgerati'

    # set the home page controls (just a simple paragraph)
    $section = New-PodeWebCard -Name 'Welcome' -NoTitle -Content @(
        New-PodeWebParagraph -Value 'This is an example homepage, with some example text'
        New-PodeWebParagraph -Value 'Using some example paragraphs'
    )
    Add-PodeWebPage -Name 'Home' -Path '/' -Content $section -Title 'Awesome Homepage' -HomePage
    # Set-PodeWebHomePage -Content $section -Title 'Awesome Homepage'

    # add a page to search process (output as json in an appended textbox)
    $form = New-PodeWebForm -Name 'Search' -ShowReset -SubmitText 'Search' -ResetText 'Clear' -AsCard -ScriptBlock {
        $procs = @(Get-Process -Name $WebEvent.Data.Name -ErrorAction Ignore |
            Select-Object Name, ID, WorkingSet, CPU)

        $procs |
            New-PodeWebTextbox -Name 'Output' -Multiline -Preformat -AsJson -Size ((6 * $procs.Length) + 2) |
            Out-PodeWebElement
    } -Content @(
        New-PodeWebTextbox -Name 'Name'
    )

    Add-PodeWebPage -Name Processes -Icon 'chart-box-outline' -Content $form -Index 1

    Use-PodeWebPages
}
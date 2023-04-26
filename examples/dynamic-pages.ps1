Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Dynamic Pages' -Theme Dark

    # set the home page controls (just a simple paragraph)
    $section = New-PodeWebCard -Name 'Welcome' -NoTitle -Content @(
        New-PodeWebParagraph -Value 'This is an example homepage, with some example text'
        New-PodeWebParagraph -Value 'Using some example paragraphs'
    )
    Set-PodeWebHomePage -Content $section -Title 'Awesome Homepage'

    Add-PodeWebPage -Name Example -ArgumentList 'Title', 'BodyText' -ScriptBlock {
        param($title, $text)

        New-PodeWebContainer -Content @(
            New-PodeWebHeader -Size 2 -Value $title -Icon 'folder'
            New-PodeWebText -Value $text
        )
    }
}
Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Paragraphs' -Theme Dark

    # set the home page controls (just a simple paragraph)
    $card1 = New-PodeWebCard -Content @(
        New-PodeWebParagraph -Value "Example paragraph`r`nover two lines"
    )

    $card2 = New-PodeWebCard -Content @(
        New-PodeWebParagraph -Content @(
            New-PodeWebText -Value "Example text`r`nover two lines"
        )
    )

    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Content $card1, $card2 -Title 'Paragraphs'
}
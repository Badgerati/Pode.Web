Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Inputs' -Theme Dark

    # set the home page controls
    $card = New-PodeWebAccordion -Items @(
        New-PodeWebAccordionItem -Name 'Section 1' -Icon 'information' -Content @(
            New-PodeWebText -Value 'Some random text' -InParagraph
        )
        New-PodeWebAccordionItem -Name 'Section 2' -Content @(
            New-PodeWebText -Value 'Some random text' -InParagraph
        )
        New-PodeWebAccordionItem -Name 'Section 3' -Content @(
            New-PodeWebText -Value 'Some random text' -InParagraph
        )
    )

    Set-PodeWebHomePage -Layouts $card -Title 'Accordion'
}
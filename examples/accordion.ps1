Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Accordion' -Theme Dark

    # set the home page controls
    $acc = New-PodeWebAccordion -Cycle -Bellows @(
        New-PodeWebBellow -Name 'Bellow 1' -Icon 'information' -Content @(
            New-PodeWebText -Value 'Some random text' -InParagraph
            New-PodeWebButton -Name 'Next' -Id 'next_1' -ScriptBlock {
                Move-PodeWebAccordion -Name 'Bellow 2'
            }
        )
        New-PodeWebBellow -Name 'Bellow 2' -Content @(
            New-PodeWebText -Value 'Some random text' -InParagraph
            New-PodeWebButton -Name 'Next' -Id 'next_2' -ScriptBlock {
                Move-PodeWebAccordion -Name 'Bellow 3'
            }
        )
        New-PodeWebBellow -Name 'Bellow 3' -Content @(
            New-PodeWebText -Value 'Some random text' -InParagraph
            New-PodeWebButton -Name 'Next' -Id 'next_3' -ScriptBlock {
                Move-PodeWebAccordion -Name 'Bellow 1'
            }
        )
    )

    Set-PodeWebHomePage -Layouts $acc -Title 'Accordion'
}
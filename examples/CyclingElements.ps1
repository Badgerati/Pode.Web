Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Cycling Elements' -Theme Dark
    
    $tabs = New-PodeWebTabs -ActiveTab "Tab2" -Tabs @(
        New-PodeWebTab -Name Tab1 -Content @(
            New-PodeWebContainer -Content @(
                New-PodeWebText -Value 'Hello World'
            )
        )
        New-PodeWebTab -Name Tab2 -Content @(
            New-PodeWebContainer -Content @(
                New-PodeWebText -Value 'Hello There'
            )
        )
        New-PodeWebTab -Name Tab3 -Content @(
            New-PodeWebContainer -Content @(
                New-PodeWebText -Value 'HI!'
            )
        )
    )
    
    Add-PodeWebPage -Name 'Tabs' -Path '/' -HomePage -Content $tabs -Title 'Tabs' -Icon 'Tab'

    $tabs = New-PodeWebTabs -Tabs @(
        New-PodeWebTab -Name Tab1 -Content @(
            New-PodeWebContainer -Content @(
                New-PodeWebText -Value 'Hello World'
            )
        )
        New-PodeWebTab -Name Tab2 -Content @(
            New-PodeWebContainer -Content @(
                New-PodeWebText -Value 'Hello There'
            )
        )
        New-PodeWebTab -Name Tab3 -Content @(
            New-PodeWebContainer -Content @(
                New-PodeWebText -Value 'HI!'
            )
        )
    )
        
    Add-PodeWebPage -Name 'Tabs (No Active tab)' -Content $tabs -Title 'Tabs' -Icon 'Tab'

    $Accordion = New-PodeWebAccordion -Bellows @(
        New-PodeWebBellow -Name Bellow1 -Content @(
            New-PodeWebText -Value 'Hello 1'
        )
        New-PodeWebBellow -Name Bellow2 -Content @(
            New-PodeWebText -Value 'Hello 2'
        )
        New-PodeWebBellow -Name Bellow3 -Content @(
            New-PodeWebText -Value 'Hello 3'
        )
    )
    
    Add-PodeWebPage -Name 'Accordion' -Content $Accordion -Title 'Accordion' -Icon 'view-split-horizontal'

    $Carousel = New-PodeWebCarousel -Slides @(
        New-PodeWebSlide -Title Slide1 -Message 'This is a message' -Content @(
            New-PodeWebContainer -Nobackground -Content @(
                New-PodeWebQuote -Value 'Pode is awesome!' -Source 'Badgerati' -Alignment Center
            )
        )
        New-PodeWebSlide -Title Slide2 -Message 'This is a message' -Content @(
            New-PodeWebContainer -Nobackground -Content @(
                New-PodeWebQuote -Value 'You should try Pode.Web!' -Source 'Badgerati' -Alignment Center
            )
        )
        New-PodeWebSlide -Title Slide3 -Message 'This is a message' -Content @(
            New-PodeWebContainer -Nobackground -Content @(
                New-PodeWebQuote -Value 'PowerShell rocks!' -Source 'Badgerati' -Alignment Center
            )
        )
    )
    
    Add-PodeWebPage -Name 'Carousel' -Content $Carousel -Title 'Carousel' -Icon 'view-carousel'

}
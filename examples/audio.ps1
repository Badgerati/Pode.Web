Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Accordion' -Theme Dark

    # set the home page controls
    $card = New-PodeWebCard -Content @(
        New-PodeWebAudio -Loop -Width '100em' -Source @(
            New-PodeWebAudioSource -Id 'synth' -Url 'https://samplelib.com/lib/preview/mp3/sample-6s.mp3'
        )
    )

    Set-PodeWebHomePage -Layouts $card -Title 'Audio'
}

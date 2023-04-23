Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Audio' -Theme Dark

    # set the home page controls
    Set-PodeWebHomePage -Title 'Audio' -Content @(
        New-PodeWebCard -Content @(
            New-PodeWebAudio -Name 'sample' -NoDownload -Source @(
                New-PodeWebAudioSource -Url 'https://samplelib.com/lib/preview/mp3/sample-6s.mp3'
            ) |
            Register-PodeWebMediaEvent -Type Play, Pause, Ended -ScriptBlock {
                Show-PodeWebToast -Title 'Action' -Message $EventType
            }
        )

        New-PodeWebContainer -Content @(
            New-PodeWebButton -Name 'Play' -ScriptBlock {
                Start-PodeWebAudio -Name 'sample'
            }

            New-PodeWebButton -Name 'Pause' -ScriptBlock {
                Stop-PodeWebAudio -Name 'sample'
            }

            New-PodeWebButton -Name 'Sample6' -ScriptBlock {
                Update-PodeWebAudio -Name 'sample' -Source @(
                    New-PodeWebAudioSource -Url 'https://samplelib.com/lib/preview/mp3/sample-6s.mp3'
                )
                Start-PodeWebAudio -Name 'sample'
            }

            New-PodeWebButton -Name 'Sample9' -ScriptBlock {
                Update-PodeWebAudio -Name 'sample' -Source @(
                    New-PodeWebAudioSource -Url 'https://samplelib.com/lib/preview/mp3/sample-9s.mp3'
                )
                Start-PodeWebAudio -Name 'sample'
            }
        )
    )
}

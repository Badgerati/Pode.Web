Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Video' -Theme Dark

    # set the home page controls
    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Title 'Video' -Content @(
        New-PodeWebCard -Content @(
            New-PodeWebVideo -Name 'sample' -Thumbnail 'https://samplelib.com/lib/preview/mp4/sample-5s.jpg' -NoDownload -Source @(
                New-PodeWebVideoSource -Url 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4'
            ) |
            Register-PodeWebMediaEvent -Type Play, Pause, Ended -ScriptBlock {
                Show-PodeWebToast -Title 'Action' -Message $EventType
            }
        )

        New-PodeWebContainer -Content @(
            New-PodeWebButton -Name 'Play' -ScriptBlock {
                Start-PodeWebVideo -Name 'sample'
            }

            New-PodeWebButton -Name 'Pause' -ScriptBlock {
                Stop-PodeWebVideo -Name 'sample'
            }

            New-PodeWebButton -Name 'Sample5' -ScriptBlock {
                Update-PodeWebVideo -Name 'sample' -Thumbnail 'https://samplelib.com/lib/preview/mp4/sample-5s.jpg' -Source @(
                    New-PodeWebVideoSource -Url 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4'
                )
                Start-PodeWebVideo -Name 'sample'
            }

            New-PodeWebButton -Name 'Sample10' -ScriptBlock {
                Update-PodeWebVideo -Name 'sample' -Thumbnail 'https://samplelib.com/lib/preview/mp4/sample-10s.jpg' -Source @(
                    New-PodeWebVideoSource -Url 'https://samplelib.com/lib/preview/mp4/sample-10s.mp4'
                )
                Start-PodeWebVideo -Name 'sample'
            }
        )
    )
}

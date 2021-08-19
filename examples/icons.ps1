Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Inputs' -Theme Dark

    # set the home page controls
    $card1 = New-PodeWebCard -Content @(
        New-PodeWebIcon -Name 'refresh'
        New-PodeWebIcon -Name 'refresh' -Colour Green
        New-PodeWebIcon -Name 'refresh' -Flip Horizontal
        New-PodeWebIcon -Name 'refresh' -Rotate 180
        New-PodeWebIcon -Name 'refresh' -Spin
    )

    $card2 = New-PodeWebCard -Content @(
        New-PodeWebTable -Name Example -ScriptBlock {
            return @{
                Icon = (New-PodeWebIcon -Name 'refresh' -Spin -Colour Yellow |
                    Register-PodeWebEvent -Type Click -ScriptBlock {
                        Show-PodeWebToast -Message 'Spinning icon clicked!'
                    })
            }
        }
    )

    Set-PodeWebHomePage -Layouts $card1, $card2 -Title 'Icons'
}
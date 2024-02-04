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
        New-PodeWebIcon -Name 'refresh' -Id 'refresh-icon' -HoverIcon (New-PodeWebIconPreset -Colour Green -Spin)
        New-PodeWebIcon -Name 'refresh' -Colour Green
        New-PodeWebIcon -Name 'refresh' -Flip Horizontal
        New-PodeWebIcon -Name 'refresh' -Rotate 180
        New-PodeWebIcon -Name 'refresh' -Spin
    )

    $card2 = New-PodeWebCard -Content @(
        New-PodeWebButton -Name 'Update' -ScriptBlock {
            Update-PodeWebIcon -Id 'refresh-icon' -Name 'cat' -Colour Yellow -Title 'Cat' -Size 40
            # Switch-PodeWebIcon -Id 'refresh-icon'
        }
    )

    $card3 = New-PodeWebCard -Content @(
        New-PodeWebTable -Name Example -ScriptBlock {
            return @{
                Icon = (New-PodeWebIcon -Name 'refresh' -Spin -Colour Yellow |
                    Register-PodeWebEvent -Type Click -ScriptBlock {
                        Show-PodeWebToast -Message 'Spinning icon clicked!'
                    })
            }
        }
    )

    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Content $card1, $card2, $card3 -Title 'Icons'
}
Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Charts' -Theme Dark

    $chartData = {
        $count = 1
        if ($WebEvent.Data.FirstLoad -eq '1') {
            $count = 4
        }

        return (1..$count | ForEach-Object {
            @{
                Key = $_
                Values = @(foreach ($i in 1..15) {
                    @{
                        Key = "Example$($i)"
                        Value = (Get-Random -Maximum 10)
                    }
                })
            }
        })
    }

    # set the home page controls
    $card1 = New-PodeWebChart `
        -Name 'Line Example' `
        -Type Line `
        -ScriptBlock $chartData `
        -Append `
        -TimeLabels `
        -MaxItems 30 `
        -AutoRefresh `
        -AsCard `
        -Colours '#ff0000', '#00ff00', '#0000ff'

    Set-PodeWebHomePage -Layouts $card1 -Title 'Charts'
}
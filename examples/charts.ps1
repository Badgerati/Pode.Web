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
                    Key    = $_
                    Values = @(foreach ($i in 1..5) {
                            @{
                                Key   = "Example$($i)"
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
        -Height '15em' `
        -AutoRefresh `
        -AsCard

    $card2 = New-PodeWebChart -Name 'Bar Example' -Type Bar -Height '15em' -AutoRefresh -AsCard -ScriptBlock {
        Get-Process |
            Sort-Object -Property CPU -Descending |
            Select-Object -First 10 |
            ConvertTo-PodeWebChartData -LabelProperty ProcessName -DatasetProperty CPU
    }

    $card3 = New-PodeWebChart -Name 'Pie Example' -Type Pie -Height '20em' -AutoRefresh -AsCard -ScriptBlock {
        Get-Process |
            Sort-Object -Property CPU -Descending |
            Select-Object -First 10 |
            ConvertTo-PodeWebChartData -LabelProperty ProcessName -DatasetProperty CPU
    }

    $card4 = New-PodeWebChart -Name 'Doughnut Example' -Type Doughnut -Height '20em' -AutoRefresh -AsCard -ScriptBlock {
        Get-Process |
            Sort-Object -Property CPU -Descending |
            Select-Object -First 10 |
            ConvertTo-PodeWebChartData -LabelProperty ProcessName -DatasetProperty CPU
    }

    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Content $card1, $card2, $card3, $card4 -Title 'Charts'
}
Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Tiles' -Theme Dark

    $processData = {
        Get-Process |
            Sort-Object -Property CPU -Descending |
            Select-Object -First 10 |
            ConvertTo-PodeWebChartData -LabelProperty ProcessName -DatasetProperty CPU, Handles
    }

    # set the home page controls
    $card = New-PodeWebCard -Content @(
        New-PodeWebGrid -Cells @(
            New-PodeWebCell -Content @(New-PodeWebTile -Name Example1 -ScriptBlock { return (Get-Random -Minimum 0 -Maximum 1000) } -Icon 'information')
            New-PodeWebCell -Content @(New-PodeWebTile -Name Example2 -ScriptBlock { return ([datetime]::Now.ToString())} -Colour Red -AutoRefresh)
            New-PodeWebCell -Content @(New-PodeWebTile -Name Example3 -Content @(
                New-PodeWebChart -Name 'Top Processes' -Type Bar -ScriptBlock $processData
            ) -Colour Yellow)
            New-PodeWebCell -Content @(New-PodeWebTile -Name Example4 -ScriptBlock {} -Colour Green)
            New-PodeWebCell -Content @(New-PodeWebTile -Name Example5 -ScriptBlock {} -Colour Dark)
            New-PodeWebCell -Content @(New-PodeWebTile -Name Example6 -ScriptBlock {} -Colour Cyan -ClickScriptBlock {
                Show-PodeWebToast -Message 'oooooo'
                Update-PodeWebTile -Name Example1 -Colour Red
                Sync-PodeWebTile -Name Example2
            })
        )

        New-PodeWebTile -Name Example7 -ScriptBlock {} -Colour Light
        New-PodeWebTile -Name Example8 -Content @(
            New-PodeWebCounterChart -Counter '\Processor(_Total)\% Processor Time'
        ) -Colour Light
    )

    Set-PodeWebHomePage -Layouts $card -Title 'Tiles'
}
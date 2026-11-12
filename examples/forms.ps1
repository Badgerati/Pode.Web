Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLogTerminalMethod | Enable-PodeErrorLogging

    # set the use of templates
    Initialize-PodeWebTemplates -Title 'Forms' -Theme Dark

    # set the home page controls
    $form1 = New-PodeWebForm -Name 'Form and Grid' -SubmitText 'Apply' -ButtonType Submit, Reset -ResetText 'Reset' -ScriptBlock {
        Write-Host 'Submitted'
    } -Content @(
        New-PodeWebGrid -Cells @(
            New-PodeWebCell -Content @(
                New-PodeWebText -Value 'Hello 1'
            )
            New-PodeWebCell -Content @(
                New-PodeWebText -Value 'Hello 2'
                New-PodeWebGrid -Cells @(
                    New-PodeWebCell -Content @(
                        New-PodeWebText -Value 'Hello 2.1'
                    )
                    New-PodeWebCell -Content @(
                        New-PodeWebText -Value 'Hello 2.2'
                    )
                )
            )
            New-PodeWebCell -Content @(
                New-PodeWebText -Value 'Hello 3'
                New-PodeWebCheckbox -Name Filter -AsSwitch
            )
        )
    )

    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Content $form1 -Title 'Forms'
}
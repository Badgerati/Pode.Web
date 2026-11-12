Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLogTerminalMethod | Enable-PodeErrorLogging

    # set the use of templates
    Initialize-PodeWebTemplates -Title 'Tabs' -Theme Dark

    # set the home page controls
    $card1 = New-PodeWebCard -Name 'Example' -Content @(
        New-PodeWebTabs -Tabs @(
            New-PodeWebTab -Name 'Paragraph' -Content @(
                New-PodeWebParagraph -Value 'This is a paragraph inside a tab.'
            )
            New-PodeWebTab -Name 'CodeBlock' -Content @(
                New-PodeWebCodeBlock -Value 'SELECT TOP 100 * FROM [User]' -Language Sql
            )
            New-PodeWebTab -Name 'CodeEditor' -Content @(
                New-PodeWebCodeEditor -Name 'Example' -Value 'Some random text'
            )
            New-PodeWebTab -Name 'Form' -Content @(
                New-PodeWebForm -Name 'TabExample' -ScriptBlock {
                    $WebEvent.Data | Out-Default
                } -Content @(
                    New-PodeWebTextbox -Name 'Name' -AppendIcon Account
                    New-PodeWebTextbox -Name 'Password' -Type Password -PrependIcon 'Lock' -Placeholder 'Enter your password' -Required
                    New-PodeWebCheckbox -Name 'Switches' -AsSwitch -Options @(
                        'Terms', 'Privacy' | ConvertTo-PodeWebOption
                    )
                )
            )
        )
    )

    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Content $card1 -Title 'Tabs'
}
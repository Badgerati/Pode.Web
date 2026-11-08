Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLogTerminalMethod | Enable-PodeErrorLogging

    # set the use of templates
    Initialize-PodeWebTemplates -Title 'Code' -Theme Dark

    # set the home page controls
    $card1 = New-PodeWebCard -Name 'Example' -Content @(
        # code block - updated as text
        New-PodeWebCodeBlock -Id 'Block1' -Value 'SELECT TOP 100 * FROM [User]' -Language Sql

        New-PodeWebButton -Name 'UpdateBlock1' -DisplayName 'Update As Text' -ScriptBlock {
            $value = (@(
                    'SELECT TOP 100 * FROM [User]'
                    'SELECT TOP 100 * FROM [Account] ORDER BY [ID] DESC'
                    'SELECT TOP 100 * FROM [Product]'
                    'SELECT TOP 100 * FROM [Order]'
                    'SELECT TOP 100 * FROM [Invoice]'
                ))[(Get-Random -Minimum 0 -Maximum 5)]

            Update-PodeWebText -Id 'Block1' -Value $value
        }
        New-PodeWebParagraph -Empty
        New-PodeWebParagraph -Empty

        # code block - updated as code and same language
        New-PodeWebCodeBlock -Id 'Block2' -Value 'SELECT TOP 100 * FROM [User]' -Language Sql

        New-PodeWebButton -Name 'UpdateBlock2' -DisplayName 'Update As Code - Same Language' -ScriptBlock {
            $value = (@(
                    'SELECT TOP 100 * FROM [User]'
                    'SELECT TOP 100 * FROM [Account] ORDER BY [ID] DESC'
                    'SELECT TOP 100 * FROM [Product]'
                    'SELECT TOP 100 * FROM [Order]'
                    'SELECT TOP 100 * FROM [Invoice]'
                ))[(Get-Random -Minimum 0 -Maximum 5)]

            Update-PodeWebCodeBlock -Id 'Block2' -Value $value
        }
        New-PodeWebParagraph -Empty
        New-PodeWebParagraph -Empty

        # code block - updated as code and different language
        New-PodeWebCodeBlock -Id 'Block3' -Value 'SELECT TOP 100 * FROM [User]' -Language Sql

        New-PodeWebButton -Name 'UpdateBlock3' -DisplayName 'Update As Code - Different Language' -ScriptBlock {
            $config = (@(
                    @{ Value = 'SELECT TOP 100 * FROM [User]'; Language = 'Sql' }
                    @{ Value = 'Write-Host "Hello World"'; Language = 'PowerShell' }
                    @{ Value = '<p>Hello World</p>'; Language = 'Html' }
                    @{ Value = 'console.log("Hello World")'; Language = 'JavaScript' }
                    @{ Value = 'echo "Hello World"'; Language = 'Bash' }
                ))[(Get-Random -Minimum 0 -Maximum 5)]

            Update-PodeWebCodeBlock -Id 'Block3' -Value $config.Value -Language $config.Language
        }
        New-PodeWebParagraph -Empty
    )

    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Content $card1 -Title 'Code'
}
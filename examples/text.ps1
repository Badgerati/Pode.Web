Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLogTerminalMethod | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Initialize-PodeWebTemplates -Title 'Text' -Theme Dark

    # set the home page controls
    $card1 = New-PodeWebCard -Name 'NoNewLine' -Content @(
        New-PodeWebBadge -Id 'Badge1' -Value 'This is a Badge <br/>'
        New-PodeWebParagraph -Empty

        New-PodeWebButton -Name 'UpdateBadge1' -DisplayName 'Update Badge' -ScriptBlock {
            Update-PodeWebBadge -Id 'Badge1' -Value 'This is an updated Badge <br/>'
        }
        New-PodeWebParagraph -Empty

        New-PodeWebText -Id 'Txt1' -Value 'This is some Text <br/>'
        New-PodeWebParagraph -Empty

        New-PodeWebButton -Name 'UpdateTxt1' -DisplayName 'Update Text' -ScriptBlock {
            Update-PodeWebText -Id 'Txt1' -Value 'This is some updated Text <br/>'
        }
        New-PodeWebParagraph -Empty

        New-PodeWebLink -Url '#' -Value 'This is a Link <br/>'
        New-PodeWebParagraph -Empty

        New-PodeWebParagraph -Value 'This is a Paragraph <br/>'
        New-PodeWebParagraph -Empty

        New-PodeWebButton -Name 'Btn1' -DisplayName 'This is a Button <br/>' -ScriptBlock {
            Show-PodeWebToast -Message 'This is a notification <br/>'
        }
        New-PodeWebParagraph -Empty

        New-PodeWebHeader -Size 1 -Value 'This is a Header <br/>' -Secondary 'This is a sub-header <br/>'
        New-PodeWebParagraph -Empty

        New-PodeWebCodeBlock -Value 'This is a Code Block <br/>'
        New-PodeWebParagraph -Empty

        New-PodeWebCode -Value 'This is a Code <br/>'
        New-PodeWebParagraph -Empty

        New-PodeWebQuote -Value 'This is a Quote <br/>'
        New-PodeWebParagraph -Empty

        New-PodeWebAlert -Value 'This is an Alert <br/>'
    )

    $card2 = New-PodeWebCard -Name 'NewLine' -Content @(
        New-PodeWebBadge -Id 'Badge2' -Value "This is`na Badge <br/>"
        New-PodeWebParagraph -Empty

        New-PodeWebButton -Name 'UpdateBadge2' -DisplayName "Update`nBadge" -ScriptBlock {
            Update-PodeWebBadge -Id 'Badge2' -Value "This is`na updated Badge <br/>"
        }
        New-PodeWebParagraph -Empty

        New-PodeWebText -Id 'Txt2' -Value "This is`nsome Text <br/>"
        New-PodeWebParagraph -Empty

        New-PodeWebButton -Name 'UpdateTxt2' -DisplayName "Update`nText" -ScriptBlock {
            Update-PodeWebText -Id 'Txt2' -Value "This is`nsome updated Text <br/>"
        }
        New-PodeWebParagraph -Empty

        New-PodeWebLink -Url '#' -Value "This is`na Link <br/>"
        New-PodeWebParagraph -Empty

        New-PodeWebParagraph -Value "This is`na Paragraph <br/>"
        New-PodeWebParagraph -Empty

        New-PodeWebButton -Name 'Btn2' -DisplayName "This is`na Button <br/>" -ScriptBlock {
            Show-PodeWebToast -Message "This is`na notification <br/>"
        }
        New-PodeWebParagraph -Empty

        New-PodeWebHeader -Size 1 -Value "This is`na Header <br/>" -Secondary "This is`na sub-header <br/>"
        New-PodeWebParagraph -Empty

        New-PodeWebCodeBlock -Value "This is`na Code Block <br/>"
        New-PodeWebParagraph -Empty

        New-PodeWebCode -Value "This is`na Code <br/>"
        New-PodeWebParagraph -Empty

        New-PodeWebQuote -Value "This is`na Quote <br/>"
        New-PodeWebParagraph -Empty

        New-PodeWebAlert -Value "This is`nan Alert <br/>"
    )

    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Content $card1, $card2 -Title 'Text'
}
# Code Block

This page details the actions available to Code Block elements.

## Update

You can use [`Update-PodeWebText`](../../../Functions/Actions/Update-PodeWebText) to update the text value of this element, but if you also wish to update the language then [`Update-PodeWebCodeBlock`](../../../Functions/Actions/Update-PodeWebCodeBlock) is available.

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCodeBlock -Id 'ex_code' -Value 'SELECT TOP 100 * FROM [User]' -Language Sql

    New-PodeWebButton -Name 'Change Code!' -ScriptBlock {
        Update-PodeWebCodeBlock -Id 'ex_code' -Value 'Write-Host "Hello, world!"' -Language PowerShell
    }
)
```

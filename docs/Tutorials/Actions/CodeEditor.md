# Code Editor

This page details the actions available to Code Editors.

## Clear

To clear the value of a Code Editor, you can use [`Clear-PodeWebCodeEditor`](../../../Functions/Actions/Clear-PodeWebCodeEditor):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCodeEditor -Language PowerShell -Name 'Code Editor' -Value "Write-Host 'hi!'"

    New-PodeWebButton -Name 'Clear Editor' -ScriptBlock {
        Clear-PodeWebCodeEditor -Name 'Code Editor'
    }
)
```

## Update

To update the value/language of a Code Editor, you can use [`Update-PodeWebCodeEditor`](../../../Functions/Actions/Update-PodeWebCodeEditor):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCodeEditor -Language PowerShell -Name 'Code Editor'

    New-PodeWebButton -Name 'Update Editor' -ScriptBlock {
        Update-PodeWebCodeEditor -Name 'Code Editor' -Value '<optional-value>' -Language '<optional-language>'
    }
)
```

# Code Editor

This page details the output actions available to Code Editors.

## Clear

To clear the value of a Code Editor, you can use [`Clear-PodeWebCodeEditor`](../../../Functions/Outputs/Clear-PodeWebCodeEditor):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCodeEditor -Language PowerShell -Name 'Code Editor' -Value "Write-Host 'hi!'"

    New-PodeWebButton -Name 'Clear Editor' -ScriptBlock {
        Clear-PodeWebCodeEditor -Name 'Code Editor'
    }
)
```

## Update

To update the value/language of a Code Editor, you can use [`Update-PodeWebCodeEditor`](../../../Functions/Outputs/Update-PodeWebCodeEditor):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCodeEditor -Language PowerShell -Name 'Code Editor'

    New-PodeWebButton -Name 'Update Editor' -ScriptBlock {
        Update-PodeWebCodeEditor -Name 'Code Editor' -Value '<optional-value>' -Language '<optional-language>'
    }
)
```

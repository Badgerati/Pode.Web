# Textbox

This page details the available output actions available to Textboxes.

## Out

To create a new textbox, usually appended beneath the sending element, you can use [`Out-PodeWebTextbox`](../../../Functions/Outputs/Out-PodeWebTextbox).  The `-Value` supplied can be a string/object array, any objects will be converted to a string:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'New Textbox' -ScriptBlock {
        Get-Process | Select-Object Name, ID, WorkingSet, CPU | Out-PodeWebTextbox -Multiline -Preformat -ReadOnly
    }
)
```

## Update

To update the value of a textbox on the page, you can use [`Update-PodeWebTextbox`](../../../Functions/Outputs/Update-PodeWebTextbox). The `-Value` supplied can be a string/object array, any objects will be converted to a string:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebTextbox -Name 'Content'

    New-PodeWebButton -Name 'Update Textbox' -ScriptBlock {
        Update-PodeWebTextbox -Name 'Content' -Value ([datetime]::Now.ToString())
    }
)
```

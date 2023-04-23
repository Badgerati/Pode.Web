# Textbox

This page details the actions available to Textboxes.

## Update

To update the value of a textbox on the page, you can use [`Update-PodeWebTextbox`](../../../Functions/Actions/Update-PodeWebTextbox). The `-Value` supplied can be a string/object array, any objects will be converted to a string:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebTextbox -Name 'Content'

    New-PodeWebButton -Name 'Update Textbox' -ScriptBlock {
        Update-PodeWebTextbox -Name 'Content' -Value ([datetime]::Now.ToString())
    }
)
```

## Clear

You can clear the content of a textbox by using [`Clear-PodeWebTextbox`](../../../Functions/Actions/Clear-PodeWebTextbox):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebTextbox -Name 'Content'

    New-PodeWebButton -Name 'Clear Textbox' -ScriptBlock {
        Clear-PodeWebTextbox -Name 'Content'
    }
)
```

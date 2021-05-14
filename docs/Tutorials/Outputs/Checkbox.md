# Checkbox

This page details the available output actions available to Checkboxes.

## Update

To update a checkbox to be checked/unchecked, you can use [`Update-PodeWebCheckbox`](../../../Functions/Outputs/Update-PodeWebCheckbox):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCheckbox -Name 'Enabled' -AsSwitch

    New-PodeWebButton -Name 'Update Checkbox' -ScriptBlock {
        $checked = [bool](Get-Random -Minimum 0 -Maximum 2)
        Update-PodeWebCheckbox -Name 'Enabled' -Checked:$checked
    }
)
```

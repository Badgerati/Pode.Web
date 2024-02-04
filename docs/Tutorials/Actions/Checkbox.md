# Checkbox

This page details the actions available to Checkboxes.

## Disable

To enable a checkbox you can use [`Disable-PodeWebCheckbox`](../../../Functions/Actions/Disable-PodeWebCheckbox):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCheckbox -Name 'Enable' -AsSwitch

    New-PodeWebButton -Name 'Disable Checkbox' -ScriptBlock {
        Disable-PodeWebCheckbox -Name 'Enable'
    }
)
```

## Enable

To enable a checkbox you can use [`Enable-PodeWebCheckbox`](../../../Functions/Actions/Enable-PodeWebCheckbox):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCheckbox -Name 'Disabled' -AsSwitch -Disabled

    New-PodeWebButton -Name 'Enable Checkbox' -ScriptBlock {
        Enable-PodeWebCheckbox -Name 'Disabled'
    }
)
```

## Update

To update a checkbox to be checked/unchecked, or to enable/disable, you can use [`Update-PodeWebCheckbox`](../../../Functions/Actions/Update-PodeWebCheckbox):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCheckbox -Name 'Enabled' -AsSwitch

    New-PodeWebButton -Name 'Update Checkbox' -ScriptBlock {
        $checked = [bool](Get-Random -Minimum 0 -Maximum 2)
        Update-PodeWebCheckbox -Name 'Enabled' -Checked:$checked
    }
    New-PodeWebButton -Name 'Enable Checkbox' -ScriptBlock {
        Update-PodeWebCheckbox -Name 'Enabled' -Checked:$false -State Enabled
    }
    New-PodeWebButton -Name 'Disable Checkbox' -ScriptBlock {
        Update-PodeWebCheckbox -Name 'Enabled' -Checked:$false -State Disabled
    }
)
```

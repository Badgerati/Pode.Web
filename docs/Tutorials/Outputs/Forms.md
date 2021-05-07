# Forms

This page details the available output actions available to Forms.

## Reset

If at any point you need to reset a form, you can use [`Reset-PodeWebForm`](../../../Functions/Outputs/Reset-PodeWebForm) which will clear all elements of the specified form:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {} -Content @(
        New-PodeWebTextbox -Name 'Name'
        New-PodeWebTextbox -Name 'Password' -Type Password -PrependIcon Lock
        New-PodeWebCheckbox -Name 'Checkboxes' -Options @('Terms', 'Privacy') -AsSwitch
        New-PodeWebSelect -Name 'Role' -Options @('User', 'Admin', 'Operations') -Multiple
    )
)

New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Reset Form' -ScriptBlock {
        Reset-PodeWebForm -Name 'Example'
    }
)
```

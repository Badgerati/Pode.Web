# Checkbox

This page details the actions available to Checkboxes.

## Add

To add one or more Options you can use [`Add-PodeWebCheckboxOption`](../../../Functions/Actions/Add-PodeWebCheckboxOption) along with `-Option`:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCheckbox -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1'
        New-PodeWebOption -Name 'Option2'
    )

    New-PodeWebButton -Name 'Add Option' -ScriptBlock {
        Add-PodeWebCheckboxOption -Name 'Example' -Option @(
            New-PodeWebOption -Name 'Added1'
        )
    }
)
```

## Clear

To clear the options of a Checkbox element, you can use [`Clear-PodeWebCheckbox`](../../../Functions/Actions/Clear-PodeWebCheckbox):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCheckbox -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1'
        New-PodeWebOption -Name 'Option2'
        New-PodeWebOption -Name 'Option3'
    )

    New-PodeWebButton -Name 'Clear Checkbox' -ScriptBlock {
        Clear-PodeWebCheckbox -Name 'Example'
    }
)
```

## Disable

To disable a checkbox you can use [`Disable-PodeWebCheckbox`](../../../Functions/Actions/Disable-PodeWebCheckbox):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCheckbox -Name 'Example' -AsSwitch

    New-PodeWebButton -Name 'Disable Checkbox' -ScriptBlock {
        Disable-PodeWebCheckbox -Name 'Example'
    }
)
```

For a Checkbox with single or multiple options, this will disable all options. For a Checkbox with multiple options you can specify which option to disable using the `-OptionName` parameter:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCheckbox -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1'
        New-PodeWebOption -Name 'Option2'
    )

    New-PodeWebButton -Name 'Disable Option1' -ScriptBlock {
        Disable-PodeWebCheckbox -Name 'Example' -OptionName 'Option1'
    }
)
```

## Enable

To enable a checkbox you can use [`Enable-PodeWebCheckbox`](../../../Functions/Actions/Enable-PodeWebCheckbox):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCheckbox -Name 'Example' -AsSwitch -Disabled

    New-PodeWebButton -Name 'Enable Checkbox' -ScriptBlock {
        Enable-PodeWebCheckbox -Name 'Example'
    }
)
```

For a Checkbox with single or multiple options, this will enable all options. For a Checkbox with multiple options you can specify which option to enable using the `-OptionName` parameter:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCheckbox -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1' -Disabled
        New-PodeWebOption -Name 'Option2'
    )

    New-PodeWebButton -Name 'Enable Option1' -ScriptBlock {
        Enable-PodeWebCheckbox -Name 'Example' -OptionName 'Option1'
    }
)
```

## Remove

To remove one or more Options you can use [`Remove-PodeWebCheckboxOption`](../../../Functions/Actions/Remove-PodeWebCheckboxOption) along with `-OptionName`:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCheckbox -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1'
        New-PodeWebOption -Name 'Option2'
        New-PodeWebOption -Name 'Option3'
    )

    New-PodeWebButton -Name 'Remove Options' -ScriptBlock {
        Remove-PodeWebCheckboxOption -Name 'Example' -OptionName 'Option1', 'Option3'
    }
)
```

## Reset

To reset/deselect options of a Checkbox element, you can use [`Reset-PodeWebCheckbox`](../../../Functions/Actions/Reset-PodeWebCheckbox):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCheckbox -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1' -Selected
        New-PodeWebOption -Name 'Option2'
        New-PodeWebOption -Name 'Option3'
    )

    New-PodeWebButton -Name 'Deselect Option' -ScriptBlock {
        Reset-PodeWebCheckbox -Name 'Example' -OptionName 'Option1'
    }
)
```

## Select

To select options of a Checkbox element, you can use [`Select-PodeWebCheckbox`](../../../Functions/Actions/Select-PodeWebCheckbox):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCheckbox -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1'
        New-PodeWebOption -Name 'Option2'
        New-PodeWebOption -Name 'Option3'
    )

    New-PodeWebButton -Name 'Select Option' -ScriptBlock {
        Select-PodeWebCheckbox -Name 'Example' -OptionName 'Option2'
    }
)
```

## Sync

If you built a Checkbox element with the `-ScriptBlock` parameter, then you can re-invoke the scriptblock to update the element by using [`Sync-PodeWebCheckbox`](../../../Functions/Actions/Sync-PodeWebCheckbox):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCheck -Name 'Example' -ScriptBlock {
        foreach ($i in (1..10)) {
            Get-Random -Minimum 1 -Maximum 10
        }
    }

    New-PodeWebButton -Name 'Sync Checkbox' -ScriptBlock {
        Sync-PodeWebCheckbox -Name 'Example'
    }
)
```

## Update

You can update a Checkbox element's options by using [`Update-PodeWebCheckbox`](../../../Functions/Actions/Update-PodeWebCheckbox):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCheckbox -Name 'Example' -ScriptBlock {
        foreach ($i in (1..10)) {
            Get-Random -Minimum 1 -Maximum 10
        }
    }

    New-PodeWebButton -Name 'New Options' -ScriptBlock {
        $options = @(foreach ($i in (1..10)) {
            Get-Random -Minimum 1 -Maximum 10
        })

        $options |
            ConvertTo-PodeWebOption |
            Update-PodeWebCheckbox -Name 'Example'
    }
)
```

Various other properties can be updated as well.

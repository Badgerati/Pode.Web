# Radio

This page details the actions available to Radio elements.

## Add

To add one or more Options you can use [`Add-PodeWebRadioOption`](../../../Functions/Actions/Add-PodeWebRadioOption) along with `-Option`:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebRadio -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1'
        New-PodeWebOption -Name 'Option2'
    )

    New-PodeWebButton -Name 'Add Option' -ScriptBlock {
        Add-PodeWebRadioOption -Name 'Example' -Option @(
            New-PodeWebOption -Name 'Added1'
        )
    }
)
```

## Clear

To clear the options of a Radio element, you can use [`Clear-PodeWebRadio`](../../../Functions/Actions/Clear-PodeWebRadio):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebRadio -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1'
        New-PodeWebOption -Name 'Option2'
        New-PodeWebOption -Name 'Option3'
    )

    New-PodeWebButton -Name 'Clear Radio' -ScriptBlock {
        Clear-PodeWebRadio -Name 'Example'
    }
)
```

## Disable

To disable a Radio you can use [`Disable-PodeWebRadio`](../../../Functions/Actions/Disable-PodeWebRadio):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebRadio -Name 'Example' -AsSwitch

    New-PodeWebButton -Name 'Disable Radio' -ScriptBlock {
        Disable-PodeWebRadio -Name 'Example'
    }
)
```

If no Option name is supplied this will disable all options, or you can specify which option to disable using the `-OptionName` parameter:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebRadio -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1'
        New-PodeWebOption -Name 'Option2'
    )

    New-PodeWebButton -Name 'Disable Option1' -ScriptBlock {
        Disable-PodeWebRadio -Name 'Example' -OptionName 'Option1'
    }
)
```

## Enable

To enable a Radio you can use [`Enable-PodeWebRadio`](../../../Functions/Actions/Enable-PodeWebRadio):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebRadio -Name 'Example' -AsSwitch -Disabled

    New-PodeWebButton -Name 'Enable Radio' -ScriptBlock {
        Enable-PodeWebRadio -Name 'Example'
    }
)
```

If no Option name is supplied this will enable all options, or you can specify which option to enable using the `-OptionName` parameter:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebRadio -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1' -Disabled
        New-PodeWebOption -Name 'Option2'
    )

    New-PodeWebButton -Name 'Enable Option1' -ScriptBlock {
        Enable-PodeWebRadio -Name 'Example' -OptionName 'Option1'
    }
)
```

## Remove

To remove one or more Options you can use [`Remove-PodeWebRadioOption`](../../../Functions/Actions/Remove-PodeWebRadioOption) along with `-OptionName`:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebRadio -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1'
        New-PodeWebOption -Name 'Option2'
        New-PodeWebOption -Name 'Option3'
    )

    New-PodeWebButton -Name 'Remove Options' -ScriptBlock {
        Remove-PodeWebRadioOption -Name 'Example' -OptionName 'Option1', 'Option3'
    }
)
```

## Reset

To reset/deselect and option of a Radio element, you can use [`Reset-PodeWebRadio`](../../../Functions/Actions/Reset-PodeWebRadio):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebRadio -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1' -Selected
        New-PodeWebOption -Name 'Option2'
        New-PodeWebOption -Name 'Option3'
    )

    New-PodeWebButton -Name 'Deselect Option' -ScriptBlock {
        Reset-PodeWebRadio -Name 'Example' -OptionName 'Option1'
    }
)
```

## Select

To select an option of a Radio element, you can use [`Select-PodeWebRadio`](../../../Functions/Actions/Select-PodeWebRadio):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebRadio -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1'
        New-PodeWebOption -Name 'Option2'
        New-PodeWebOption -Name 'Option3'
    )

    New-PodeWebButton -Name 'Select Option' -ScriptBlock {
        Select-PodeWebRadio -Name 'Example' -OptionName 'Option2'
    }
)
```

## Sync

If you built a Radio element with the `-ScriptBlock` parameter, then you can re-invoke the scriptblock to update the element by using [`Sync-PodeWebRadio`](../../../Functions/Actions/Sync-PodeWebRadio):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCheck -Name 'Example' -ScriptBlock {
        foreach ($i in (1..10)) {
            Get-Random -Minimum 1 -Maximum 10
        }
    }

    New-PodeWebButton -Name 'Sync Radio' -ScriptBlock {
        Sync-PodeWebRadio -Name 'Example'
    }
)
```

## Update

You can update a Radio element's options by using [`Update-PodeWebRadio`](../../../Functions/Actions/Update-PodeWebRadio):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebRadio -Name 'Example' -ScriptBlock {
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
            Update-PodeWebRadio -Name 'Example'
    }
)
```

Various other properties can be updated as well.

# Datalist

This page details the actions available to Datalist elements.

## Add

To add one or more Options you can use [`Add-PodeWebDatalistOption`] along with `-Option`:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebDatalist -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1'
        New-PodeWebOption -Name 'Option2'
    )

    New-PodeWebButton -Name 'Add Option' -ScriptBlock {
        Add-PodeWebDatalistOption -Name 'Example' -Option @(
            New-PodeWebOption -Name 'Added1'
        )
    }
)
```

## Clear

To clear the options of a Datalist element, you can use [`Clear-PodeWebDatalist`]:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebDatalist -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1'
        New-PodeWebOption -Name 'Option2'
        New-PodeWebOption -Name 'Option3'
    )

    New-PodeWebButton -Name 'Clear Datalist' -ScriptBlock {
        Clear-PodeWebDatalist -Name 'Example'
    }
)
```

## Remove

To remove one or more Options you can use [`Remove-PodeWebDatalistOption`] along with `-OptionName`:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebDatalist -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1'
        New-PodeWebOption -Name 'Option2'
        New-PodeWebOption -Name 'Option3'
    )

    New-PodeWebButton -Name 'Remove Options' -ScriptBlock {
        Remove-PodeWebDatalistOption -Name 'Example' -OptionName 'Option1', 'Option3'
    }
)
```

## Set

To set the currently selected option/value of a Datalist element, you can use [`Set-PodeWebDatalist`]. You can either set the value to a predefined option, or to a custom value not in the options list:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebDatalist -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1'
        New-PodeWebOption -Name 'Option2'
        New-PodeWebOption -Name 'Option3'
    )

    New-PodeWebButton -Name 'Update Datalist Predefined' -ScriptBlock {
        $rand = Get-Random -Minimum 0 -Maximum 3
        $opt = (@('Option1', 'Option2', 'Option3'))[$rand]
        Set-PodeWebDatalist -Name 'Example' -Value $opt
    }

    New-PodeWebButton -Name 'Update Datalist Custom' -ScriptBlock {
        Set-PodeWebDatalist -Name 'Example' -Value 'Custom Value'
    }
)
```

## Sync

If you built a Datalist element with the `-ScriptBlock` parameter, then you can re-invoke the scriptblock to update the element by using [`Sync-PodeWebDatalist`]:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebDatalist -Name 'Example' -ScriptBlock {
        foreach ($i in (1..10)) {
            Get-Random -Minimum 1 -Maximum 10
        }
    }

    New-PodeWebButton -Name 'Sync Datalist' -ScriptBlock {
        Sync-PodeWebDatalist -Name 'Example'
    }
)
```

## Update

You can update a Datalist element's options by using [`Update-PodeWebDatalist`]:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebDatalist -Name 'Example' -ScriptBlock {
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
            Update-PodeWebDatalist -Name 'Example'
    }
)
```

Various other properties can be updated as well.

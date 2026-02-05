# Select

This page details the actions available to Select elements.

## Add

To add one or more Options, or Option Groups, you can use [`Add-PodeWebSelectOption`] along with `-Option` and optionally a `-GroupName` to place the options under:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebSelect -Name 'Example' -Options @(
        New-PodeWebOptionGroup -Name 'Group1' -Options @(
            New-PodeWebOption -Name 'Option1'
        )
        New-PodeWebOption -Name 'Option2'
    )

    New-PodeWebButton -Name 'Add Option' -ScriptBlock {
        Add-PodeWebSelectOption -Name 'Example' -Option @(
            New-PodeWebOption -Name 'Added1'
        )
    }

    New-PodeWebButton -Name 'Add Option to Group' -ScriptBlock {
        Add-PodeWebSelectOption -Name 'Example' -GroupName 'Group1' -Option @(
            New-PodeWebOption -Name 'Added1'
        )
    }

    New-PodeWebButton -Name 'Add Options and Group' -ScriptBlock {
        Add-PodeWebSelectOption -Name 'Example' -Option @(
            New-PodeWebOptionGroup -Name 'AddedGroup1' -Options @(
                New-PodeWebOption -Name 'Added1'
            )
        )
    }
)
```

## Clear

To clear the options of a Select element, you can use [`Clear-PodeWebSelect`](../../../Functions/Actions/Clear-PodeWebSelect):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebSelect -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1'
        New-PodeWebOption -Name 'Option2'
        New-PodeWebOption -Name 'Option3'
    )

    New-PodeWebButton -Name 'Clear Select' -ScriptBlock {
        Clear-PodeWebSelect -Name 'Example'
    }
)
```

## Remove

To remove one or more Options, or Option Groups, you can use [`Remove-PodeWebSelectOption`] along with `-OptionName` and/or `-GroupName`:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebSelect -Name 'Example' -Options @(
        New-PodeWebOptionGroup -Name 'Group1' -Options @(
            New-PodeWebOption -Name 'Option1'
        )
        New-PodeWebOptionGroup -Name 'Group2' -Options @(
            New-PodeWebOption -Name 'Option2'
            New-PodeWebOption -Name 'Option3'
        )
    )

    New-PodeWebButton -Name 'Remove Groups' -ScriptBlock {
        Remove-PodeWebSelectOption -Name 'Example' -GroupName 'Group1', 'Group2'
    }

    New-PodeWebButton -Name 'Remove Options' -ScriptBlock {
        Remove-PodeWebSelectOption -Name 'Example' -OptionName 'Option1', 'Option3'
    }
)
```

## Set

To set the currently selected option/value of a Select element, you can use [`Set-PodeWebSelect`](../../../Functions/Actions/Set-PodeWebSelect):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebSelect -Name 'Example' -Options @(
        New-PodeWebOption -Name 'Option1'
        New-PodeWebOption -Name 'Option2'
        New-PodeWebOption -Name 'Option3'
    )

    New-PodeWebButton -Name 'Update Select' -ScriptBlock {
        $rand = Get-Random -Minimum 0 -Maximum 3
        $opt = (@('Option1', 'Option2', 'Option3'))[$rand]
        Set-PodeWebSelect -Name 'Example' -OptionName $opt
    }
)
```

## Sync

If you built a Select element with the `-ScriptBlock` parameter, then you can re-invoke the scriptblock to update the element by using [`Sync-PodeWebSelect`](../../../Functions/Actions/Sync-PodeWebSelect):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebSelect -Name 'Example' -ScriptBlock {
        foreach ($i in (1..10)) {
            Get-Random -Minimum 1 -Maximum 10
        }
    }

    New-PodeWebButton -Name 'Sync Select' -ScriptBlock {
        Sync-PodeWebSelect -Name 'Example'
    }
)
```

## Update

You can update a Select element's options by using [`Update-PodeWebSelect`](../../../Functions/Actions/Update-PodeWebSelect):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebSelect -Name 'Example' -ScriptBlock {
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
            Update-PodeWebSelect -Name 'Example'
    }
)
```

Various other properties can be updated as well.

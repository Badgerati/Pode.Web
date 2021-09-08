# Select

This page details the available output actions available to Select elements.

## Clear

To clear the options of a Select element, you can use [`Clear-PodeWebSelect`](../../../Functions/Outputs/Clear-PodeWebSelect):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebSelect -Name Options -Options Option1, Option2, Option3

    New-PodeWebButton -Name 'Clear Select' -ScriptBlock {
        Clear-PodeWebSelect -Name Options
    }
)
```

## Set

To set the currently selected option/value of a select element, you can use [`Set-PodeWebSelect`](../../../Functions/Outputs/Set-PodeWebSelect):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebSelect -Name Options -Options Option1, Option2, Option3

    New-PodeWebButton -Name 'Update Select' -ScriptBlock {
        $rand = Get-Random -Minimum 0 -Maximum 3
        $opt = (@('Option1', 'Option2', 'Option3'))[$rand]
        Set-PodeWebSelect -Name Options -Value $opt
    }
)
```

## Sync

If you built a Select element with the `-ScriptBlock` parameter, then you can re-invoke the scriptblock to update the element by using [`Sync-PodeWebSelect`](../../../Functions/Outputs/Sync-PodeWebSelect):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebSelect -Name Options --ScriptBlock {
        return @(foreach ($i in (1..10)) {
            Get-Random -Minimum 1 -Maximum 10
        })
    }

    New-PodeWebButton -Name 'Sync Select' -ScriptBlock {
        Sync-PodeWebSelect -Name Options
    }
)
```

## Update

You can update a Select element's options by using [`Update-PodeWebSelect`](../../../Functions/Outputs/Update-PodeWebSelect):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebSelect -Name Options --ScriptBlock {
        return @(foreach ($i in (1..10)) {
            Get-Random -Minimum 1 -Maximum 10
        })
    }

    New-PodeWebButton -Name 'New Options' -ScriptBlock {
        $options = @(foreach ($i in (1..10)) {
            Get-Random -Minimum 1 -Maximum 10
        })

        $options | Update-PodeWebSelect -Name Options
    }
)
```

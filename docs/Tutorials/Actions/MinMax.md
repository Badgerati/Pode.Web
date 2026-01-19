# MinMax

This page details the actions available to MinMax Textboxes.

## Update

To update the min and/or max values of a MinMax on the page, you can use [`Update-PodeWebMinMax`](../../../Functions/Actions/Update-PodeWebMinMax). The `-MinValue` and `-MaxValue` parameters should be a valid double number type:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebMinMax -Name 'MinMax'

    New-PodeWebButton -Name 'Update' -ScriptBlock {
        Update-PodeWebMinMax -Name 'MinMax' -MinValue 10 -MaxValue 85
    }
)
```

You can omit the `-MinValue`/`-MaxValue` and update other properties of the MinMax, such as `-ReadOnly`, etc.

Various other properties can be updated as well.

## Clear

You can clear the content of a MinMax by using [`Clear-PodeWebMinMax`](../../../Functions/Actions/Clear-PodeWebMinMax), and both the min and max fields will be cleared:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebMinMax -Name 'MinMax'

    New-PodeWebButton -Name 'Clear' -ScriptBlock {
        Clear-PodeWebMinMax -Name 'MinMax'
    }
)
```

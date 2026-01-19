# DateTime

This page details the actions available to DateTime Textboxes.

## Update

To update the date and/or time values of a DateTime on the page, you can use [`Update-PodeWebDateTime`](../../../Functions/Actions/Update-PodeWebDateTime). The `-DateValue` and `-TimeValue` parameters should be a string:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebDateTime -Name 'DateTime'

    New-PodeWebButton -Name 'Update' -ScriptBlock {
        Update-PodeWebDateTime -Name 'DateTime' -DateValue '2024-01-01' -TimeValue '00:00'
    }
)
```

You can omit the `-DateValue`/`-TimeValue` and update other properties of the DateTime, such as `-ReadOnly`, etc.

!!! note
    You can clear a DateTime by supplying an empty string to either `-DateValue` or `-TimeValue`.

Various other properties can be updated as well.

## Clear

You can clear the content of a DateTime by using [`Clear-PodeWebDateTime`](../../../Functions/Actions/Clear-PodeWebDateTime), and both the date and time fields will be cleared:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebDateTime -Name 'DateTime'

    New-PodeWebButton -Name 'Clear' -ScriptBlock {
        Clear-PodeWebDateTime -Name 'DateTime'
    }
)
```

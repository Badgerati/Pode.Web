# Page

This page details the actions available to Pages.

## Move

You can redirect a user to another Page by using [`Move-PodeWebPage`](../../../Functions/Actions/Move-PodeWebPage):

```powershell
Add-PodeWebPage -Name Page1 -Content @()

Add-PodeWebPage -Name Page2 -Content @(
    New-PodeWebContainer -NoBackground -Content @(
        New-PodeWebButton -Name 'Change Page' -ScriptBlock {
            Move-PodeWebPage -Name 'Page1'
        }
    )
)
```

The Page can be opened in a new tab via the `-NewTab` switch.

## Reset

You can refresh the current page by using [`Reset-PodeWebPage`](../../../Functions/Actions/Reset-PodeWebPage):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Refresh the Page' -ScriptBlock {
        Reset-PodeWebPage
    }
)
```

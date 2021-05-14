# Tabs

This page details the available output actions available to control a Tab layout.

## Move

You can change the current active tab by using [`Move-PodeWebTab`](../../../Functions/Outputs/Move-PodeWebTab). This will make the specified tab become the active one.

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Change Tab' -ScriptBlock {
        Move-PodeWebTab -Name "Tab$(Get-Random -Minimum 1 -Maximum 4)"
    }
)

New-PodeWebTabs -Tabs @(
    New-PodeWebTab -Name Tab1 -Layouts @(
        New-PodeWebCard -Content @(
            New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
        )
    )
    New-PodeWebTab -Name Tab2 -Layouts @(
        New-PodeWebCard -Content @(
            New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
        )
    )
    New-PodeWebTab -Name Tab3 -Layouts @(
        New-PodeWebCard -Content @(
            New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
        )
    )
)
```

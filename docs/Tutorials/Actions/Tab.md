# Tab

This page details the actions available to control a Tab element.

## Open

You can open a specific Tab in a Tabs element by using [`Open-PodeWebTab`](../../../Functions/Actions/Open-PodeWebTab). This will make the specified Tab become the active one.

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Change Tab' -ScriptBlock {
        Open-PodeWebTab -Name "Tab$(Get-Random -Minimum 1 -Maximum 4)"
    }
)

New-PodeWebTabs -Name Tabs1 -Tabs @(
    New-PodeWebTab -Name Tab1 -Content @(
        New-PodeWebCard -Content @(
            New-PodeWebImage -Source '/pode.web-static/images/icon.png' -Alignment Center
        )
    )
    New-PodeWebTab -Name Tab2 -Content @(
        New-PodeWebCard -Content @(
            New-PodeWebImage -Source '/pode.web-static/images/icon.png' -Alignment Center
        )
    )
    New-PodeWebTab -Name Tab3 -Content @(
        New-PodeWebCard -Content @(
            New-PodeWebImage -Source '/pode.web-static/images/icon.png' -Alignment Center
        )
    )
)
```

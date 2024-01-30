# Tabs

This page details the actions available to control the Tabs element.

## Move

You can change the current active Tab of a Tabs element by using [`Move-PodeWebTabs`](../../../Functions/Actions/Move-PodeWebTabs). This will cycle the active Tab to either the next (default) or previous Tab, controlled via the `-Direction` parameter.

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Next Tab' -ScriptBlock {
        Move-PodeWebTabs -Name 'Tabs1' -Direction Next
    }
    New-PodeWebButton -Name 'Previous Tab' -ScriptBlock {
        Move-PodeWebTabs -Name 'Tabs1' -Direction Previous
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

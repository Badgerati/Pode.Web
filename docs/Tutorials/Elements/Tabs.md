# Tabs

A tabs element is an array of tabs with content, where the content of those tabs is just an array of other elements.

## Usage

To create a tabs element you use [`New-PodeWebTabs`](../../../Functions/Elements/New-PodeWebTabs), and supply it an array of `-Tabs` using [`New-PodeWebTab`](../../../Functions/Elements/New-PodeWebTab). The tabs themselves accept an array of other `-Content`.

For example, the below renders an element with 3 tabs each containing an image:

```powershell
New-PodeWebTabs -Tabs @(
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

Which would look like below:

![tabs_layout](../../../images/tabs_layout.png)

## Cycling Tabs

You can render tabs that automatically cycle through themselves every X seconds, by using `-Cycle` and `-CycleInterval`. The default interval is every 15secs:

```powershell
New-PodeWebTabs -Cycle -Tabs @(
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

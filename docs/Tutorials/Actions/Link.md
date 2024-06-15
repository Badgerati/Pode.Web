# Link

This page details the actions available to Links.

## Enable

To enable a disabled link on the page, you can use [`Enable-PodeWebLink`](../../../Functions/Actions/Enable-PodeWebLink):

```powershell
New-PodeWebCard -Content @(
    New-PodeWebLink -Value 'Google' -Url 'https://www.google.com' -Id 'link' -Disabled

    New-PodeWebButton -Name 'Example' -ScriptBlock {
        Enable-PodeWebLink -Id 'link'
    }
)
```

## Disable

To disable an enabled link on the page, you can use [`Disable-PodeWebLink`](../../../Functions/Actions/Disable-PodeWebLink):

```powershell
New-PodeWebCard -Content @(
    New-PodeWebLink -Value 'Google' -Url 'https://www.google.com' -Id 'link'

    New-PodeWebButton -Name 'Example' -ScriptBlock {
        Disable-PodeWebLink -Id 'link'
    }
)
```

## Update

You can update a link's URL, Value, or Tab state using [`Update-PodeWebLink`](../../../Functions/Actions/Update-PodeWebLink).

For example, to change the URL of a link from Google to DuckDuckGo, including its Value:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebLink -Value 'Google' -Url 'https://www.google.com' -Id 'link'

    New-PodeWebButton -Name 'Example' -ScriptBlock {
        Update-PodeWebLink -Id 'link' -Url 'https://www.duckduckgo.com' -Value 'DuckDuckGo'
    }
)
```

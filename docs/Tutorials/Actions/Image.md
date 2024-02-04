# Images

This page details the actions available to Image elements.

## Update

To update the source, title, or size of an Image element, you can use [`Update-PodeWebImage`](../../../Functions/Actions/Update-PodeWebImage):

```powershell
New-PodeWebContainer -Content @(
    New-PodeWebImage -Id 'my-image' -Source 'https://raw.githubusercontent.com/Badgerati/Pode.Web/develop/src/Templates/Public/images/icon.png' -Height 70

    New-PodeWebButton -Name 'Update Image' -ScriptBlock {
        $value = Get-Random -Minimum 70 -Maximum 141
        Update-PodeWebImage -Id 'my-image' -Title "Example$($value)" -Height $value
    }
)
```

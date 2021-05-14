# Badge

This page details the available output actions available to Badges.

## Update

To update the value or the colour of a badge on the page, you can use [`Update-PodeWebBadge`](../../../Functions/Outputs/Update-PodeWebBadge):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebBadge -Id 'example_bdg' -Value 'Example Badge' -Colour Green

    New-PodeWebButton -Name 'Update Badge' -ScriptBlock {
        $rand = Get-Random -Minimum 0 -Maximum 3
        $colour = (@('Green', 'Yellow', 'Cyan'))[$rand]
        Update-PodeWebBadge -Id 'example_bdg' -Colour $colour
    }
)
```

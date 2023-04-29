# Headers

This page details the actions available to Headers.

## Update

To update the value or icon of a Header on the page, you can use [`Update-PodeWebHeader`](../../../Functions/Actions/Update-PodeWebHeader):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebHeader -Id 'my-header' -Size 1 -Value 'My Header' -Icon 'home'

    New-PodeWebButton -Name 'Update Header' -ScriptBlock {
        $rand = Get-Random -Minimum 0 -Maximum 3
        $icon = (@('cat', 'home', 'information'))[$rand]
        Update-PodeWebHeader -Id 'my-header' -Value "My Header $($rand)" -Icon $icon
    }
)
```

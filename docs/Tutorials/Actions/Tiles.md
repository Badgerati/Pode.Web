# Tiles

This page details the actions available to Tiles.

## Update

To update the value, colour or icon of a Tile on the page, you can use [`Update-PodeWebTile`](../../../Functions/Actions/Update-PodeWebTile):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebTile -Name 'Randomness' -ScriptBlock {
        return (Get-Random -Minimum 0 -Maximum 1000)
    }

    New-PodeWebButton -Name 'Update Tile' -ScriptBlock {
        $rand = Get-Random -Minimum 0 -Maximum 3
        $colour = (@('Green', 'Yellow', 'Cyan'))[$rand]
        Update-PodeWebTile -Name 'Randomness' -Colour $colour
    }
)
```

## Sync

To force a Tile to refresh its data you can use [`Sync-PodeWebTile`](../../../Functions/Actions/Sync-PodeWebTile):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebTile -Name 'Randomness' -ScriptBlock {
        return (Get-Random -Minimum 0 -Maximum 1000)
    }

    New-PodeWebButton -Name 'Refresh Tile' -ScriptBlock {
        Sync-PodeWebTile -Name 'Randomness'
    }
)
```

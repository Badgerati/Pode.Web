# Tile

A tile is a small coloured container, that contains either a static value or more elements. There purpose is to display quick informational data like: CPU, counters, charts, etc.

To add a tile you use [`New-PodeWebTile`](../../../Functions/Elements/New-PodeWebTile), and supply a `-Name` and either a `-ScriptBlock` or `-Content`.

## Value

The simplest tile is one that shows a flat value. This value should be returned from a `-ScriptBlock`, for example to show an random number:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebTile -Name 'Randomness' -ScriptBlock {
        return (Get-Random -Minimum 0 -Maximum 1000)
    }
)
```

> If you click the refresh icon, the scriptblock will be re-called, and the value updated.

Or, if you want to display the current CPU but change the colour if it goes above 90%, then you can use [`Update-PodeWebTile`] instead:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebTile -Name 'CPU' -Icon 'mdi-chart-box' -ScriptBlock {
        $cpu = ((Get-Counter -Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 2).CounterSamples.CookedValue | Measure-Object -Average).Average

        $colour = 'green'
        if ($cpu -gt 90) {
            $colour = 'red'
        }
        elseif ($cpu -gt 50) {
            $colour = 'yellow'
        }

        $cpu | Update-PodeWebTile -ID $ElementData.ID -Colour $colour
    }
)
```


## Elements



## Clickable


## Refresh






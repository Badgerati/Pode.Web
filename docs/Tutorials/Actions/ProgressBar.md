# Progress Bar

This page details the actions available to Progress Bars.

## Update

To update the value or the colour of a progress bar on the page, you can use [`Update-PodeWebProgress`](../../../Functions/Actions/Update-PodeWebProgress):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebProgress -Name 'Download' -Value 0 -Colour Green -Striped -Animated

    New-PodeWebButton -Name 'Update Progress' -ScriptBlock {
        $rand = Get-Random -Minimum 0 -Maximum 3
        $colour = (@('Green', 'Yellow', 'Cyan'))[$rand]
        $value = Get-Random -Minimum 0 -Maximum 99
        Update-PodeWebProgress -Name 'Download' -Colour $colour -Value $value
    }
)
```

## Reset

To reset the value of a progress bar back to 0, you can use [`Reset-PodeWebProgress`](../../../Functions/Actions/Reset-PodeWebProgress):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebProgress -Name 'Download' -Value 25 -Colour Green -Striped -Animated

    New-PodeWebButton -Name 'Reset Progress' -ScriptBlock {
        Reset-PodeWebProgress -Name 'Download'
    }
)
```

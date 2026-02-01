# Range

This page details the actions available to Range elements.

## Step

To increment, or decrement, a Range element by its current "step" value you can use [`Step-PodeWebRange`](../../../Functions/Actions/Step-PodeWebRange):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebRange -Name 'CPU' -Step 8 -Min 0 -Max 32

    New-PodeWebButton -Name 'Increase' -ScriptBlock {
        Step-PodeWebRange -Name 'CPU' -Direction Increase
    }
    New-PodeWebButton -Name 'Decrease' -ScriptBlock {
        Step-PodeWebRange -Name 'CPU' -Direction Decrease
    }
)
```

## Update

To update the value, min, max, or step of a Range element you can use [`Update-PodeWebRange`](../../../Functions/Actions/Update-PodeWebRange):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebRange -Name 'Example'

    New-PodeWebButton -Name 'Update Range' -ScriptBlock {
        $value = Get-Random -Minimum 0 -Maximum 100
        Update-PodeWebRange -Name 'Example' -Value $value
    }
)
```

!!! tip
    The values supplied are treated as raw values by default, for example if you supply `-Value 1` the the value will always be set to 1. However, if you supply `-AsDelta` then instead the value will be increased by 1 instead. Same applies to Min, Max, and Step.

!!! note
    If you have a custom step supplied, such as `-Step 2.5`, and you supply `-Value 1 -AsDelta`, then the value will not increase as Pode will round to the nearest step - in this case down to 0. However, in this example, using `-Value 2 -AsDelta` will increase as it will round up to 2.5.

Various other properties can be updated as well.

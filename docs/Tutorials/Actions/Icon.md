# Icons

This page details the actions available to Icon elements.

## Update

To update the name, colour, size, etc. of an Icon element, you can use [`Update-PodeWebIcon`](../../../Functions/Actions/Update-PodeWebIcon):

```powershell
New-PodeWebContainer -Content @(
    New-PodeWebIcon -Id 'my-icon' -Name 'home' -Spin

    New-PodeWebButton -Name 'Update Icon' -ScriptBlock {
        Update-PodeWebIcon -Id 'my-icon' -Name 'cat' -Colour 'yellow' -Spin:$false
    }
)
```

## Switch

To switch the state of an Icon between the Base/Toggle presets, or specifically to either the Base, Toggle or Hover presets via the `-State` parameter, you can use [`Switch-PodeWebIcon`](../../../Functions/Actions/Switch-PodeWebIcon):

```powershell
New-PodeWebContainer -Content @(
    $toggle = New-PodeWebIcon -Id 'my-icon' -Name 'home' -Spin
    New-PodeWebIcon -Id 'my-icon' -Name 'home' -ToggleIcon $toggle

    # swap between base/toggle
    New-PodeWebButton -Name 'Switch Icon - Default' -ScriptBlock {
        Switch-PodeWebIcon -Id 'my-icon'
    }

    # swap to only toggle
    New-PodeWebButton -Name 'Switch Icon - Default' -ScriptBlock {
        Switch-PodeWebIcon -Id 'my-icon' -State Toggle
    }
)
```

!!! note
    The default behaviour without `-State` is to swap between the Base and Toggle icons.

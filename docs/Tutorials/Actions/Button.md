# Button

This page details the actions available to Buttons.

## Invoke

To invoke/click a button on the page, you can use [`Invoke-PodeWebButton`](../../../Functions/Actions/Invoke-PodeWebButton):

```powershell
New-PodeWebCard -Content @(
    New-PodeWebButton -Name 'InvokeMe' -ScriptBlock {
        Show-PodeWebToast -Message 'Hello, there'
    }

    New-PodeWebButton -Name 'Example' -ScriptBlock {
        Invoke-PodeWebButton -Name 'InvokeMe'
    }
)
```

## Enable

To enable a disabled button on the page, you can use [`Enable-PodeWebButton`](../../../Functions/Actions/Enable-PodeWebButton):

```powershell
New-PodeWebCard -Content @(
    New-PodeWebButton -Name 'Disabled' -Disabled -ScriptBlock {
        Show-PodeWebToast -Message 'Hello, there'
    }

    New-PodeWebButton -Name 'Example' -ScriptBlock {
        Enable-PodeWebButton -Name 'Disabled'
    }
)
```

## Disable

To disable a enabled button on the page, you can use [`Disable-PodeWebButton`](../../../Functions/Actions/Disable-PodeWebButton):

```powershell
New-PodeWebCard -Content @(
    New-PodeWebButton -Name 'Enabled' -ScriptBlock {
        Show-PodeWebToast -Message 'Hello, there'
    }

    New-PodeWebButton -Name 'Example' -ScriptBlock {
        Disable-PodeWebButton -Name 'Enabled'
    }
)
```

## Update

You can update a button's Icon, DisplayName, Colour, and Size using [`Update-PodeWebButton`](../../../Functions/Actions/Update-PodeWebButton).

For example, just change a solid button to be yellow and outlined:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebButton -Name 'Solid' -Colour Green -ScriptBlock {
        Show-PodeWebToast -Message 'Hello, there'
    }

    New-PodeWebButton -Name 'Example' -ScriptBlock {
        Update-PodeWebButton -Name 'Solid' -Colour Yellow -ColourState Outline
    }
)
```

or to change the Icon and Size of a button:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebButton -Name 'Large' -Icon 'console-line' -Size Large -ScriptBlock {
        Show-PodeWebToast -Message 'Hello, there'
    }

    New-PodeWebButton -Name 'Example' -ScriptBlock {
        Update-PodeWebButton -Name 'Large' -Size Small -Icon 'safety-goggles'
    }
)
```

The `-ColourState` and `-SizeState` have default values of `Unchanged`. They map to `-Outline` and `-FullWidth` of a button's switches, so they can be toggled in a stateful manor.

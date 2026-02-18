# Spinner

This page details the actions available to Spinners.

## Hide

For Spinners created via [`New-PodeWebSpinner`](../../../Functions/Elements/New-PodeWebSpinner) you can use [`Hide-PodeWebElement`](../../../Functions/Actions/Hide-PodeWebElement). However, if you wish to hide the spinner that is part of another element by default - such as a Button, Table, or Chart - then you can use [`Hide-PodeWebSpinner`](../../../Functions/Actions/Hide-PodeWebSpinner) to hide that element's spinner:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Loading' -ScriptBlock {
        Start-Sleep -Seconds 10
    }

    New-PodeWebButton -Name 'Hide Spinner' -ScriptBlock {
        Hide-PodeWebSpinner -Name 'Loading' -ObjectType 'Button'
    }
)
```

### Sender

If you want to pre-emptively hide the spinner for the current sending element, such as a Button that was just clicked, then you can use [`Hide-PodeWebSenderSpinner`](../../../Functions/Actions/Hide-PodeWebSenderSpinner):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Loading' -ScriptBlock {
        Start-Sleep -Seconds 2
        Hide-PodeWebSenderSpinner
        Start-Sleep -Seconds 2
    }
)
```

## Show

For Spinners created via [`New-PodeWebSpinner`](../../../Functions/Elements/New-PodeWebSpinner) you can use [`Show-PodeWebElement`](../../../Functions/Actions/Show-PodeWebElement). However, if you wish to show a spinner that is part of another element by default - such as a Button, Table, or Chart - then you can use [`Show-PodeWebSpinner`](../../../Functions/Actions/Show-PodeWebSpinner) to show that element's spinner:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Loading' -ScriptBlock {
        # logic
    }

    New-PodeWebButton -Name 'Show Spinner' -ScriptBlock {
        Show-PodeWebSpinner -Name 'Loading' -ObjectType 'Button'
    }
)
```

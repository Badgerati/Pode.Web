# Toast

This page details the actions available to Toast messages.

## Show

You can show a quick toast message to a user, displayed in the top-right of the page, by using [`Show-PodeWebToast`](../../../Functions/Actions/Show-PodeWebToast). By default a toast is displayed for 3secs, but can be customised via `-Duration` (in ms):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Toast Me!' -ScriptBlock {
        Show-PodeWebToast -Message 'Oooh, BURN!' -Duration 5000
    }
)
```

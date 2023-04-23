# Desktop Notification

This page details the actions available to Desktop Notifications.

## Show

You can show a desktop notification on the user's computer by using [`Show-PodeWebNotification`](../../../Functions/Actions/Show-PodeWebNotification). When called for the first time for a user, this will ack the user if they're OK for the page to show desktop notifications:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Ping Me!' -ScriptBlock {
        Show-PodeWebNotification -Title 'Hi!' -Body 'Hello, there!'
    }
)
```

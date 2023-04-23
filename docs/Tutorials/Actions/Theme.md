# Theme

This page details the actions available to the Theme of pages.

## Update

To update the theme for a user you can use [`Update-PodeWebTheme`](../../../Functions/Actions/Update-PodeWebTheme). This will update the frontend cookie, and then reload the page to toggle the rendering theme:

```powershell
Use-PodeWebTemplates -Title Test -Theme Dark

New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Dark Theme' -Icon 'moon-new' -Colour Dark -ScriptBlock {
        Update-PodeWebTheme -Name Dark
    }
    New-PodeWebButton -Name 'Light Theme' -Icon 'weather-sunny' -Colour Light -ScriptBlock {
        Update-PodeWebTheme -Name Light
    }
)
```

## Reset

To reset a user's theme back to the default, you can use [`Reset-PodeWebTheme`](../../../Functions/Actions/Reset-PodeWebTheme):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Reset Theme' -Icon 'refresh' -ScriptBlock {
        Reset-PodeWebTheme
    }
)
```

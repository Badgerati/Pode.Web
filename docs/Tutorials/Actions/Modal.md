# Modal

This page details the actions available to Modals.

## Show

You can show a modal by using [`Show-PodeWebModal`](../../../Functions/Actions/Show-PodeWebModal), for this to work you must have created a modal via [`New-PodeWebModal`](../../../Functions/Elements/New-PodeWebModal) first. When showing a modal, you can supply some further output `-Actions` to populate elements within the modal:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Show Modal' -ScriptBlock {
        Show-PodeWebModal -Name 'Look a Modal'
    }
)

New-PodeWebModal -Name 'Look a Modal' -Content @(
    New-PodeWebText -Value "Looks, it's a modal!"
) -ScriptBlock {
    Hide-PodeWebModal
}
```

## Hide

You can hide a shown modal via [`Hide-PodeWebModal`](../../../Functions/Actions/Hide-PodeWebModal). If called on its own with no parameters, this will hide a modal that is currently visible:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Show Modal' -ScriptBlock {
        Show-PodeWebModal -Name 'Look a Modal'
    }
)

New-PodeWebModal -Name 'Look a Modal' -Content @(
    New-PodeWebText -Value "Looks, it's a modal!"
) -ScriptBlock {
    Hide-PodeWebModal
}
```

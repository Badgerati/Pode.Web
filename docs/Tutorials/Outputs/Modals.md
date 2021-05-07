# Modals

This page details the available output actions available to Modals.

## Show

You can show a modal by using [`Show-PodeWebModal`](../../../Functions/Outputs/Show-PodeWebModal), for this to work you must have created a modal via [`New-PodeWebModal`](../../../Functions/Layouts/New-PodeWebModal) first. When showing a modal, you can supply some further output `-Actions` to populate elements within the modal:

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

You can hide a shown modal via [`Hide-PodeWebModal`](../../../Functions/Outputs/Hide-PodeWebModal). If call on its own with no parameters, this will hide an modal that is currently visible:

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

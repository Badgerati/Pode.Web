# Bellow

This page details the actions available to control a Bellow element.

## Open

You can open a specific Bellow in an Accordion element by using [`Open-PodeWebBellow`](../../../Functions/Actions/Open-PodeWebBellow). This will make the specified Bellow become the active one.

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Change Bellow' -ScriptBlock {
        Open-PodeWebBellow -Name "Bellow$(Get-Random -Minimum 1 -Maximum 4)"
    }
)

New-PodeWebAccordion -Name Accordion1 -Bellows @(
    New-PodeWebBellow -Name 'Bellow1' -Content @(
        New-PodeWebText -Value 'Text1'
    )
    New-PodeWebBellow -Name 'Bellow2' -Content @(
        New-PodeWebText -Value 'Text2'
    )
    New-PodeWebBellow -Name 'Bellow3' -Content @(
        New-PodeWebText -Value 'Text3'
    )
)
```

## Close

You can close a specific Bellow in an Accordion element by using [`Close-PodeWebBellow`](../../../Functions/Actions/Close-PodeWebBellow). This will close the specified Bellow.

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Close Bellow 1' -ScriptBlock {
        Close-PodeWebBellow -Name "Bellow1"
    }
)

New-PodeWebAccordion -Name Accordion1 -Bellows @(
    New-PodeWebBellow -Name 'Bellow1' -Content @(
        New-PodeWebText -Value 'Text1'
    )
    New-PodeWebBellow -Name 'Bellow2' -Content @(
        New-PodeWebText -Value 'Text2'
    )
    New-PodeWebBellow -Name 'Bellow3' -Content @(
        New-PodeWebText -Value 'Text3'
    )
)
```

# Accordion

This page details the actions available to control an Accordion element.

## Move

You can change the current active Bellow of a Accordion element by using [`Move-PodeWebAccordion`](../../../Functions/Actions/Move-PodeWebAccordion). This will cycle the active Bellow to either the next (default) or previous Bellow, controlled via the `-Direction` parameter.

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Next Bellow' -ScriptBlock {
        Move-PodeWebAccordion -Name 'Accordion1' -Direction Next
    }
    New-PodeWebButton -Name 'Previous Bellow' -ScriptBlock {
        Move-PodeWebAccordion -Name 'Accordion1' -Direction Previous
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

You can close all Bellows of an Accordion by using [`Close-PodeWebAccordion`](../../../Functions/Actions/Close-PodeWebAccordion).

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Close Accordion' -ScriptBlock {
        Close-PodeWebAccordion -Name 'Accordion1'
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

# Accordion

This page details the output actions available to control an Accordion layout.

## Move

You can change the current active accordion bellow by using [`Move-PodeWebAccordion`](../../../Functions/Outputs/Move-PodeWebAccordion). This will make the specified bellow become the active one, and collapse the others.

```powershell
New-PodeWebAccordion -Bellows @(
    New-PodeWebBellow -Name 'Item 1' -Content @(
        New-PodeWebButton -Name 'Next' -Id 'next_1' -ScriptBlock {
            Move-PodeWebAccordion -Name 'Item 2'
        }
    )
    New-PodeWebBellow -Name 'Item 2' -Content @(
        New-PodeWebButton -Name 'Next' -Id 'next_2' -ScriptBlock {
            Move-PodeWebAccordion -Name 'Item 3'
        }
    )
    New-PodeWebBellow -Name 'Item 3' -Content @(
        New-PodeWebButton -Name 'Next' -Id 'next_3' -ScriptBlock {
            Move-PodeWebAccordion -Name 'Item 1'
        }
    )
)
```

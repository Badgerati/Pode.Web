# Line Break

| Support |     |
| ------- | --- |
| Events  | No  |

A Line Break is effectively a new-line for text, equivalent to doing `<br/>` in HTML.

## Usage

To create a Line Break element use [`New-PodeWebLineBreak`](../../../Functions/Elements/New-PodeWebLineBreak). For example, the following will render a paragraph with text across 2 lines:

```powershell
New-PodeWebParagraph -Content @(
    New-PodeWebText -Value 'The quick brown fox jumped'
    New-PodeWebLineBreak
    New-PodeWebText -Value 'over the lazy dog'
)
```

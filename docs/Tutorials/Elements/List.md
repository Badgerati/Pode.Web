# List

Pode.Web lets you display lists of items, either bullet pointed or numbered, using [`New-PodeWebList`](../../../Functions/Elements/New-PodeWebList). You need to supply an array of `-Items`, and then the `-Numbered` flag for numbered lists:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebList -Items 'Item1', 'Item2', 'Item3'
    New-PodeWebLine
    New-PodeWebList -Items 'Item1', 'Item2', 'Item3' -Numbered
)
```

Which looks like below:

![lists](../../../images/lists.png)

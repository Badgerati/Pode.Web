# Hidden

The Hidden element is a form input element, and can be added using [`New-PodeWebHidden`](../../../Functions/Elements/New-PodeWebHidden). It allows you to add hidden values/elements to your forms:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        $date = $WebEvent.Data['HiddenDate']
    } -Content @(
        New-PodeWebHidden -Name 'HiddenDate' -Value ([datetime]::Now.ToString())
    )
)
```

# Radio

The Radio element is a form input element, and can be added using [`New-PodeWebRadio`](../../../Functions/Elements/New-PodeWebRadio). This will add a series of radio buttons to your form:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        $bestLang = $WebEvent.Data['Best Language?']
    } -Content @(
        New-PodeWebRadio -Name 'Best Language?' -Options 'PowerShell', 'C#', 'Python', 'Other'
    )
)
```

Which looks like below:

![radio](../../../images/radio.png)

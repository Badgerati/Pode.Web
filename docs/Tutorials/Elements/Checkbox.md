# Checkbox

The Checkbox element is a form input element, and can be added using [`New-PodeWebCheckbox`](../../../Functions/Elements/New-PodeWebCheckbox). This will add a checkbox to your form, and you can render with checkbox as a switch using `-AsSwitch`:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        $accept = $WebEvent.Data['Accept Terms']
        $enable = $WebEvent.Data['Enable']
    } -Content @(
        New-PodeWebCheckbox -Name 'Accepts Terms'
        New-PodeWebCheckbox -Name 'Enable' -Checked -AsSwitch
    )
)
```

Which looks like below:

![checkbox](../../../images/checkbox.png)

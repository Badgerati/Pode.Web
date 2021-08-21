# Checkbox

| Support | |
| ------- |-|
| Events | Yes |

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

When using singular checkboxes like above, the value in `$WebEvent` will be `true` or `false` strings.

Which looks like below:

![checkbox](../../../images/checkbox.png)

You can also setup a checkbox to have multiple options like below; in this case, the value will be a comma separated list of the selected options:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        $langs = $WebEvent.Data['Spoken Languages']
    } -Content @(
        New-PodeWebCheckbox -Name 'Spoken Languages' -Options 'English', 'French', 'Japanese', 'Chinese', 'Other' -AsSwitch
    )
)
```

Which looks like below:

![checkbox_multi](../../../images/checkbox_multi.png)

## Inline

You can render this element inline with other non-form elements by using the `-NoForm` switch. This will remove the form layout, and render the element more cleanly when used outside of a form.

# Range

| Support | |
| ------- |-|
| Events | Yes |

The Range element is a form input element, and can be added using [`New-PodeWebRange`](../../../Functions/Elements/New-PodeWebRange). This will add a range slider to your form, with default min/max values of 0-100, but these can be altered via `-Min` and `-Max`. You can set a default `-Value`, and show the currently selected value via `-ShowValue`:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        $quantity = $WebEvent.Data['Quantity']
    } -Content @(
        New-PodeWebRange -Name 'Quantity' -Max 30 -Value 1 -ShowValue
    )
)
```

Which looks like below:

![range](../../../images/range.png)

## Inline

You can render this element inline with other non-form elements by using the `-NoForm` switch. This will remove the form layout, and render the element more cleanly when used outside of a form.

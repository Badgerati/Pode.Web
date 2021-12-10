# Select

| Support | |
| ------- |-|
| Events | Yes |

The Select element is a form input element, and can be added using [`New-PodeWebSelect`](../../../Functions/Elements/New-PodeWebSelect). This will add a dropdown select menu to your form, allowing the user to select an entry; to allow multiple entries to be selected you can pass `-Multiple`, and to specify a pre-selected value you can use `-SelectedValue`.

## Options

To create a Select element with pre-defined options, you can use the `-Options` parameter:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        $single = $WebEvent.Data['Single']
        $multiple = $WebEvent.Data['Multiple']
    } -Content @(
        New-PodeWebSelect -Name 'Single' -Options 'Text', 'Xml', 'Json', 'Csv' -SelectedValue 'Json'
        New-PodeWebSelect -Name 'Multiple' -Options 'Text', 'Xml', 'Json', 'Csv' -Multiple
    )
)
```

!!! Note
    When using `-Multiple`, the values will be sent back in a comma separated list

Which looks like below:

![select](../../../images/select.png)

### Dynamic

You can build a Select element's options dynamically by using the `-ScriptBlock` parameter. This will allow you to retrieve the options from elsewhere and use them as options instead.

You can either return an array of raw values, or pipe the options into, and return, [`Update-PodeWebSelect`](../../../Functions/Outputs/Update-PodeWebSelect). The following will both build a Select element with 10 random numbers as the options:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        New-PodeWebSelect -Name 'Random1' -ScriptBlock {
            return @(foreach ($i in (1..10)) {
                Get-Random -Minimum 1 -Maximum 10
            })
        }

        New-PodeWebSelect -Name 'Random2' -ScriptBlock {
            $options = @(foreach ($i in (1..10)) {
                Get-Random -Minimum 1 -Maximum 10
            })

            $options | Update-PodeWebSelect -Id $ElementData.Id
        }
    }
)
```

## Multiple

You can render a multiple select element, where more than one option can be selected, by using the `-Multiple` switch. By default only the first 4 options are shown, this can be altered using the `-Size` parameter.

## Inline

You can render this element inline with other non-form elements by using the `-NoForm` switch. This will remove the form layout, and render the element more cleanly when used outside of a form.

## Display Name

By default the label displays the `-Name` of the element. You can change the value displayed by also supplying an optional `-DisplayName` value; this value is purely visual, when the user submits the form the value of the element is still retrieved using the `-Name` from `$WebEvent.Data`.

## Display Options

By default the options displayed are from the `-Options` parameter. Like the Name, you can change the values displayed by supplying the optional `-DisplayOptions` - values in the array should be in the same order as the values in `-Options`. These values are, like the Display Name, purely visual, and when the form is submitted the server receives the original values from `-Options`.

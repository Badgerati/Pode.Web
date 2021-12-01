# MinMax

| Support | |
| ------- |-|
| Events | Yes |

The MinMax element is a form input element, and can be added using [`New-PodeWebMinMax`](../../../Functions/Elements/New-PodeWebMinMax). This will add a pair of number type textboxes to your form to allow input of minimum/maximum values, you can set preset values using `-MinValue` and `-MaxValue`:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        $min = $WebEvent.Data['CpuRange_Min']
        $max = $WebEvent.Data['CpuRange_Max']
    } -Content @(
        New-PodeWebMinMax -Name 'CpuRange' -MinValue 20 -MaxValue 90
    )
)
```

Which looks like below:

![minmax](../../../images/minmax.png)

## Type

By default both the Min and Max fields are displayed, but you can control which ones are displayed by using the `-Type` parameter:

```powershell
# both (this is the default)
New-PodeWebMinMax -Name 'Example' -Type Min, Max

# just min
New-PodeWebMinMax -Name 'Example' -Type Min

# just max
New-PodeWebMinMax -Name 'Example' -Type Max
```

## Display Name

By default the label displays the `-Name` of the element. You can change the value displayed by also supplying an optional `-DisplayName` value; this value is purely visual, when the user submits the form the value of the element is still retrieved using the `-Name` from `$WebEvent.Data`.

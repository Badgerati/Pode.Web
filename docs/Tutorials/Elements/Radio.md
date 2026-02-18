# Radio

| Support |     |
| ------- | --- |
| Events  | Yes |

The Radio element is a form input element, and can be added using [`New-PodeWebRadio`](../../../Functions/Elements/New-PodeWebRadio). This will add a series of radio buttons to your form:

## Options

### Multiple

To create a Radio element with multiple pre-defined options, you can use the `-Options` parameter which accepts an array of [`New-PodeWebOption`](../../../Functions/Elements/New-PodeWebOption):

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        $bestLang = $WebEvent.Data['Best Language?']
    } -Content @(
        New-PodeWebRadio -Name 'Best Language?' -Options @(
            New-PodeWebOption -Name 'PowerShell' - Selected
            New-PodeWebOption -Name 'C#'
            New-PodeWebOption -Name 'Python'
            New-PodeWebOption -Name 'Other'
        )
    )
)
```

Which looks like below:

![radio](../../../images/radio.png)

### Dynamic

You can build a Radio element's options dynamically by using the `-ScriptBlock` parameter. This will allow you to retrieve the options from elsewhere for use with the Radio element.

You can either return an array of raw string values, or pipe the options into, and return, [`Update-PodeWebRadio`](../../../Functions/Actions/Update-PodeWebRadio). When using the latter you will need to supply the options as Option elements, for this you can either build the options using [`New-PodeWebOption`](../../../Functions/Elements/New-PodeWebOption) or convert raw values via [`ConvertTo-PodeWebOption`](../../../Functions/Elements/ConvertTo-PodeWebOption).

The following will both build a RAdio element with 10 random numbers as the options, using the above methods:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        # return raw values for Pode.Web to convert
        New-PodeWebRadio -Name 'RawValues' -ScriptBlock {
            foreach ($i in (1..10)) {
                Get-Random -Minimum 1 -Maximum 10
            }
        }

        # use New-PodeWebOption
        New-PodeWebRadio -Name 'NewToUpdate' -ScriptBlock {
            $options = @(foreach ($i in (1..10)) {
                New-PodeWebOption -Name (Get-Random -Minimum 1 -Maximum 10)
            })

            $options | Update-PodeWebRadio -Id $ElementData.Id
        }

        # use ConvertTo-PodeWebOption
        New-PodeWebRadio -Name 'NewToUpdate' -ScriptBlock {
            $options = @(foreach ($i in (1..10)) {
                Get-Random -Minimum 1 -Maximum 10
            })

            $options |
                ConvertTo-PodeWebOption |
                Update-PodeWebRadio -Id $ElementData.Id
        }
    }
)
```

## Display Name

By default the label displays the `-Name` of the element. You can change the value displayed by also supplying an optional `-DisplayName` value; this value is purely visual, when the user submits the form the value of the element is still retrieved using the `-Name` from `$WebEvent.Data`.

The same principle applies to `New-PodeWebOption` and `-DisplayName`.

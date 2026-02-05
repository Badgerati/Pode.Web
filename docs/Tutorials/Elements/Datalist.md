# Datalist

| Support |     |
| ------- | --- |
| Events  | Yes |

The Datalist element is a form input element, and can be added using [`New-PodeWebDatalist`](../../../Functions/Elements/New-PodeWebDatalist). This will add a textbox input element but with an "autocomplete" select-like dropdown menu, allowing the user to select either a predefined option or supply a custom value.

## Options

To create a Datalist element with pre-defined options, you can use the `-Options` parameter which accepts an array of [`New-PodeWebOption`](../../../Functions/Elements/New-PodeWebOption):

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        $value = $WebEvent.Data['DatalistExample']
    } -Content @(
        New-PodeWebDatalist -Name 'DatalistExample' -Options @(
            New-PodeWebOption -Name 'Text'
            New-PodeWebOption -Name 'Xml'
            New-PodeWebOption -Name 'Json' -Selected
            New-PodeWebOption -Name 'Csv'
        )
    )
)
```

### Dynamic

You can build a Datalist element's options dynamically by using the `-ScriptBlock` parameter. This will allow you to retrieve the options from elsewhere for use with the Datalist element.

You can either return an array of raw values, or pipe the options into, and return, [`Update-PodeWebDatalist`](../../../Functions/Actions/Update-PodeWebDatalist). When using the latter you will need to supply the options as Option elements, for this you can either build the options using [`New-PodeWebOption`](../../../Functions/Elements/New-PodeWebOption) or convert raw values via [`ConvertTo-PodeWebOption`](../../../Functions/Elements/ConvertTo-PodeWebOption).

The following will both build a Datalist element with 10 random numbers as the options, using the above methods:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        # return raw values for Pode.Web to convert
        New-PodeWebDatalist -Name 'RawValues' -ScriptBlock {
            foreach ($i in (1..10)) {
                Get-Random -Minimum 1 -Maximum 10
            }
        }

        # use New-PodeWebOption
        New-PodeWebDatalist -Name 'NewToUpdate' -ScriptBlock {
            $options = @(foreach ($i in (1..10)) {
                New-PodeWebOption -Name (Get-Random -Minimum 1 -Maximum 10)
            })

            $options | Update-PodeWebDatalist -Id $ElementData.Id
        }

        # use ConvertTo-PodeWebOption
        New-PodeWebDatalist -Name 'NewToUpdate' -ScriptBlock {
            $options = @(foreach ($i in (1..10)) {
                Get-Random -Minimum 1 -Maximum 10
            })

            $options |
                ConvertTo-PodeWebOption |
                Update-PodeWebDatalist -Id $ElementData.Id
        }
    }
)
```

## Display Name

By default the label displays the `-Name` of the element. You can change the value displayed by also supplying an optional `-DisplayName` value; this value is purely visual, when the user submits the form the value of the element is still retrieved using the `-Name` from `$WebEvent.Data`.

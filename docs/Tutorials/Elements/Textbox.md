# Textbox

A textbox element is a form input element; you can render a textbox, single and multiline, to your page using [`New-PodeWebTextbox`](../../../Functions/Elements/New-PodeWebTextbox).

A textbox by default is a normal plain single lined textbox, however you can customise its `-Type` to Email/Password/etc. To change the textbox to be multilined you ca supply `-Multiline`.

Textboxes also allow you to specify `-AutoComplete` values.

## Single

A default textbox is just a simple single lined textbox. You can change the type to Email/Password/etc using the `-Type` parameter:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        $username = $WebEvent.Data['Username']
        $email = $WebEvent.Data['Email']
        $password = $WebEvent.Data['Password']
    } -Content @(
        New-PodeWebTextbox -Name 'Username'
        New-PodeWebTextbox -Name 'Email' -Type Email
        New-PodeWebTextbox -Name 'Password' -Type Password -PrependIcon Lock
    )
)
```

Which looks like below:

![textbox_single](../../../images/textbox_single.png)

### AutoComplete

For a single textbox, you can supply autocomplete values via a scriptblock passed to `-AutoComplete`. This scriptblock should return an array of strings, and will be called once when the textbox is initially loaded:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        $svcName = $WebEvent.Data['Service Name']
    } -Content @(
        New-PodeWebTextbox -Name 'Service Name' -AutoComplete {
            return @(Get-Service).Name
        }
    )
)
```

Which looks like below:

![textbox_auto](../../../images/textbox_auto.png)

## Multiline

A mutlilined textbox can be displayed by passing `-Multiline`. You cannot change the type of this textbox, it will always allow freestyle text:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        $message = $WebEvent.Data['Message']
    } -Content @(
        New-PodeWebTextbox -Name 'Message' -Multiline
    )
)
```

Which looks like below:

![textbox_multi](../../../images/textbox_multi.png)

By default it shows the first 4 lines of text, this can be altered using the `-Size` parameter.

# Button

| Support | |
| ------- |-|
| Events | No |

To display a button on your page you use [`New-PodeWebButton`](../../../Functions/Elements/New-PodeWebButton); a button can either be dynamic and run custom logic via a `-ScriptBlock`, or it can redirect a user to a `-Url`.

## Dynamic

A dynamic button is one that takes a custom `-ScriptBlock`, and when clicked will invoke that logic. You can run whatever you like, including output actions for Pode.Web to action against.

When using a dynamic button you can also supply a `-DataValue`, which is a way of supplying a special value/identity when the button is clicked. If supplied, this value is available in your scriptblock via `$WebEvent.Data['Value']`.

For example, the below button, when clicked, will display a toast message on the page:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebButton -Name 'Click Me' -DataValue 'Random' -ScriptBlock {
        Show-PodeWebToast -Message "This came from a button, with a data value of '$($WebEvent.Data['Value'])'!"
    }
)
```

Which looks like below:

![button_dynamic](../../../images/button_dynamic.png)

You can pass values to the scriptblock by using the `-ArgumentList` parameter. This accepts an array of values/objects, and they are supplied as parameters to the scriptblock:

```powershell
New-PodeWebButton -Name 'Click Me' -ArgumentList 'Value1', 2, $false -ScriptBlock {
    param($value1, $value2, $value3)

    # $value1 = 'Value1'
    # $value2 = 2
    # $value3 = $false
}
```

## URL

To have a button that simply redirects to another URL, all you have to do is supply `-Url`:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebButton -Name 'Repository' -Icon Link -Url 'https://github.com/Badgerati/Pode.Web'
)
```

### New Tab

To open the URL in a new tab, supply the `-NewTab` switch:

```powershell
New-PodeWebButton -Name 'Repository' -Icon Link -Url 'https://github.com/Badgerati/Pode.Web' -NewTab
```

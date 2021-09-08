# Events

In JavaScript you have events that can trigger, such as `onchange` or `onfocus`. You can bind scriptblocks to these events for different components by using [`Register-PodeWebEvent`](../../Functions/Events/Register-PodeWebEvent).

For now only Element components support registering events, and not all elements support events (check an elements page to see if it supports events!).

The following events are supported:

* Change
* Focus
* FocusOut
* Click
* MouseOver
* MouseOut
* KeyDown
* KeyUp

Similar to say a Button's click scriptblock, these events can run whatever logic you like, including returning output actions for Pode.Web to action against on the frontend.

## Example

Let's say you want to have a Select element, but not in a form. When the Select's current value is changed, you want to run a script to show a message:

```powershell
New-PodeWebSelect -Name 'Role' -Options @('Choose...', 'User', 'Admin', 'Operations') |
    Register-PodeWebEvent -Type Change -ScriptBlock {
        Show-PodeWebToast -Message "The value was changed: $($WebEvent.Data['Role'])"
    }
```

If the element the event triggers for is a form input element, the value will be serialised and available in `$WebEvent.Data`.

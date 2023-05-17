# Events

In JavaScript you have general events that can trigger, such as `onchange` or `onfocus`. You can bind scriptblocks to these events for different components by using [`Register-PodeWebEvent`](../../Functions/Events/Register-PodeWebEvent).

For now only Element components support registering events, and not all elements support events (check an elements page to see if it supports events!).

The following general events are supported:

| Name | Description |
| ---- | ----------- |
| Change | Fires when the value of the component changes |
| Focus | Fires when the component gains focus |
| FocusOut | Fires when the component loses focus |
| Click | Fires when the component is clicked |
| MouseOver | Fires when the mouse moves over the component |
| MouseOut | Fires when the mouse moves out of the component |
| KeyDown | Fires when a key is pressed down on the component |
| KeyUp | Fires when a key is lifted up on a component |

Similar to say a Button's click scriptblock, these events can run whatever logic you like, including returning output actions for Pode.Web to action against on the frontend.

You can bind the same action to multiple event types by supplying mutliple types to [`Register-PodeWebEvent`](../../Functions/Events/Register-PodeWebEvent)'s `-Type` parameter. The current event that has triggered the logic can be sourced via `$EventType` within the `-ScriptBlock`.

## Example

Let's say you want to have a Select element, but not in a form. When the Select's current value is changed, you want to run a script to show a message; to achieve this you can pipe the object returned by [`New-PodeWebSelect`](../../Functions/Elements/New-PodeWebSelect) into [`Register-PodeWebEvent`](../../Functions/Events/Register-PodeWebEvent):

```powershell
New-PodeWebSelect -Name 'Role' -Options @('Choose...', 'User', 'Admin', 'Operations') |
    Register-PodeWebEvent -Type Change -ScriptBlock {
        Show-PodeWebToast -Message "The value was changed: $($WebEvent.Data['Role'])"
    }
```

If the element the event triggers for is a form input element, the value will be serialised and available in `$WebEvent.Data`.

## Element Specific

The events listed above are general events supported by almost every component. However some elements, like Audio, have their own specific events, and these can be found on the element's document page.

For example, the Audio element has a `play` event which can be registered as follows:

```powershell
New-PodeWebAudio -Name 'example' -Source @(
    New-PodeWebAudioSource -Id 'sample' -Url 'https://samplelib.com/lib/preview/mp3/sample-6s.mp3'
) |
    Register-PodeWebMediaEvent -Type Play -ScriptBlock {
        Show-PodeWebToast -Title 'Action' -Message $EventType
    }
```

## Page Events

Pages also support events, and documentation can be [found here](../Pages#events).

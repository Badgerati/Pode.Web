# Events

In JavaScript you have general events that can trigger, such as `onchange` or `onfocus`. You can bind either server-side scriptblocks, or client-side JavaScript functions, to these events for different elements by using [`Register-PodeWebEvent`](../../Functions/Events/Register-PodeWebEvent).

For now only Elements support registering events, and not all elements support events (check an element's page to see if it supports events!).

The following events are supported:

| Name      | Description                                     |
| --------- | ----------------------------------------------- |
| Change    | Fires when the value of the element changes     |
| Focus     | Fires when the element gains focus              |
| FocusOut  | Fires when the element loses focus              |
| Click     | Fires when the element is clicked               |
| MouseOver | Fires when the mouse moves over the element     |
| MouseOut  | Fires when the mouse moves out of the element   |
| KeyDown   | Fires when a key is pressed down on the element |
| KeyUp     | Fires when a key is lifted up on a element      |


Similar to say a Button's click scriptblock, these events can run whatever logic you like, including returning actions for Pode.Web to action against on the frontend.

You can bind the same logic to multiple event types by supplying multiple types to [`Register-PodeWebEvent`](../../Functions/Events/Register-PodeWebEvent)'s `-Type` parameter. Additionally, you can supply the same event multiple times, and the logic when the event is triggered will be run in the order they are defined.

## Example

Let's say you want to have a Select element, but not in a form. When the Select's current value is changed you want to run a script to show a message. to achieve this you can pipe the object returned by [`New-PodeWebSelect`](../../Functions/Elements/New-PodeWebSelect) into [`Register-PodeWebEvent`](../../Functions/Events/Register-PodeWebEvent):

### Server-Side

```powershell
New-PodeWebSelect -Name 'Role' -Options @('Choose...', 'User', 'Admin', 'Operations') |
    Register-PodeWebEvent -Type Change -ScriptBlock {
        Show-PodeWebToast -Message "The value was changed: $($WebEvent.Data['Role'])"
    }
```

If the element the event triggers for is a form input element, the value will be serialised and available in `$WebEvent.Data`. The current event that has triggered the logic can be sourced via `$EventType` within the ScriptBlock.

### Client-Side

```powershell
New-PodeWebSelect -Name 'Role' -Options @('Choose...', 'User', 'Admin', 'Operations') |
    Register-PodeWebEvent -Type Change -JSFunction 'invokeCustomEvent'
```

The above will trigger a JavaScript function on the frontend, which will need to be imported via [`Import-PodeWebJavaScript`](../../Functions/Utilities/Import-PodeWebJavaScript). For example, assume the following `custom.js` file in your `/public` folder:

```powershell
Import-PodeWebJavaScript -Url '/custom.js'
```

with content containing the `invokeCustomEvent` function:

```javascript
function invokeCustomEvent(evt, target, sender, eventType, opts) {
    console.log(`Custom event triggered: ${eventType} on ${target.attr('name')}`);
}
```

The arguments supplied to the function are:

| Argument  | Description                                               |
| --------- | --------------------------------------------------------- |
| evt       | The JavaScript event object                               |
| target    | A jQuery object for the element which triggered the event |
| sender    | A Pode JavaScript object which triggered the event        |
| eventType | The event type name - such a "load", "click", etc.        |
| opts      | Any additional options for the event, such as eventId     |

## Element Specific

The events listed above are general events supported by almost every element. However some elements, like Audio, have their own specific events, and these can be found on the element's document page.

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

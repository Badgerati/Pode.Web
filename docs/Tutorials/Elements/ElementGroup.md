# Element Group

| Support |     |
| ------- | --- |
| Events  | No  |

An Element Group is similar to a Span and a Container, and similar to the Span has no impact on any styling or rendering. However, unlike the Span and Container, the Element Group creates a logical grouping of elements. For example, if you have a Textbox and a Button in the same Element Group and then click the button, this will serialize the Textbox and send its value up to your Button's scriptblock - allowing you to create more inline custom Forms.

These Element Groups can be applied to all elements however, only Buttons and Events will serialize the other elements, as these are the only features that can take advantage of the logical grouping.

# Usage

## Simple

The simplest use case for an Element Group is to wrap some input and a Button - such as a Textbox and a Button - using [`New-PodeWebElementGroup`](../../../Functions/Elements/New-PodeWebElementGroup). In the following example, such a use case is set up, and when the Button is clicked a Toast will be displayed showing the name supplied to the Textbox; the elements are added by passing them to `-Content`:

```powershell
New-PodeWebElementGroup -Content @(
    New-PodeWebTextbox -Name 'Name' -Type Text -Placeholder 'Name'
    New-PodeWebButton -Name 'Click Me' -ScriptBlock {
        Show-PodeWebToast -Message "Hi, $($WebEvent.Data.Name)!"
    }
)
```

![element_group_simple](../../../images/element_group_simple.png)

### Binding a Submit Button

Above we had to manually click the Button however, you can give an Element Group the ID of a Button to treat as a "Submit" via `-SubmitButtonId`. You can still click on the Button, but you can now also present enter from an input within the Element Group and it will auto-click the Button for you:

```powershell
New-PodeWebElementGroup -SubmitButtonId 'click_me' -Content @(
    New-PodeWebTextbox -Name 'Name' -Type Text -Placeholder 'Name'
    New-PodeWebButton -Name 'Click Me' -Id 'click_me' -ScriptBlock {
        Show-PodeWebToast -Message "Hi, $($WebEvent.Data.Name)!"
    }
)
```

## Custom Layouts

You can use any other element within an Element Group, such as Spans or Text elements. Taking the simple Textbox/Button example above we can tweak the layout to look a bit better as follows - this will use Spans, Text, and add some Margin to the elements as well:

```powershell
New-PodeWebElementGroup -Content @(
    New-PodeWebSpan -Content @(
        New-PodeWebText -Value 'Name:'
        New-PodeWebTextbox -Name 'Name' -Type Text | Set-PodeWebMargin -Left 1
    ) |
        Set-PodeWebDisplay -Value Flex

    New-PodeWebSpan -Content @(
        New-PodeWebText -Value 'City:'
        New-PodeWebTextbox -Name 'City' -Type Text | Set-PodeWebMargin -Left 1
    ) |
        Set-PodeWebDisplay -Value Flex |
        Set-PodeWebMargin -Top 1

    New-PodeWebButton -Name 'Click Me' -ScriptBlock {
        Show-PodeWebToast -Message "Hi, $($WebEvent.Data.Name) from $($WebEvent.Data.City)!"
    } |
        Set-PodeWebMargin -Top 1
)
```

![element_group_custom_layout](../../../images/element_group_custom_layout.png)

## Groups in Groups

Going one step further, you can also embed an Element Group within an Element Group. This allows you to have Buttons or Events scoped to a specific Element Group, and then a larger scoped Button that will serialize all elements in sub-Element Groups.

For example, the following has a button each for Name and City, and then a global Button to submit both Name and City together:

```powershell
New-PodeWebElementGroup -Content @(
    New-PodeWebElementGroup -Content @(
        New-PodeWebText -Value 'Name:'
        New-PodeWebTextbox -Name 'Name' -Type Text | Set-PodeWebMargin -Left 1 -Right 1
        New-PodeWebButton -Name 'Submit Name' -ScriptBlock {
            Show-PodeWebToast -Message "Hi, $($WebEvent.Data.Name)!"
        }
    ) |
        Set-PodeWebDisplay -Value Flex

    New-PodeWebElementGroup -Content @(
        New-PodeWebText -Value 'City:'
        New-PodeWebTextbox -Name 'City' -Type Text | Set-PodeWebMargin -Left 1 -Right 1
        New-PodeWebButton -Name 'Submit City' -ScriptBlock {
            Show-PodeWebToast -Message "Hi, $($WebEvent.Data.City)!"
        }
    ) |
        Set-PodeWebDisplay -Value Flex |
        Set-PodeWebMargin -Top 1

    New-PodeWebButton -Name 'Submit All' -ScriptBlock {
        Show-PodeWebToast -Message "Hi, $($WebEvent.Data.Name) from $($WebEvent.Data.City)!"
    } |
        Set-PodeWebMargin -Top 1
)
```

![element_group_grp_in_grp](../../../images/element_group_grp_in_grp.png)

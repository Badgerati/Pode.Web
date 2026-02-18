# Span

| Support |     |
| ------- | --- |
| Events  | No  |

A Span is similar to a Container but has no styling or impact on any "display" values set. They have the same use case which is to group elements, but in the most minimal and least impactful way possible.

A Span takes an array of elements via `-Content`.

## Usage

To create a Span element you [`New-PodeWebSpan`](../../../Functions/Elements/New-PodeWebSpan), and supply an array of elements via `-Content`. For example, the below renders a Span with some Text and a Textbox:

```powershell
New-PodeWebSpan -Content @(
    New-PodeWebText -Value 'Name:'
    New-PodeWebTextbox -Name 'Name' -Type Text
)
```

![span_example](../../../images/span_example.png)

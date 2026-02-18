# Container

| Support |     |
| ------- | --- |
| Events  | No  |

A Container is similar to a card element, but it has no title, nor can it be collapsed. It's a way of grouping multiple elements with the option of making the background of the Container transparent.

A Container takes an array of elements via `-Content`.

## Usage

To create a Container element you use [`New-PodeWebContainer`](../../../Functions/Elements/New-PodeWebContainer), and supply it an array of `-Content`.

For example, the below renders a Container with a quote:

```powershell
New-PodeWebContainer -Content @(
    New-PodeWebQuote -Value 'Pode is awesome!' -Source 'Badgerati'
)
```

Which would look like below:

![container_back](../../../images/container_back.png)

Or with no background:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebQuote -Value 'Pode is awesome!' -Source 'Badgerati'
)
```

Which would look like below:

![container_no_back](../../../images/container_no_back.png)

# Button Group

| Support | |
| ------- |-|
| Events | No |

A Button Group lets you render a group of buttons in a more stylised manor - either horizontally or vertically. To add a Button Group you use [`New-PodeWebButtonGroup`](../../../Functions/Elements/New-PodeWebButtonGroup), and supply and array of Buttons to its `-Buttons` parameter:

```powershell
New-PodeWebButtonGroup -Buttons @(
    New-PodeWebButton -Name 'Hide' -ScriptBlock {
        # logic
    }
    New-PodeWebButton -Name 'Show' -ScriptBlock {
        # logic
    }
)
```

Which looks like below:

![button_group](../../../images/button_group.png)

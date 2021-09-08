# Icon

| Support | |
| ------- |-|
| Events | Yes |

The icon element will render a [Material Design Icon](https://materialdesignicons.com) to your page. To create an icon element you use [`New-PodeWebIcon`](../../../Functions/Elements/New-PodeWebIcon), and supply the name of a Material Design Icon using `-Name`; you can also change the icon colour via `-Colour` which can be a known name (red/green/etc) or a hex value (#333333).

```powershell
New-PodeWebCard -Content @(
    New-PodeWebText -Value 'Here is an icon: '
    New-PodeWebIcon -Name 'alert-triange' -Colour 'yellow'
    New-PodeWebText -Value ', and look another one!: '
    New-PodeWebIcon -Name 'smile' -Colour '#00CC00'
)
```

Which looks like below:

![icon_ele](../../../images/icon_ele.png)

## Actions

### Flip

You can flip an icon by passing `Horizontal` or `Vertical` to the `-Flip` parameter. You cannot supply both flip and rotate together.

### Rotate

You can rotate an icon by a fixed number of degrees by supplying a value, 45-315 in 45 degree increments, to the `-Rotate` parameter. You cannot supply both flip and rotate together.

### Spin

You can make an icon spin by supplying the `-Spin` switch.

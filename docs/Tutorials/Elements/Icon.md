# Icon

The icon element will render [feather icons](https://feathericons.com) icon to your page. To create an icon element you use [`New-PodeWebIcon`](../../../Functions/Elements/New-PodeWebIcon), and supply the name of a feather icon using `-Name`; you can also change the icon colour via `-Colour` which can be a known name (red/green/etc) or a hex value (#333333).

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

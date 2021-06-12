# Icons

All icons rendered in Pode.Web are done using [Material Design Icons](https://materialdesignicons.com). This applies to pretty much all `-Icon` parameters, except for the one on [`Set-PodeWebLoginPage`](../../Functions/Pages/Set-PodeWebLoginPage) which is actually the path to an image.

A list of searchable icons can be [found here](https://pictogrammers.github.io/@mdi/font/5.4.55/). When you've found the one you need, you only have to supply the part after `mdi-`. For example let's say you need the `mdi-github` icon, then you only need to supply the `github` part:

```powershell
New-PodeWebButton -Name 'Repository' -Icon 'github' -Url 'https://github.com/Badgerati/Pode.Web'
```

Which would look like below:

![icon_example](../../images/icon_example.png)

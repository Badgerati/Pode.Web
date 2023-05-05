# Icons

All icons rendered in Pode.Web are done using [Material Design Icons](https://materialdesignicons.com), this applies to all `-Icon` parameters.

A list of searchable icons can be [found here](https://pictogrammers.github.io/@mdi/font/7.2.96/). When you've found the one you need, you only have to supply the partof the name after `mdi-`. For example let's say you need the `mdi-github` icon, then you only need to supply the `github` part of the name:

```powershell
New-PodeWebButton -Name 'Repository' -Icon 'github' -Url 'https://github.com/Badgerati/Pode.Web'
```

Which would look like below:

![icon_example](../../images/icon_example.png)

## Name or Element

On elements such as a Button ([`New-PodeWebButton`]), when you supply the `-Icon` parameter this can be done in one of two ways:

1. You can supply just the name of the icon, such as the example at the top of this page.
2. You can supply a more dynamic icon by using [`New-PodeWebIcon`] instead.

In the case of 2., the following is the same example as above but using [`New-PodeWebIcon`] instead:

```powershell
$icon = New-PodeWebIcon -Name 'github' -Spin
New-PodeWebButton -Name 'Repository' -Icon $icon -Url 'https://github.com/Badgerati/Pode.Web'
```

Notice this time though, the icon is set to spin instead!

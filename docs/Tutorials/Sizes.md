# Sizes

Some `-Width`, `-Height`, and `-Size` parameters for elements accept either plain number or a pure CSS value.

When a plain number is supplied these parameters will append a default unit, such as `px` or `%`, and use that for the CSS width/height. In some cases, if `0` is supplied then the default value will be `auto`. For elements that support this, they will have a relevant "Size" section in their docs page.

For example, an [Image](../Elements/Image) element has a default unit of `px` for its width/height. If you wanted to add a image of 100px by 100px you could do:

```powershell
New-PodeWebImage -Source '/url/to/image.png' -Width 100 -Height 100
```

and Pode.Web will append the default `px` unit. If instead you wanted a image at 25% and 10em:

```powershell
New-PodeWebImage -Source '/url/to/image.png' -Width '25%' -Height '10em'
```

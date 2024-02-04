# Image

| Support | |
| ------- |-|
| Events | Yes |

This will render an image onto your page, using [`New-PodeWebImage`](../../../Functions/Elements/New-PodeWebImage). You need to supply a `-Source` URL to the image you wish to display:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebImage -Source '/pode.web-static/images/icon.png' -Title 'Pode' -Alignment Center
)
```

Which looks like below:

![image](../../../images/image.png)

## Size

The `-Width` and `-Height` of an image have the default unit of `px`. If `0` is specified then `auto` is used instead. Any custom value such as `10%` can be used, but if a plain number is used then `px` is appended.

## Public Content

The `-Source` parameter path for an image typically references media stored in a `public` folder in your project root. If your file system is case sensitive (default on Linux, but not on Windows), then the `public` folder in your project root MUST be all lower case. More details [available in Pode documentation](https://badgerati.github.io/Pode/Tutorials/Routes/Utilities/StaticContent/#public-directory).

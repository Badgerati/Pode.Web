# Image

| Support | |
| ------- |-|
| Events | Yes |

This will render an image onto your page, using [`New-PodeWebImage`](../../../Functions/Elements/New-PodeWebImage). You need to supply a `-Source` URL to the image you wish to display:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebImage -Source '/pode.web/images/icon.png' -Title 'Pode' -Alignment Center
)
```

Which looks like below:

![image](../../../images/image.png)

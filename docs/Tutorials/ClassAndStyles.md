# Classes and Styles

Nearly every component in Pode.Web has a `-CssClass` and a `-CssStyle` parameter. These parameters allow you to add custom classes/styles onto the components, so you can control their look and functionality.

## Classes

The `-CssClass` parameter accepts an array of strings, which are set on the `class` property on the parent element of approparite component. The classes by themselves don't do anything, but you can use them to build custom CSS files and import them via [`Import-PodeWebStylesheet`](../../Functions/Utilities/Import-PodeWebStylesheet); you can also use the custom classes as references in custom JavaScript files, and import these via [`Import-PodeWebJavaScript`](../../Functions/Utilities/Import-PodeWebJavaScript).

For example, the following would apply the `my-custom-textbox` class to a textbox:

```powershell
New-PodeWebTextbox -Name 'Message' -CssClass 'my-custom-textbox'
```

Then you could create some `/public/my-styles.css` file with the following, to set the textbox's text colour to purple:

```css
.my-custom-textbox {
    color: purple
}
```

and import it via: `Import-PodeWebStylesheet -Url '/my-styles.css'`.

or, you can create some JavaScript file at `/public/my-scripts.js` with an event to write to console on keyup. jQuery works here, as Pode.Web uses jQuery. Also, we have to reference the class then the input control, as the class is at the paraent level of the textbox element; this allows for more fine grained control of a component as a whole - such as a textbox's labels, divs, spans, etc.

```js
$('.my-custom-textbox input').off('keyup').on('keyup', (e) => {
    console.log($(e.target).val());
})
```

and import it via: `Import-PodeWebJavaScript -Url '/my-scripts.js'`.

You can add/remove classes on components using the [Class output actions](../Outputs/Components#classes). (This will add classes onto the component itself, not the parent).

## Styles

The `-CssStyle` parameter accepts a hashtable where the key is the name of a CSS property, with an appropriate value for that property. These styles are applied directly onto the main component.

For example, the following would display a paragraph with yellow text:

```powershell
New-PodeWebParagraph -CssStyle @{ Color = 'Yellow' } -Content @(
    New-PodeWebText -Value 'And then here is some more text, that also includes a '
    New-PodeWebLink -Value 'link' -Source 'https://google.com'
    New-PodeWebText -Value ' that takes you to Google'
)
```

You can set/remove CSS style properties on components using the [Style output actions](../Outputs/Components#styles).

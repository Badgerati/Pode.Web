# Classes, Styles, and Attributes

Every element can be piped into either [`Add-PodeWebClass`](../../Functions/Actions/Add-PodeWebClass), [`Add-PodeWebStyle`](../../Functions/Actions/Add-PodeWebStyle), or [`Add-PodeWebAttribute`](../../Functions/Actions/Add-PodeWebAttribute). These functions let you you add custom classes, styles, or attributes to elements during creation so you can control their look and functionality - you can also use them to control classes/styles, etc. dynamically during the running of the website as an async Action.

By default, they will all be applied to the primary Element. Some Elements are wrapped in "Containers" which might be better suited for the style/class. If you need to alter the scope, you can do so via the `-Scope` parameter on most class, style, and attribute functions.

## Classes

To add a class to an element you can pipe a new element into [`Add-PodeWebClass`](../../Functions/Actions/Add-PodeWebClass), and this will set the values on the element's `class` attribute on the frontend. The classes by themselves don't do anything, but you can use them to build custom CSS files and import them via [`Import-PodeWebStylesheet`](../../Functions/Utilities/Import-PodeWebStylesheet); you can also use the custom classes as references in custom JavaScript files, and import these via [`Import-PodeWebJavaScript`](../../Functions/Utilities/Import-PodeWebJavaScript).

For example, the following would apply the `my-custom-textbox` class to a textbox:

```powershell
New-PodeWebTextbox -Name 'Message' |
    Add-PodeWebClass -Value 'my-custom-textbox'
```

Then you could create some `/public/my-styles.css` file with the following, to set the textbox's text colour to purple:

```css
.my-custom-textbox {
    color: purple
}
```

and import it via: `Import-PodeWebStylesheet -Url '/my-styles.css'`.

or, you can create some JavaScript file at `/public/my-scripts.js` with an event to write to console on key-up. jQuery works here, as Pode.Web uses jQuery. We just have to reference the class applied to the element:

```js
$('.my-custom-textbox').off('keyup').on('keyup', (e) => {
    console.log($(e.target).val());
})
```

and import it via: `Import-PodeWebJavaScript -Url '/my-scripts.js'`.

You can add/remove adhoc classes on elements using the [Class actions](../Actions/Elements#classes). (This will add classes onto the element itself, not the parent).

## Styles

To add a CSS style to an element you can pipe a new element into [`Add-PodeWebStyle`](../../Functions/Actions/Add-PodeWebStyle), and this will set the value on the element's `style` attribute on the frontend. The `-Key` is the name of a CSS style property.

For example, the following would display a paragraph with yellow text:

```powershell
New-PodeWebParagraph -Content @(
    New-PodeWebText -Value 'And then here is some more text, that also includes a '
    New-PodeWebLink -Value 'link' -Url 'https://google.com'
    New-PodeWebText -Value ' that takes you to Google'
) |
    Add-PodeWebStyle -Key 'color' -Value 'yellow'
```

You can add/remove adhoc CSS style properties on elements using the [Style actions](../Actions/Elements#styles).

## Attributes

To add an attribute to an element you can pipe a new element into [`Add-PodeWebAttribute`](../../Functions/Actions/Add-PodeWebAttribute), and this will set the attribute on the element on the frontend. The `-Key` is the name of an HTML attribute.

For example, the following would add the `hx-confirm` attribute to a button:

```powershell
New-PodeWebButton -Name 'Example' -ScriptBlock {} |
    Add-PodeWebAttribute -Key 'hx-confirm' -Value 'Are you sure?'
```

You can add/remove adhoc attributes on elements using the [Attribute actions](../Actions/Elements#attributes).

## Visibility

You can hide an element on creation by piping it into [`Hide-PodeWebElement`](../../Functions/Actions/Hide-PodeWebElement). For example, the following will hide a textbox initially when it's created:

```powershell
New-PodeWebTextbox -Name 'Message' |
    Hide-PodeWebElement
```

You can later show the element by using the [Visibility actions](../Actions/Elements#visibility), such as [`Show-PodeWebElement`](../../Functions/Actions/Show-PodeWebElement).

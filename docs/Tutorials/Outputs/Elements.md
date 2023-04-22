# Elements

This page details the output actions available to all elements of Pode.Web.

## General

### Hide

To hide an element on the frontend, you use [`Hide-PodeWebElement`](../../../Functions/Outputs/Hide-PodeWebElement). You can hide an element either by `-Id`, or by the element's `-Name` and `-Type`:

```powershell
Hide-PodeWebElement -Type 'Card' -Name 'SomeCardName'

# or

Hide-PodeWebElement -Id 'card_somename'
```

### Show

To show an element on the frontend, you use [`Show-PodeWebElement`](../../../Functions/Outputs/Show-PodeWebElement). You can show an element either by `-Id`, or by the element's `-Name` and `-Type`:

```powershell
Show-PodeWebElement -Type 'Card' -Name 'SomeCardName'

# or

Show-PodeWebElement -Id 'card_somename'
```

## Classes

### Add

You can add a class onto an element via [`Add-PodeWebElementClass`](../../../Functions/Outputs/Add-PodeWebElementClass). You can update an element either by `-Id`, or by the element's `-Name` and `-Type`:

```powershell
Add-PodeWebElementClass -Type 'Textbox' -Name 'SomeTextboxName' -Class 'my-custom-class'

# or

Add-PodeWebElementClass -Id 'textbox_somename' -Class 'my-custom-class'
```

### Remove

You can remove a class from an element via [`Remove-PodeWebElementClass`](../../../Functions/Outputs/Remove-PodeWebElementClass). You can update an element either by `-Id`, or by the element's `-Name` and `-Type`:

```powershell
Remove-PodeWebElementClass -Type 'Textbox' -Name 'SomeTextboxName' -Class 'my-custom-class'

# or

Remove-PodeWebElementClass -Id 'textbox_somename' -Class 'my-custom-class'
```

## Styles

### Set

You can set/update the value of a CSS property on an element via [`Set-PodeWebElementStyle`](../../../Functions/Outputs/Set-PodeWebElementStyle). You can update an element either by `-Id`, or by the element's `-Name` and `-Type`:

```powershell
Set-PodeWebElementStyle -Type 'Textbox' -Name 'SomeTextboxName' -Property 'color' -Value 'red'

# or

Set-PodeWebElementStyle -Id 'textbox_somename' -Property 'color' -Value 'red'
```

### Remove

You can remove a CSS property from an element via [`Remove-PodeWebElementStyle`](../../../Functions/Outputs/Remove-PodeWebElementStyle). You can update an element either by `-Id`, or by the element's `-Name` and `-Type`:

```powershell
Remove-PodeWebElementStyle -Type 'Textbox' -Name 'SomeTextboxName' -Property 'color'

# or

Remove-PodeWebElementStyle -Id 'textbox_somename' -Property 'color'
```

# Components

This page details the available output actions available to all components of Pode.Web.

## General

### Hide

To hide a component on the frontend, you use [`Hide-PodeWebComponent`](../../../Functions/Outputs/Hide-PodeWebComponent). You can hide a component either by `-Id`, or by the component's `-Name` and `-Type`:

```powershell
Hide-PodeWebComponent -Type 'Card' -Name 'SomeCardName'

# or

Hide-PodeWebComponent -Id 'card_somename'
```

### Show

To show a component on the frontend, you use [`Show-PodeWebComponent`](../../../Functions/Outputs/Show-PodeWebComponent). You can show a component either by `-Id`, or by the component's `-Name` and `-Type`:

```powershell
Show-PodeWebComponent -Type 'Card' -Name 'SomeCardName'

# or

Show-PodeWebComponent -Id 'card_somename'
```

## Classes

### Add

You can add a class onto a component via [`Add-PodeWebComponentClass`](../../../Functions/Outputs/Add-PodeWebComponentClass). You can update a component either by `-Id`, or by the component's `-Name` and `-Type`:

```powershell
Add-PodeWebComponentClass -Type 'Textbox' -Name 'SomeTextboxName' -Class 'my-custom-class'

# or

Add-PodeWebComponentClass -Id 'textbox_somename' -Class 'my-custom-class'
```

### Remove

You can remove a class from a component via [`Remove-PodeWebComponentClass`](../../../Functions/Outputs/Remove-PodeWebComponentClass). You can update a component either by `-Id`, or by the component's `-Name` and `-Type`:

```powershell
Remove-PodeWebComponentClass -Type 'Textbox' -Name 'SomeTextboxName' -Class 'my-custom-class'

# or

Remove-PodeWebComponentClass -Id 'textbox_somename' -Class 'my-custom-class'
```

## Styles

### Set

You can set/update the value of a CSS property on a component via [`Set-PodeWebComponentStyle`](../../../Functions/Outputs/Set-PodeWebComponentStyle). You can update a component either by `-Id`, or by the component's `-Name` and `-Type`:

```powershell
Set-PodeWebComponentStyle -Type 'Textbox' -Name 'SomeTextboxName' -Property 'color' -Value 'red'

# or

Set-PodeWebComponentStyle -Id 'textbox_somename' -Property 'color' -Value 'red'
```

### Remove

You can remove a CSS property from a component via [`Remove-PodeWebComponentStyle`](../../../Functions/Outputs/Remove-PodeWebComponentStyle). You can update a component either by `-Id`, or by the component's `-Name` and `-Type`:

```powershell
Remove-PodeWebComponentStyle -Type 'Textbox' -Name 'SomeTextboxName' -Property 'color'

# or

Remove-PodeWebComponentStyle -Id 'textbox_somename' -Property 'color'
```

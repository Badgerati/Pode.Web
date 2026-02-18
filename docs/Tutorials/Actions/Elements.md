# Elements

This page details the actions available to all elements of Pode.Web.

!!! important
    Most of the functions also have an `-Element` parameter, and it should only be used when creating a new element, such as with `New-PodeWebTextbox` - otherwise attempting to use this parameter to update an existing element on the frontend will just create another new element instead! To update an element, use the `-Id` or `-Name`/`-Type` parameters instead.

## General

### Out

When rendering new elements as actions it's wise to pipe them into [`Out-PodeWebElement`](../../../Functions/Actions/Out-PodeWebElement). This will allow Pode.Web to render the new element in the correct location relative to the "sender" - ie: a Form, Button, etc.

By default, this will append the new element "after" the sender, but you can customise the location via `-AppendType` - such as appending the new element before the sender, or within the sender.

```powershell
$form = New-PodeWebForm -Name 'Search Processes' -AsCard -ScriptBlock {
    Get-Process -Name $WebEvent.Data.Name -ErrorAction Ignore |
        Select-Object Name, ID, WorkingSet, CPU |
        New-PodeWebTable -Name 'Output' |
        Out-PodeWebElement
} -Content @(
    New-PodeWebTextbox -Name 'Name'
)
```

#### Reference

You can use [`Out-PodeWebElement`](../../../Functions/Actions/Out-PodeWebElement) to create a "reference" element on the frontend, and then use the reference via [`Use-PodeWebElement`](../../../Functions/Elements/Use-PodeWebElement). The element is cached but isn't rendered to the screen. This lets you create a new element, and then reference it later on for rendering - such as buttons in table rows, so you don't have to build a new button every time:

```powershell
$table = New-PodeWebTable -Name 'Example' -Paginate -ScriptBlock {
    # create a reference to a stop button
    $stopBtn = New-PodeWebButton -Name 'Stop' -Icon 'stop-circle-outline' -IconOnly -ScriptBlock {
        Stop-Service -Name $WebEvent.Data.Value -Force | Out-Null
        Sync-PodeWebTable -Id $ParentData.ID
    }
    $stopBtn | Out-PodeWebElement -AsReference

    # create a reference to a start button
    $startBtn = New-PodeWebButton -Name 'Start' -Icon 'play-circle-outline' -IconOnly -ScriptBlock {
        Start-Service -Name $WebEvent.Data.Value | Out-Null
        Sync-PodeWebTable -Id $ParentData.ID
    }
    $startBtn | Out-PodeWebElement -AsReference

    # build rows, and use button references above
    foreach ($svc in (Get-Service)) {
        $btn = $null
        if ($svc.Status -ieq 'running') {
            $btn = Use-PodeWebElement -Element $stopBtn
        }
        else {
            $btn = Use-PodeWebElement -Element $startBtn
        }

        [ordered]@{
            Name    = $svc.Name
            Status  = "$($svc.Status)"
            Actions = @($btn)
        }
    }
}
```

## Visibility

### Hide

To hide an element on the frontend, you use [`Hide-PodeWebElement`](../../../Functions/Actions/Hide-PodeWebElement). You can hide an element either by `-Id`, or by the element's `-Name` and `-Type`:

```powershell
Hide-PodeWebElement -Type 'Card' -Name 'SomeCardName'

# or

Hide-PodeWebElement -Id 'card_somename'
```

### Show

To show an element on the frontend, you use [`Show-PodeWebElement`](../../../Functions/Actions/Show-PodeWebElement). You can show an element either by `-Id`, or by the element's `-Name` and `-Type`:

```powershell
Show-PodeWebElement -Type 'Card' -Name 'SomeCardName'

# or

Show-PodeWebElement -Id 'card_somename'
```

## Classes

### Add

You can add a class to an element via [`Add-PodeWebClass`](../../../Functions/Actions/Add-PodeWebClass). You can update an element either by `-Id`, or by the element's `-Name` and `-Type`:

```powershell
Add-PodeWebClass -Type 'Textbox' -Name 'SomeTextboxName' -Value 'my-custom-class'

# or

Add-PodeWebClass -Id 'textbox_somename' -Value 'my-custom-class'
```

### Remove

You can remove a class from an element via [`Remove-PodeWebClass`](../../../Functions/Actions/Remove-PodeWebClass). You can update an element either by `-Id`, or by the element's `-Name` and `-Type`:

```powershell
Remove-PodeWebClass -Type 'Textbox' -Name 'SomeTextboxName' -Value 'my-custom-class'

# or

Remove-PodeWebClass -Id 'textbox_somename' -Value 'my-custom-class'
```

### Rename

You can rename one class to another class on an element by using [`Rename-PodeWebClass`](../../../Functions/Actions/Rename-PodeWebClass). You can update an element either by `-Id`, or by the element's `-Name` and `-Type`:

```powershell
Rename-PodeWebClass -Type 'Textbox' -Name 'SomeTextboxName' -From 'my-custom-class' -To 'my-other-class'

# or

Rename-PodeWebClass -Id 'textbox_somename' -From 'my-custom-class' -To 'my-other-class'
```

### Switch

You can toggle a class to be added/removed by using [`Switch-PodeWebClass`](../../../Functions/Actions/Switch-PodeWebClass). By default, this will toggle a class between being added/removed, but you can specify the state to be added or removed by supplying the `-State` parameter. You can update an element either by `-Id`, or by the element's `-Name` and `-Type`:

```powershell
Switch-PodeWebClass -Type 'Textbox' -Name 'SomeTextboxName' -Value 'my-custom-class'

# or

Switch-PodeWebClass -Id 'textbox_somename' -Value 'my-custom-class' -State Remove
```

## Styles

### Add

You can add/update the value of a CSS property on an element via [`Add-PodeWebStyle`](../../../Functions/Actions/Add-PodeWebStyle). You can update an element either by `-Id`, or by the element's `-Name` and `-Type`:

```powershell
Add-PodeWebStyle -Type 'Textbox' -Name 'SomeTextboxName' -Key 'color' -Value 'red'

# or

Add-PodeWebStyle -Id 'textbox_somename' -Key 'color' -Value 'red'
```

### Remove

You can remove a CSS property from an element via [`Remove-PodeWebStyle`](../../../Functions/Actions/Remove-PodeWebStyle). You can update an element either by `-Id`, or by the element's `-Name` and `-Type`:

```powershell
Remove-PodeWebStyle -Type 'Textbox' -Name 'SomeTextboxName' -Key 'color'

# or

Remove-PodeWebStyle -Id 'textbox_somename' -Key 'color'
```


## Attributes

### Add

You can add/update the attributes on an element via [`Add-PodeWebAttribute`](../../../Functions/Actions/Add-PodeWebAttribute). You can update an element either by `-Id`, or by the element's `-Name` and `-Type`:

```powershell
Add-PodeWebAttribute -Type 'Textbox' -Name 'SomeTextboxName' -Key 'hx-confirm' -Value 'Are you sure?'

# or

Add-PodeWebAttribute -Id 'textbox_somename' -Key 'hx-confirm' -Value 'Are you sure?'
```

### Remove

You can remove an attribute from an element via [`Remove-PodeWebAttribute`](../../../Functions/Actions/Remove-PodeWebAttribute). You can update an element either by `-Id`, or by the element's `-Name` and `-Type`:

```powershell
Remove-PodeWebAttribute -Type 'Textbox' -Name 'SomeTextboxName' -Key 'hx-confirm'

# or

Remove-PodeWebAttribute -Id 'textbox_somename' -Key 'hx-confirm'
```

## Padding

### Set

You can set the padding of an element using [`Set-PodeWebPadding`](../../../Functions/Actions/Set-PodeWebPadding). You can update an element either by `-Id`, or by the element's `-Name` and `-Type`; you can also control the individual padding values for `-Left`, `-Right`, `-Top`, and `-Bottom`, or you can set them all at once via `-Value`.

Padding values can be supplied in a range of 0 to 5, with 0 being no padding and 5 being the most padding.

```powershell
Set-PodeWebPadding -Type 'Textbox' -Name 'SomeTextboxName' -Value 3
Set-PodeWebPadding -Type 'Textbox' -Name 'SomeTextboxName' -Right 3 -Left 4

# or

Set-PodeWebPadding -Id 'textbox_somename' -Value 3
Set-PodeWebPadding -Id 'textbox_somename' -Right 3 -Left 4
```

## Margin

### Set

You can set the margin of an element using [`Set-PodeWebMargin`](../../../Functions/Actions/Set-PodeWebMargin). You can update an element either by `-Id`, or by the element's `-Name` and `-Type`; you can also control the individual margin values for `-Left`, `-Right`, `-Top`, and `-Bottom`, or you can set them all at once via `-Value`.

Margin values can be supplied in a range of 0 to 5, with 0 being no margin and 5 being the largest margin.

```powershell
Set-PodeWebMargin -Type 'Textbox' -Name 'SomeTextboxName' -Value 3
Set-PodeWebMargin -Type 'Textbox' -Name 'SomeTextboxName' -Right 3 -Left 4

# or

Set-PodeWebMargin -Id 'textbox_somename' -Value 3
Set-PodeWebMargin -Id 'textbox_somename' -Right 3 -Left 4
```

## Display

### Set

You can set the display mode of an element using [`Set-PodeWebDisplay`](../../../Functions/Actions/Set-PodeWebDisplay). You can update an element either by `-Id`, or by the element's `-Name` and `-Type`

Display values allowed are:

* Block
* Inline
* Inline-Block
* Flex
* Inline-Flex
* None

```powershell
Set-PodeWebDisplay -Type 'Textbox' -Name 'SomeTextboxName' -Value 'Inline-Block'

# or

Set-PodeWebDisplay -Id 'textbox_somename' -Value 'Flex'
```

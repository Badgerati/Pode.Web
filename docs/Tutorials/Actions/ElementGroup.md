# Element Group

This page details the actions available to Element Groups.

## Reset

To reset the input, select, and textarea elements contained within an Element Group you can use [`Reset-PodeWebElementGroup`](../../../Functions/Actions/Reset-PodeWebElementGroup):

```powershell
New-PodeWebElementGroup -Id 'ele_grp' -Content @(
    New-PodeWebTextbox -Name 'Name' -Type Text -Placeholder 'Name'

    New-PodeWebButton -Name 'Reset' -ScriptBlock {
        Reset-PodeWebElementGroup -Id 'ele_grp'
    }
)
```

## Submit

To programmatically submit an Element Group you can use [`Submit-PodeWebElementGroup`](../../../Functions/Actions/Submit-PodeWebElementGroup). This does require an Element Group to be created with a `-SubmitButtonId`:

```powershell
New-PodeWebElementGroup -Id 'ele_grp' -SubmitButtonId 'click_me' -Content @(
    New-PodeWebTextbox -Name 'Name' -Type Text -Placeholder 'Name'

    New-PodeWebButton -Name 'Click Me' -Id 'click_me' -ScriptBlock {
        Show-PodeWebToast -Message "Hi, $($WebEvent.Data.Name)!"
    }

    New-PodeWebButton -Name 'Dynamic Submit' -ScriptBlock {
        Submit-PodeWebElementGroup -Id 'ele_grp'
    }
)
```

## Update

You can update the submit ButtonId being used by an Element Group with [`Update-PodeWebElementGroup`](../../../Functions/Actions/Update-PodeWebElementGroup):

```powershell
New-PodeWebElementGroup -Id 'ele_grp' -SubmitButtonId 'submit1' -Content @(
    New-PodeWebTextbox -Name 'Name' -Type Text -Placeholder 'Name'

    New-PodeWebButton -Name 'Submit1' -Id 'submit1' -ScriptBlock {
        Update-PodeWebElementGroup -Id 'ele_grp' -SubmitButtonId 'submit2'
    }

    New-PodeWebButton -Name 'Submit2' -Id 'submit2' -ScriptBlock {
        Show-PodeWebToast -Message "Hi, $($WebEvent.Data.Name)!"
    }
)
```

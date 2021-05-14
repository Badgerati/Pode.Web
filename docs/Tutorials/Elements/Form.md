# Form

A form is kind of like a layout, but is an element that contains other elements. It automatically wraps the `-Content` as a `<form>` and adds a submit button to the bottom. When clicked, the form is serialised and sent to the `-ScriptBlock`. To add a form to you page use [`New-PodeWebForm`](../../../Functions/Elements/New-PodeWebForm) along with other form elements:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        $WebEvent.Data | Out-Default
    } -Content @(
        New-PodeWebTextbox -Name 'Name' -AutoComplete {
            return @('billy', 'bobby', 'alice', 'john', 'sarah', 'matt', 'zack', 'henry')
        }
        New-PodeWebTextbox -Name 'Password' -Type Password -PrependIcon Lock
        New-PodeWebTextbox -Name 'Date' -Type Date
        New-PodeWebTextbox -Name 'Time' -Type Time
        New-PodeWebDateTime -Name 'DateTime' -NoLabels
        New-PodeWebCredential -Name 'Credentials' -NoLabels
        New-PodeWebCheckbox -Name 'Checkboxes' -Options @('Terms', 'Privacy') -AsSwitch
        New-PodeWebRadio -Name 'Radios' -Options @('S', 'M', 'L')
        New-PodeWebSelect -Name 'Role' -Options @('User', 'Admin', 'Operations') -Multiple
        New-PodeWebRange -Name 'Cores' -Value 30 -ShowValue
    )
)
```

Which looks like below:

![form](../../../images/form.png)

## Elements

The available form elements in Pode.Web are:

* [Checkbox](../Checkbox)
* [Credentials](../Credentials)
* [DateTime](../DateTime)
* [FileUpload](../FileUpload)
* [Hidden](../Hidden)
* [Radio](../Radio)
* [Range](../Range)
* [Select](../Select)
* [Textbox](../Textbox)

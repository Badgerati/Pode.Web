# Form Elements

The following Form input elements are available, and this page details common parameters available to each of them.

* [Checkbox](../Elements/Checkbox)
* [Credentials](../Elements/Credentials)
* [Datalist](../Elements/Datalist)
* [DateTime](../Elements/DateTime)
* [File Upload](../Elements/FileUpload)
* [MinMax](../Elements/MinMax)
* [Radio](../Elements/Radio)
* [Range](../Elements/Range)
* [Select](../Elements/Select)
* [Textbox](../Elements/Textbox)

## Labels

### State

You can control a Form Element's label appearance using `-LabelState`, with the default value being `Automatic` - the label will appear if the element is detected to be within a Form.

You can also force the label to `Show` or `Hide`, allowing to to force a label to be shown or hidden.

```powershell
New-PodeWebTextbox -Name 'Password' -Type Password -LabelState Hide -Required
```

### Width

You can optionally specify the width used by the label, by using the `-LabelWidth` parameter. Form elements are rendered using a grid, which is split up into 12 segments, and the `-LabelWidth` parameter lets you specify a value between 1 and 12 - the default value is 2. A value of 12 means the label takes up the full width of the grid, where as 6 would be half the width.

You can also supply the value as a percentage as well; 50% being 6 segments, etc.

```powershell
New-PodeWebTextbox -Name 'Date' -Type Date -LabelWidth 1
```

# DateTime

The DateTime element is a form input element, and can be added using [`New-PodeWebDateTime`](../../../Functions/Elements/New-PodeWebDateTime). This will automatically add a date and time input fields to your form:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        $date = $WebEvent.Data['CreateDate_Date']
        $time = $WebEvent.Data['CreateDate_Time']
    } -Content @(
        New-PodeWebDateTime -Name 'CreateDate'
    )
)
```

Which looks like below:

![datetime](../../../images/datetime.png)

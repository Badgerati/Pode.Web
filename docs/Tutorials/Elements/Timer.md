# Timer

| Support |     |
| ------- | --- |
| Events  | No  |

A timer is a non-visible element, it sets up a javascript timer in the background that periodically invokes logic on the server. You can add a timer using [`New-PodeWebTimer`](../../../Functions/Elements/New-PodeWebTimer).

!!! warning
    You can set the interval of a timer to run using the `-Interval` parameter, in seconds. The default is 60s, and you can set this to whatever you need: 120s, 30, 15s, etc.; you can also set this to lower values such as 5s and 1s, however, please note that the lower you set the value it might have an adverse affect on the performance of your website - depending on the logic being invoked.

The below example sets up a timer that will update a badge's value and colour every 10 seconds:

```powershell
New-PodeWebTimer -Interval 10 -ScriptBlock {
    $rand = Get-Random -Minimum 0 -Maximum 3
    $colour = (@('Green', 'Yellow', 'Cyan'))[$rand]
    Update-PodeWebBadge -Id 'bdg_example' -Value ([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss')) -Colour $colour
}

New-PodeWebCard -Content @(
    New-PodeWebBadge -Id 'bdg_example' -Value ([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss')) -Colour Cyan
)
```

You can pass values to the scriptblock by using the `-ArgumentList` parameter. This accepts an array of values/objects, and they are supplied as parameters to the scriptblock:

```powershell
New-PodeWebTimer -Interval 10 -ArgumentList 'Value1', 2, $false -ScriptBlock {
    param($value1, $value2, $value3)

    # $value1 = 'Value1'
    # $value2 = 2
    # $value3 = $false
}
```

# Timer

A timer is a non-visible element, it sets up a javascript timer in the background that periodically (60s) invokes logic. You can add a timer using [`New-PodeWebTimer`](../../../Functions/Elements/New-PodeWebTimer), and they're mostly used with the outputs function to alter the page.

The below example sets up a timer that will update the badge's value and colour every 10 seconds:

```powershell
New-PodeWebTimer -Name ExampleTimer -Interval 10 -ScriptBlock {
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
New-PodeWebTimer -Name 'Example' -Interval 10 -ArgumentList 'Value1', 2, $false -ScriptBlock {
    param($value1, $value2, $value3)

    # $value1 = 'Value1'
    # $value2 = 2
    # $value3 = $false
}
```

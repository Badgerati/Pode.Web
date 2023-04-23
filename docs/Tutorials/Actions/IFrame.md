# IFrame

This page details the actions available to IFrames.

## Update

To update an iframe's URL you can use [`Update-PodeWebIFrame`](../../../Functions/Actions/Update-PodeWebIFrame):

```powershell
# set toggle buttons for different pages
$con1 = New-PodeWebContainer -Content @(
    1..3 |  ForEach-Object {
        New-PodeWebButton -Name "Page$_" -ScriptBlock {
            Update-PodeWebIFrame -Name 'IFrame' -Url "/pages/$($ElementData.Name)"
        }
    }
)

# create iframe
$con2 = New-PodeWebContainer -Content @(
    New-PodeWebIFrame -Name 'IFrame' -Url '/pages/Page1'
)

# add page with buttons/iframe
Add-PodeWebPage -Name 'Example' -Content $con1, $con2

# add 3 hidden pages for the iframe to toggle between
1..3 |  ForEach-Object {
    Add-PodeWebPage -Name "Page$_" -Hide -Content @(
        New-PodeWebContainer -Content @(
            New-PodeWebText -Value "Page$_!"
        )
    )
}
```

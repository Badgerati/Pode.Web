# Raw

This page details the actions available to Raw elements.

## Update

To update the value of a Raw element, you can use [`Update-PodeWebRaw`](../../../Functions/Actions/Update-PodeWebRaw):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebRaw -Name 'ExampleRaw' -Value '<h1>Initial Value</h1>'

    New-PodeWebTimer -Interval 10 -ScriptBlock {
        $size = Get-Random -Minimum 1 -Maximum 7
        Update-PodeWebRaw -Name 'ExampleRaw' -Value "<h$($size)>Random Size</h$($size)>"
    }
)
```

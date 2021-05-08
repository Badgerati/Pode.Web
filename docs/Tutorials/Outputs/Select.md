# Select

This page details the available output actions available to Select elements.

## Set

To set the current selected option/value of a select element, you can use [`Set-PodeWebSelect`](../../../Functions/Outputs/Set-PodeWebSelect):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebSelect -Name Options -Options Option1, Option2, Option3

    New-PodeWebButton -Name 'Update Select' -ScriptBlock {
        $rand = Get-Random -Minimum 0 -Maximum 3
        $opt = (@('Option1', 'Option2', 'Option3'))[$rand]
        Set-PodeWebSelect -Name Options -Value $opt
    }
)
```

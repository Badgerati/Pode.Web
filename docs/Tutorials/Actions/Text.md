# Text

This page details the actions available to Text elements, or elements available to have text updated within them.

This action differs slightly, as it doesn't just update elements created by [`New-PodeWebText`](../../../Functions/Elements/New-PodeWebText), but instead applies to the following list:

* Alert
* Badge
* Button
* Code
* CodeBlock
* Header
* Link
* Paragraph
* Quote
* Text
* Tile

## Update

To update the textual value of one of the above elements, you can use [`Update-PodeWebText`](../../../Functions/Actions/Update-PodeWebText):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebText -Value 'I have a pet'
    New-PodeWebText -Value 'dog' -Id 'pet_type'

    New-PodeWebButton -Name 'Change Pet!' -ScriptBlock {
        $rand = Get-Random -Minimum 0 -Maximum 5
        $pet = (@('dog', 'cat', 'fish', 'bear'))[$rand]
        Update-PodeWebText -Id 'pet_type' -Value $pet
    }
)
```

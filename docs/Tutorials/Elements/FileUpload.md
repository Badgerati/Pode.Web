# File Upload

| Support | |
| ------- |-|
| Events | No |

The File Upload element is a form input element, and can be created using [`New-PodeWebFileUpload`](../../../Functions/Elements/New-PodeWebFileUpload). It allows users to upload files from your page forms:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        Save-PodeRequestFile -Key 'File' -Path 'C:\some\path\file.png'
    } -Content @(
        New-PodeWebFileUpload -Name 'File'
    )
)
```

Which looks like below:

![file_upload](../../../images/file_upload.png)

## Accept

By default the file upload dialog will accept every file type, but you can filter which files are accepted via the `-Accept` parameter. This accepts an array of file types/extensions such as:

```powershell
New-PodeWebFileUpload -Name 'File' -Accept '.png', 'audio/*'
```

which will accept any `.png` file, and all sound files.

## Display Name

By default the label displays the `-Name` of the element. You can change the value displayed by also supplying an optional `-DisplayName` value; this value is purely visual, when the user submits the form the value of the element is still retrieved using the `-Name` from `$WebEvent.Data`.

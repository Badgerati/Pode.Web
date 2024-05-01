# Element Data

When using Elements some of these will allow you to supply scriptblocks to invoke actions or retrieve data, etc.

Within the scriptblocks you can use `$ElementData` to retrieve details about the current element the scriptblock is for, or you can use `$ParentData` to retrieve details about the current element's parent element.

For example, the following updates a select element by passing random options into [`Update-PodeWebSelect`](../../Functions/Actions/Update-PodeWebSelect), and the select element to update is done by using `$ElementData.Id` which refers to the current [`New-PodeWebSelect`](../../Functions/Elements/New-PodeWebSelect) element.

```powershell
New-PodeWebSelect -Name 'Random' -ScriptBlock {
    $options = @(foreach ($i in (1..10)) {
        Get-Random -Minimum 1 -Maximum 10
    })

    $options | Update-PodeWebSelect -Id $ElementData.Id
}
```

This is similar for `$ParentData`, wherein the following example the [`Sync-PodeWebTable`](../../Functions/Actions/Sync-PodeWebTable) action refreshes the table from `$ParentData.Id` which refers the the [`New-PodeWebTable`](../../Functions/Elements/New-PodeWebTable) element as it is the parent element for the [`New-PodeWebButton`](../../Functions/Elements/New-PodeWebButton) elements.

```powershell
New-PodeWebTable -Name 'Services' -DataColumn Name -ScriptBlock {
    foreach ($svc in (Get-Service)) {
        [ordered]@{
            Name      = $svc.Name
            Status    = "$($svc.Status)"
            StartType = "$($svc.StartType)"
            Actions   = @(
                New-PodeWebButton -Name 'Stop' -Icon 'Stop-Circle' -IconOnly -ScriptBlock {
                    Stop-Service -Name $WebEvent.Data.Value -Force | Out-Null
                    Show-PodeWebToast -Message "$($WebEvent.Data.Value) stopped"
                    Sync-PodeWebTable -Id $ParentData.ID
                }
                New-PodeWebButton -Name 'Start' -Icon 'Play-Circle' -IconOnly -ScriptBlock {
                    Start-Service -Name $WebEvent.Data.Value -Force | Out-Null
                    Show-PodeWebToast -Message "$($WebEvent.Data.Value) started"
                    Sync-PodeWebTable -Id $ParentData.ID
                }
            )
        }
    }
}
```

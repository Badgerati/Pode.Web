# Table

This page details the available output actions available to Tables.

## Out

To create a new table, usually appended beneath the sending element, you can use [`Out-PodeWebTable`](../../../Functions/Outputs/Out-PodeWebTable):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Show Processes' -ScriptBlock {
        Get-Process |
            Sort-Object -Property CPU -Descending |
            Select-Object -First 15 -Property Name, ID, WorkingSet, CPU |
            Out-PodeWebTable
    }
)
```

## Update

To update a table on the page, you can use [`Update-PodeWebTable`](../../../Functions/Outputs/Update-PodeWebTable):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Update Processes' -ScriptBlock {
        Get-Process |
            Sort-Object -Property CPU -Descending |
            Select-Object -First 15 -Property Name, ID, WorkingSet, CPU |
            Update-PodeWebTable -Name 'Processes'
    }

    New-PodeWebTable -Name 'Processes' -NoRefresh -ScriptBlock {
        Get-Process |
            Sort-Object -Property CPU -Descending |
            Select-Object -First 15 -Property Name, ID, WorkingSet, CPU
    }
)
```

Or, to update a single row in the table you can use [`Update-PodeWebTableRow`](../../../Functions/Outputs/Update-PodeWebTableRow). You need to supply the table's ID/Name, and then either the index of the row, or the value of that row's `-DataColumn`. The `-Data` is a HashTable/PSCustomObject containing the properties/columns that you want to update:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebTable -Name 'Processes' -DataColumn ID -NoRefresh -ScriptBlock {
        $refreshBtn = New-PodeWebButton -Name 'Refresh' -Icon 'refresh-cw' -IconOnly -ScriptBlock {
            $processId = $WebEvent.Data.Value

            Get-Process -Id $processId |
                Select-Object -Property WorkingSet, CPU |
                Update-PodeWebTableRow -Name 'Processes' -DataValue $processId
        }

        Get-Process |
            Sort-Object -Property CPU -Descending |
            Select-Object -First 15 |
            ForEach-Object {
                [ordered]@{
                    Name        = $_.Name
                    ID          = $_.ID
                    WorkingSet  = $_.WorkingSet
                    CPU         = $_.CPU
                    Refresh     = @($refreshBtn)
                }
            }
    }
)
```

## Sync

To force a table to refresh its data you can use [`Sync-PodeWebTable`](../../../Functions/Outputs/Sync-PodeWebTable):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Refresh Processes' -ScriptBlock {
        Sync-PodeWebTable -Name 'Processes'
    }

    New-PodeWebTable -Name 'Processes' -NoRefresh -ScriptBlock {
        Get-Process |
            Sort-Object -Property CPU -Descending |
            Select-Object -First 15 -Property Name, ID, WorkingSet, CPU
    }
)
```

## Clear

To clear a table's data you can use [`Clear-PodeWebTable`](../../../Functions/Outputs/Clear-PodeWebTable):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Clear Processes' -ScriptBlock {
        Clear-PodeWebTable -Name 'Processes'
    }

    New-PodeWebTable -Name 'Processes' -NoRefresh -ScriptBlock {
        Get-Process |
            Sort-Object -Property CPU -Descending |
            Select-Object -First 15 -Property Name, ID, WorkingSet, CPU
    }
)
```

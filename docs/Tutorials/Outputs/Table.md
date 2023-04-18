# Table

This page details the output actions available to Tables.

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

## Update Row

To update a single row in the table you can use [`Update-PodeWebTableRow`](../../../Functions/Outputs/Update-PodeWebTableRow). You need to supply the table's ID/Name, and then either the index of the row, or the value of that row's `-DataColumn`. The `-Data` is a HashTable/PSCustomObject containing the properties/columns that you want to update:

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

## Hide Column

To hide a column within a table, you can use [`Hide-PodeWebTableColumn`](../../../Functions/Outputs/Hide-PodeWebTableColumn). You'll need to supply the table's ID/Name and then the Key of column, specified via [`Initialize-PodeWebTableColumn`](../../../Functions/Elements/Initialize-PodeWebTableColumn) (or the Key used in a PSCustomObject or Hashtable used to build the table):

```powershell
New-PodeWebCard -Content @(
    New-PodeWebButton -Name 'HideCPU' -ScriptBlock {
        Hide-PodeWebColumn -Name 'Processes' -Key 'CPU'
    }

    New-PodeWebTable `
        -Name 'Processes' `
        -Paginate `
        -Compact `
        -ScriptBlock {
            $processes = Get-Process | Select-Object -Property Name, ID, WorkingSet, CPU

            $totalCount = $processes.Length
            $pageIndex = [int]$WebEvent.Data.PageIndex
            $pageSize = [int]$WebEvent.Data.PageSize
            $processes = $processes[(($pageIndex - 1) * $pageSize) .. (($pageIndex * $pageSize) - 1)]

            $processes | Update-PodeWebTable -Name $ElementData.Name -PageIndex $pageIndex -TotalItemCount $totalCount
        } `
        -Columns @(
            Initialize-PodeWebTableColumn -Key 'Name'
            Initialize-PodeWebTableColumn -Key 'ID'
            Initialize-PodeWebTableColumn -Key 'WorkingSet' -Name 'Memory' -Alignment Center -Width 10
            Initialize-PodeWebTableColumn -Key 'CPU'
        )
)
```

## Show Column

To show a column within a table, you can use [`Show-PodeWebTableColumn`](../../../Functions/Outputs/Show-PodeWebTableColumn). You'll need to supply the table's ID/Name and then the Key of column, specified via [`Initialize-PodeWebTableColumn`](../../../Functions/Elements/Initialize-PodeWebTableColumn) (or the Key used in a PSCustomObject or Hashtable used to build the table):

```powershell
New-PodeWebCard -Content @(
    New-PodeWebButton -Name 'ShowCPU' -ScriptBlock {
        Show-PodeWebColumn -Name 'Processes' -Key 'CPU'
    }

    New-PodeWebTable `
        -Name 'Processes' `
        -Paginate `
        -Compact `
        -ScriptBlock {
            $processes = Get-Process | Select-Object -Property Name, ID, WorkingSet, CPU

            $totalCount = $processes.Length
            $pageIndex = [int]$WebEvent.Data.PageIndex
            $pageSize = [int]$WebEvent.Data.PageSize
            $processes = $processes[(($pageIndex - 1) * $pageSize) .. (($pageIndex * $pageSize) - 1)]

            $processes | Update-PodeWebTable -Name $ElementData.Name -PageIndex $pageIndex -TotalItemCount $totalCount
        } `
        -Columns @(
            Initialize-PodeWebTableColumn -Key 'Name'
            Initialize-PodeWebTableColumn -Key 'ID'
            Initialize-PodeWebTableColumn -Key 'WorkingSet' -Name 'Memory' -Alignment Center -Width 10
            Initialize-PodeWebTableColumn -Key 'CPU' -Hide
        )
)
```

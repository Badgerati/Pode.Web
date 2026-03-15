Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Initialize-PodeWebTemplates -Title 'Tables' -Theme Dark

    # set the home page controls
    $card1 = New-PodeWebTable `
        -Name 'Empty Table' `
        -ScriptBlock {} `
        -AsCard `
        -Columns @(
        Initialize-PodeWebTableColumn -Key 'Name'
        Initialize-PodeWebTableColumn -Key 'ID'
        Initialize-PodeWebTableColumn -Key 'WorkingSet' -Name 'Memory'
        Initialize-PodeWebTableColumn -Key 'CPU'
    )

    $card2 = New-PodeWebCard -Name 'Processes' -Content @(
        New-PodeWebButton -Name 'HideCPU' -ScriptBlock {
            Hide-PodeWebTableColumn -Name 'Processes' -Key 'CPU'
        }

        New-PodeWebButton -Name 'ShowCPU' -ScriptBlock {
            Show-PodeWebTableColumn -Name 'Processes' -Key 'CPU'
        }

        New-PodeWebTable `
            -Name 'Processes' `
            -PageSize 4 `
            -Paginate `
            -Filter `
            -SimpleFilter `
            -Compact `
            -ScriptBlock {
            $processes = Get-Process | Select-Object -Property Name, ID, WorkingSet, CPU

            $totalCount = $processes.Length
            $pageIndex = [int]$WebEvent.Data.PageIndex
            $pageSize = [int]$WebEvent.Data.PageSize
            $processes = $processes[(($pageIndex - 1) * $pageSize) .. (($pageIndex * $pageSize) - 1)]

            Start-Sleep -Seconds 2

            $processes | Update-PodeWebTable -Name $ElementData.Name -PageIndex $pageIndex -TotalItemCount $totalCount
        } `
            -Columns @(
            Initialize-PodeWebTableColumn -Key 'Name'
            Initialize-PodeWebTableColumn -Key 'ID'
            Initialize-PodeWebTableColumn -Key 'WorkingSet' -Name 'Memory' -Alignment Center -Width 10
            Initialize-PodeWebTableColumn -Key 'CPU' -Hide
        )
    )

    $multiTable = New-PodeWebTable `
        -Name 'MultiSelect' `
        -PageSize 4 `
        -Paginate `
        -Filter `
        -SimpleFilter `
        -Compact `
        -DataColumn 'ID' `
        -MultiSelect `
        -ScriptBlock {
        $allProcesses = @(Get-Process | ForEach-Object {
                [ordered]@{
                    Name       = $_.Name
                    ID         = $_.Id
                    WorkingSet = $_.WorkingSet
                    CPU        = $_.CPU
                }
            })

        $totalCount = $allProcesses.Count
        $pageIndex = [int]$WebEvent.Data.PageIndex
        $pageSize = [int]$WebEvent.Data.PageSize
        $processes = $allProcesses[(($pageIndex - 1) * $pageSize) .. (($pageIndex * $pageSize) - 1)]

        $processes | Update-PodeWebTable -Name $ElementData.Name -PageIndex $pageIndex -TotalItemCount $totalCount
    } `
        -Columns @(
        Initialize-PodeWebTableColumn -Key 'Name'
        Initialize-PodeWebTableColumn -Key 'ID'
        Initialize-PodeWebTableColumn -Key 'WorkingSet' -Name 'Memory'
        Initialize-PodeWebTableColumn -Key 'CPU' -Hide
    )

    $multiTable | Add-PodeWebTableButton -Name 'StopSelected' -DisplayName 'Stop Selected' -Icon 'delete' -WithText -ScriptBlock {
        $selected = $WebEvent.Data['Selection'] -split ','
        if ($selected.Length -eq 0) {
            Show-PodeWebToast -Message 'No processes selected' -Title 'MultiSelect' -Duration 3000
        }
        else {
            Show-PodeWebModal -Name 'StopSelected' -Actions @(
                Update-PodeWebTextbox -Name 'SelectedProcesses' -Value ($selected -join "`n")
            )
        }
    }

    $stopModal = New-PodeWebModal -Name 'StopSelected' -DisplayName 'Stop Selected Processes' -Size 'Medium' -AsForm -Content @(
        New-PodeWebTextbox -Name 'SelectedProcesses' -DisplayName 'Selected Process IDs' -Multiline -ReadOnly
    ) -ScriptBlock {
        $ids = ($WebEvent.Data['SelectedProcesses'] -split "`n") | Where-Object { ![string]::IsNullOrWhiteSpace($_) }
        foreach ($id in $ids) {
            Stop-Process -Id ([int]$id) -Force -ErrorAction SilentlyContinue
        }
        Show-PodeWebToast -Message "Stopped $($ids.Count) process(es)" -Title 'Done' -Duration 3000
        Hide-PodeWebModal
    }

    $card3 = New-PodeWebCard -Name 'MultiSelect Processes' -Content $multiTable

    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Content $card1, $card2, $card3, $stopModal -Title 'Tables'
}
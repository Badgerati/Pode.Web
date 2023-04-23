Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force
Import-Module ImportExcel -Force

Start-PodeServer -StatusPageExceptions Show {
    Export-PodeModule -Name ImportExcel


    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging


    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title Test -Logo '/pode.web/images/icon.png' -Theme Dark


    # add a page to search and filter services (output in a new table element)
    $modal = New-PodeWebModal -Name 'Edit Service' -Id 'modal_edit_svc' -AsForm -Content @(
        New-PodeWebAlert -Type Info -Value 'This does nothing, it is just an example'
        New-PodeWebCheckbox -Name Running -Id 'chk_svc_running' -AsSwitch
    ) -ScriptBlock {
        $WebEvent.Data | Out-Default
        Hide-PodeWebModal
    }

    $table = New-PodeWebTable -Name 'Static' -DataColumn Name -AsCard -Click -Paginate -ScriptBlock {
        $stopBtn = New-PodeWebButton -Name 'Stop' -Icon 'stop-circle' -IconOnly -ScriptBlock {
            Stop-Service -Name $WebEvent.Data.Value -Force | Out-Null
            Show-PodeWebToast -Message "$($WebEvent.Data.Value) stopped"
            Sync-PodeWebTable -Id $ElementData.Parent.ID
        }

        $startBtn = New-PodeWebButton -Name 'Start' -Icon 'play-circle' -IconOnly -ScriptBlock {
            Start-Service -Name $WebEvent.Data.Value | Out-Null
            Show-PodeWebToast -Message "$($WebEvent.Data.Value) started"
            Sync-PodeWebTable -Id $ElementData.Parent.ID
        }

        $editBtn = New-PodeWebButton -Name 'Edit' -Icon 'square-edit-outline' -IconOnly -ScriptBlock {
            $svc = Get-Service -Name $WebEvent.Data.Value
            $checked = ($svc.Status -ieq 'running')

            Show-PodeWebModal -Id 'modal_edit_svc' -DataValue $WebEvent.Data.Value -Actions @(
                Update-PodeWebCheckbox -Id 'chk_svc_running' -Checked:$checked
            )
        }

        foreach ($svc in (Get-Service)) {
            $btns = @($editBtn)
            if ($svc.Status -ieq 'running') {
                $btns += $stopBtn
            }
            else {
                $btns += $startBtn
            }

            [ordered]@{
                Name = $svc.Name
                Status = "$($svc.Status)"
                Actions = $btns
            }
        }
    }

    Add-PodeStaticRoute -Path '/download' -Source '.\storage' -DownloadOnly

    $table | Add-PodeWebTableButton -Name 'Excel' -Icon 'chart-bar' -ScriptBlock {
        $path = Join-Path (Get-PodeServerPath) '.\storage\test.xlsx'
        $WebEvent.Data | Export-Excel -WorksheetName Log -TableName Log -AutoSize -Path $path
        Set-PodeResponseAttachment -Path '/download/test.xlsx'
    }

    Add-PodeWebPage -Name Services -Icon 'cogs' -Group Tools -Content $modal, $table -ScriptBlock {
        $name = $WebEvent.Query['value']
        if ([string]::IsNullOrWhiteSpace($name)) {
            return
        }

        $svc = Get-Service -Name $name | Out-String

        New-PodeWebCard -Name "$($name) Details" -Content @(
            New-PodeWebCodeBlock -Value $svc -NoHighlight
        )
    }

}
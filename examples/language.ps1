Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer -StatusPageExceptions Show {
    # add a simple endpoint
    Add-PodeEndpoint -Address * -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging


    # set the use of templates
    Use-PodeWebTemplates -Title 'Test' -Logo '/pode.web/images/icon.png' -Theme Dark

    $chartData = {
        $count = 1
        if ($WebEvent.Data.FirstLoad -eq '1') {
            $count = 4
        }

        return (1..$count | ForEach-Object {
            @{
                Key = $_
                Values = @(
                    @{
                        Key = 'Example1'
                        Value = (Get-Random -Maximum 10)
                    },
                    @{
                        Key = 'Example2'
                        Value = (Get-Random -Maximum 10)
                    }
                )
            }
        })
    }

    $processData = {
        Get-Process |
            Sort-Object -Property CPU -Descending |
            Select-Object -First 10 |
            ConvertTo-PodeWebChartData -LabelProperty ProcessName -DatasetProperty CPU, Handles
    }

    $grid1 = New-PodeWebGrid -Cells @(
        New-PodeWebCell -Content @(
            New-PodeWebChart -Name 'Line Example 1' -DisplayName '行の例' -Type Line -ScriptBlock $chartData -Append -TimeLabels -MaxItems 15 -AutoRefresh -AsCard
        )
        New-PodeWebCell -Content @(
            New-PodeWebChart -Name 'Top Processes' -DisplayName 'トッププロセス' -Type Bar -ScriptBlock $processData -AutoRefresh -RefreshInterval 10 -AsCard
        )
        New-PodeWebCell -Content @(
            New-PodeWebCounterChart -DisplayName 'プロセッサ時間' -Counter '\Processor(_Total)\% Processor Time' -MinY 0 -MaxY 100 -AsCard
        )
    )

    Set-PodeWebHomePage -Content $grid1 -DisplayName '家'


    # add a page to search and filter services (output in a new table element) [note: requires auth]
    $editModal = New-PodeWebModal -Name 'Edit Service' -Icon 'square-edit-outline' -Id 'modal_edit_svc' -AsForm -Content @(
        New-PodeWebAlert -Type Info -Value 'This does nothing, it is just an example'
        New-PodeWebCheckbox -Name Running -Id 'chk_svc_running' -AsSwitch
    ) -ScriptBlock {
        $WebEvent.Data | Out-Default
        Hide-PodeWebModal
    }

    $helpModal = New-PodeWebModal -Name 'Help' -Icon 'help' -Content @(
        New-PodeWebText -Value 'HELP!'
    )

    $table = New-PodeWebTable -Name 'Services' -DisplayName 'サービス' -DataColumn Name -AsCard -Filter -SimpleSort -Click -Paginate -ScriptBlock {
        $stopBtn = New-PodeWebButton -Name 'Stop' -Icon 'stop-circle-outline' -IconOnly -ScriptBlock {
            Stop-Service -Name $WebEvent.Data.Value -Force | Out-Null
            Show-PodeWebToast -Message "$($WebEvent.Data.Value) stopped"
            Sync-PodeWebTable -Id $ElementData.Parent.ID
        }

        $startBtn = New-PodeWebButton -Name 'Start' -Icon 'play-circle-outline' -IconOnly -ScriptBlock {
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

        $filter = "*$($WebEvent.Data.Filter)*"

        foreach ($svc in (Get-Service)) {
            if ($svc.Name -inotlike $filter) {
                continue
            }

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

    Add-PodeWebPage -Name Services -DisplayName 'サービス' -Icon 'cogs' -Group Tools -Content $editModal, $helpModal, $table -ScriptBlock {
        $name = $WebEvent.Query['value']
        if ([string]::IsNullOrWhiteSpace($name)) {
            return
        }

        $svc = Get-Service -Name $name | Out-String

        New-PodeWebCard -Name "$($name) Details" -Content @(
            New-PodeWebCodeBlock -Value $svc -NoHighlight
        )
    } `
    -HelpScriptBlock {
        Show-PodeWebModal -Name 'Help'
    }


    # open twitter
    Add-PodeWebPageLink -Name Twitter -DisplayName 'Tweet' -Icon Twitter -Group Social -ScriptBlock {
        Move-PodeWebUrl -Url 'https://twitter.com' -NewTab
    }
}
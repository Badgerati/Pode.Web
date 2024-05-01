Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Async Updates' -Theme Dark -RootRedirect

    # add a home page page
    Add-PodeWebPage -Name 'Page 1' -Id 'page_1' -HomePage -ScriptBlock {
        New-PodeWebCard -Name 'Welcome' -NoTitle -Content @(
            New-PodeWebParagraph -Value 'This is an example homepage, with some example text'
            New-PodeWebParagraph -Value 'Using some example paragraphs'
        )
    }

    # add a second page
    Add-PodeWebPage -Name 'Page 2' -Id 'page_2' -ScriptBlock {
        New-PodeWebCard -Name 'About' -NoTitle -Content @(
            New-PodeWebParagraph -Value 'Random about page'
        )
    }

    # add a third page - table
    Add-PodeWebPage -Name 'Processes' -ScriptBlock {
        New-PodeWebCard -Name 'Processes' -NoTitle -Content @(
            New-PodeWebTable -Name 'Processes' -Paginate -ScriptBlock {
                Set-PodeWebAsyncHeader
                $null = Invoke-PodeTask -Name 'GetProcesses' -ArgumentList @{
                    AsyncEvent = Export-PodeWebAsyncEvent
                    PageIndex  = $WebEvent.Data.PageIndex
                    PageSize   = $WebEvent.Data.PageSize
                }
            }
        )
    }

    # add a forth page - chart
    Add-PodeWebPage -Name 'Chart' -Id 'page_chart' -ScriptBlock {
        New-PodeWebCard -Name 'Chart' -NoTitle -Content @(
            New-PodeWebChart -Name 'Numbers' -Type Line -ScriptBlock {} -Append -TimeLabels -MaxItems 15
        )
    }

    # async task to load the processes and populate the table
    Add-PodeTask -Name 'GetProcesses' -ScriptBlock {
        param([hashtable]$AsyncEvent, [int]$PageIndex, [int]$PageSize)

        $AsyncEvent | Set-PodeWebAsyncEvent
        Start-Sleep -Seconds 2

        $processes = Get-Process | Select-Object -Property Name, ID, WorkingSet, CPU
        $totalCount = $processes.Length
        $processes = $processes[(($PageIndex - 1) * $PageSize) .. (($PageIndex * $PageSize) - 1)]
        $processes | Update-PodeWebTable -Name 'Processes' -PageIndex $PageIndex -TotalItemCount $totalCount
    }

    # timer to update chart page every 10s
    Add-PodeTimer -Name 'Chart Update' -Interval 10 -ScriptBlock {
        New-PodeWebAsyncEvent -Group 'page_chart' | Set-PodeWebAsyncEvent

        $item = @{
            Key    = 1
            Values = @(@{
                    Key   = 'Number'
                    Value = (Get-Random -Maximum 10)
                })
        }

        $item | Update-PodeWebChart -Name 'Numbers'
    }

    # schedule that sends toasts to all users on page_1
    Add-PodeSchedule -Name 'Toast Page 1' -Cron (New-PodeCron -Every Minute) -ScriptBlock {
        New-PodeWebAsyncEvent -Group 'page_1' | Set-PodeWebAsyncEvent
        Show-PodeWebToast -Message 'A message for all page_1 peeps!'
    }

    # schedule that sends toasts to all users on page_2
    Add-PodeSchedule -Name 'Toast Page 2' -Cron (New-PodeCron -Every Minute) -ScriptBlock {
        New-PodeWebAsyncEvent -Group 'page_2' | Set-PodeWebAsyncEvent
        Show-PodeWebToast -Message 'A different message for all page_2 peeps!'
    }

    # schedule that sends toasts to all users
    Add-PodeSchedule -Name 'Toast All' -Cron (New-PodeCron -Every Minute) -ScriptBlock {
        New-PodeWebAsyncEvent -All | Set-PodeWebAsyncEvent
        Show-PodeWebToast -Message 'A global message for all!'
    }

}
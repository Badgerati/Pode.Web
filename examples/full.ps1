Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer -StatusPageExceptions Show {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging


    # enable sessions and authentication
    Enable-PodeSessionMiddleware -Secret 'schwifty' -Duration (10 * 60) -Extend

    New-PodeAuthScheme -Form | Add-PodeAuth -Name Example -ScriptBlock {
        param($username, $password)

        # here you'd check a real user storage, this is just for example
        if ($username -eq 'morty' -and $password -eq 'pickle') {
            return @{
                User = @{
                    ID ='M0R7Y302'
                    Name = 'Morty'
                    Type = 'Human'
                }
            }
        }

        return @{ Message = 'Invalid details supplied' }
    }


    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title Test -Logo '/pode.web/images/icon.png' -Theme Dark
    Set-PodeWebLoginPage -Authentication Example


    # set the home page controls (just a simple paragraph) [note: homepage does not require auth in this example]
    $section = New-PodeWebSection -Name 'Welcome' -NoHeader -Elements @(
        New-PodeWebParagraph -Value 'This is an example homepage, with some example text'
        New-PodeWebParagraph -Elements @(
            New-PodeWebText -Value 'Using some '
            New-PodeWebText -Value 'example' -Style Italics
            New-PodeWebText -Value ' paragraphs' -Style Bold
        )
        New-PodeWebParagraph -Elements @(
            New-PodeWebText -Value "Look, here's a "
            New-PodeWebLink -Source 'https://github.com/badgerati/pode' -Value 'link' -NewTab
            New-PodeWebText -Value "! "
            New-PodeWebBadge -Value 'Sweet!' -Colour Cyan
        )
        New-PodeWebImage -Source '/pode.web/images/icon.png' -Height 70 -Location Right
        New-PodeWebQuote -Value 'Pode is awesome!' -Source 'Badgerati'
        New-PodeWebButton -Name 'Click Me' -DataValue 'PowerShell Rules!' -NoAuth -Icon Command -Colour Green -ScriptBlock {
            Show-PodeWebToast -Message "Message of the day: $($InputData.Value)"
            Show-PodeWebNotification -Title 'Hello, there' -Body 'General Kenobi' -Icon '/pode.web/images/icon.png'
        }
        New-PodeWebAlert -Type Note -Value 'Hello, world'
    )

    $section2 = New-PodeWebSection -Name 'Code' -NoHeader -Elements @(
        New-PodeWebCodeBlock -Value "Write-Host 'hello, world!'" -NoHighlight
        New-PodeWebCodeBlock -Value "
            function Write-SomeStuff
            {
                param(
                    [Parameter()]
                    [string]
                    `$Message
                )

                Write-Host `$Message
            }

            Write-SomeStuff -Message 'Hello, there'
        " -Language PowerShell
    )

    $section3 = New-PodeWebSection -Name 'Comments' -Elements @(
        New-PodeWebComment -Icon '/pode.web/images/icon.png' -Username 'Badgerati' -Message 'Lorem ipsum'
        New-PodeWebComment -Icon '/pode.web/images/icon.png' -Username 'Badgerati' -Message 'Lorem ipsum' -TimeStamp ([datetime]::Now)
    )

    $chartData = {
        return (1..1 | ForEach-Object {
            @{
                Key = $_
                Value = (Get-Random -Maximum 10)
            }
        })
    }

    $grid1 = New-PodeWebGrid -Components @(
        New-PodeWebChart -Name 'Line Example 1' -NoAuth -Type Line -ScriptBlock $chartData -Append -TimeLabels -MaxItems 30 -AutoRefresh
        New-PodeWebChart -Name 'Bar Example 1' -NoAuth -Type Bar -ScriptBlock $chartData
        New-PodeWebCounterChart -Counter '\Processor(_Total)\% Processor Time' -NoAuth
    )

    Set-PodeWebHomePage -NoAuth -Components $section, $section2, $section3, $grid1 -Title 'Awesome Homepage'


    # tabs and charts
    $tabs1 = New-PodeWebTabs -Tabs @(
        New-PodeWebTab -Name 'Line' -Components @(
            New-PodeWebChart -Name 'Line Example 2' -NoAuth -Type Line -ScriptBlock $chartData -Append -TimeLabels -MaxItems 30 -AutoRefresh -NoHeader -Height 250
        )
        New-PodeWebTab -Name 'Bar' -Components @(
            New-PodeWebChart -Name 'Bar Example 2' -NoAuth -Type Bar -ScriptBlock $chartData -NoHeader
        )
        New-PodeWebTab -Name 'Doughnut' -Components @(
            New-PodeWebChart -Name 'Doughnut Example 1' -NoAuth -Type Doughnut -ScriptBlock $chartData -NoHeader
        )
    )

    Add-PodeWebPage -Name Charts -Icon 'bar-chart-2' -Components $tabs1


    # add a page to search and filter services (output in a new table component) [note: requires auth]
    $modal = New-PodeWebModal -Name 'Edit Service' -Id 'modal_edit_svc' -Form -Elements @(
        New-PodeWebAlert -Type Info -Value 'This does nothing, it is just an example'
        New-PodeWebCheckbox -Name Running -Id 'chk_svc_running' -AsSwitch
    ) -ScriptBlock {
        $InputData | Out-Default
        Hide-PodeWebModal
    }

    $table = New-PodeWebTable -Name 'Static' -DataColumn Name -NoHeader -Filter -Sort -Click -Paginate -ScriptBlock {
        $stopBtn = New-PodeWebButton -Name 'Stop' -Icon 'Stop-Circle' -IconOnly -ScriptBlock {
            Stop-Service -Name $InputData.Value -Force | Out-Null
            Show-PodeWebToast -Message "$($InputData.Value) stopped"
            Sync-PodeWebTable -Id $ElementData.Component.ID
        }

        $startBtn = New-PodeWebButton -Name 'Start' -Icon 'Play-Circle' -IconOnly -ScriptBlock {
            Start-Service -Name $InputData.Value | Out-Null
            Show-PodeWebToast -Message "$($InputData.Value) started"
            Sync-PodeWebTable -Id $ElementData.Component.ID
        }

        $editBtn = New-PodeWebButton -Name 'Edit' -Icon 'Edit' -IconOnly -ScriptBlock {
            $svc = Get-Service -Name $InputData.Value
            $checked = ($svc.Status -ieq 'running')

            Show-PodeWebModal -Id 'modal_edit_svc' -DataValue $InputData.Value -Actions @(
                Out-PodeWebCheckbox -Id 'chk_svc_running' -Checked:$checked
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

    Add-PodeWebPage -Name Services -Icon Settings -Group Tools -Components $modal, $table -ScriptBlock {
        $name = $WebEvent.Query['value']
        if ([string]::IsNullOrWhiteSpace($name)) {
            return
        }
        
        $svc = Get-Service -Name $name | Out-String

        New-PodeWebSection -Name "$($name) Details" -Elements @(
            New-PodeWebCodeBlock -Value $svc -NoHighlight
        )
    }


    # add a page to search process (output as json in an appended textbox) [note: requires auth]
    $form = New-PodeWebForm -Name 'Search' -ScriptBlock {
        Get-Process -Name $InputData.Name -ErrorAction Ignore | Select-Object Name, ID, WorkingSet, CPU | Out-PodeWebTextbox -Multiline -Preformat -ReadOnly
    } -Elements @(
        New-PodeWebTextbox -Name 'Name'
    )

    Add-PodeWebPage -Name Processes -Icon Activity -Group Tools -Components $form
}
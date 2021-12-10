Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer -StatusPageExceptions Show {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging


    # enable sessions and authentication
    Enable-PodeSessionMiddleware -Secret 'schwifty' -Duration (10 * 60) -Extend

    New-PodeAuthScheme -Form | Add-PodeAuth -Name Example -SuccessUseOrigin -ScriptBlock {
        param($username, $password)

        # here you'd check a real user storage, this is just for example
        if ($username -eq 'morty' -and $password -eq 'pickle') {
            return @{
                User = @{
                    ID ='M0R7Y302'
                    Name = 'Morty'
                    Type = 'Human'
                    Groups = @('Developer')
                    AvatarUrl = '/pode.web/images/icon.png'
                }
            }
        }

        return @{ Message = 'Invalid details supplied' }
    }


    # set the use of templates
    Use-PodeWebTemplates -Title 'Test' -Logo '/pode.web/images/icon.png' -Theme Dark

    # set login page 
    # -BackgroundImage '/images/galaxy.jpg'
    Set-PodeWebLoginPage -Authentication Example -PassThru |
        Register-PodeWebPageEvent -Type Load, Unload, BeforeUnload -NoAuth -ScriptBlock {
            Show-PodeWebToast -Message "Login page $($EventType)!"
        }

    $link1 = New-PodeWebNavLink -Name 'Home' -Url '/' -Icon Home
    $link2 = New-PodeWebNavLink -Name 'Dynamic' -Icon Cogs -NoAuth -ScriptBlock {
        Show-PodeWebToast -Message "I'm from a nav link!"
    }
    $div1 = New-PodeWebNavDivider
    $link3 = New-PodeWebNavLink -Name 'Disabled' -Url '/' -Disabled
    $dd1 = New-PodeWebNavDropdown -Name 'Dropdown' -Icon Expand -Items @(
        New-PodeWebNavLink -Name 'Twitter' -Url 'https://twitter.com'
        New-PodeWebNavLink -Name 'Facebook' -Url 'https://facebook.com' -Disabled
        New-PodeWebNavDivider
        New-PodeWebNavLink -Name 'YouTube' -Url 'https://youtube.com' -Icon YouTube
        New-PodeWebNavDropdown -Name 'InnerDrop' -Items @(
            New-PodeWebNavLink -Name 'Twitch' -Url 'https://twitch.tv'
            New-PodeWebNavLink -Name 'Pode' -Url 'https://github.com/Badgerati/Pode'
        )
    )

    Set-PodeWebNavDefault -Items $link1, $link2, $div1, $link3, $dd1


    $timer1 = New-PodeWebTimer -Name 'Timer1' -Interval 10 -NoAuth -ScriptBlock {
        $rand = Get-Random -Minimum 0 -Maximum 3
        $colour = (@('Green', 'Yellow', 'Cyan'))[$rand]
        Update-PodeWebBadge -Id 'bdg_test' -Value ([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss')) -Colour $colour
        Update-PodeWebText -Id 'code_test' -Value ([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))
    }

    # set the home page controls (just a simple paragraph) [note: homepage does not require auth in this example]
    $section = New-PodeWebCard -Name 'Welcome' -NoTitle -Content @(
        New-PodeWebParagraph -Value 'This is an example homepage, with some example text'
        New-PodeWebParagraph -Elements @(
            New-PodeWebText -Value 'Using some '
            New-PodeWebText -Value 'example' -Style Italics
            New-PodeWebText -Value ' paragraphs' -Style Bold
        )
        New-PodeWebParagraph -Elements @(
            New-PodeWebText -Value 'Pronuncation example: '
            New-PodeWebText -Value '漢' -Pronunciation 'ㄏㄢˋ'
        )
        New-PodeWebParagraph -Elements @(
            New-PodeWebText -Value "Look, here's a "
            New-PodeWebLink -Source 'https://github.com/badgerati/pode' -Value 'link' -NewTab
            New-PodeWebText -Value "! "
            New-PodeWebBadge -Id 'bdg_test' -Value 'Sweet!' -Colour Cyan |
                Register-PodeWebEvent -Type Click -NoAuth -ScriptBlock {
                    Show-PodeWebToast -Message 'Badge was clicked!'
                }
        )
        New-PodeWebParagraph -Elements @(
            New-PodeWebCode -Id 'code_test' -Value "some code :o"
        )
        $timer1
        New-PodeWebImage -Source '/pode.web/images/icon.png' -Height 70 -Alignment Right
        New-PodeWebQuote -Value 'Pode is awesome!' -Source 'Badgerati'
        New-PodeWebButton -Name 'Click Me' -DataValue 'PowerShell Rules!' -NoAuth -Icon 'console-line' -Colour Green -ScriptBlock {
            Show-PodeWebToast -Message "Message of the day: $($WebEvent.Data.Value)"
            Show-PodeWebNotification -Title 'Hello, there' -Body 'General Kenobi' -Icon '/pode.web/images/icon.png'
        }
        New-PodeWebContainer -Content @(
            New-PodeWebButton -Name 'Dark Theme' -NoAuth -Icon 'moon-new' -Colour Dark -ScriptBlock { Update-PodeWebTheme -Name Dark }
            New-PodeWebButton -Name 'Light Theme' -NoAuth -Icon 'weather-sunny' -Colour Light -ScriptBlock { Update-PodeWebTheme -Name Light }
            New-PodeWebButton -Name 'Reset Theme' -NoAuth -Icon 'refresh' -ScriptBlock { Reset-PodeWebTheme }
        )
        New-PodeWebAlert -Type Note -Value 'Hello, world'
    )

    $section2 = New-PodeWebCard -Name 'Code' -NoTitle -Content @(
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

    $section3 = New-PodeWebCard -Name 'Comments' -Icon 'comment' -Content @(
        New-PodeWebComment -Icon '/pode.web/images/icon.png' -Username 'Badgerati' -Message 'Lorem ipsum'
        New-PodeWebComment -Icon '/pode.web/images/icon.png' -Username 'Badgerati' -Message 'Lorem ipsum' -TimeStamp ([datetime]::Now)
    )

    $codeEditor = New-PodeWebCodeEditor -Language PowerShell -Name 'Code Editor' -AsCard

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
            New-PodeWebChart -Name 'Line Example 1' -NoAuth -Type Line -ScriptBlock $chartData -Append -TimeLabels -MaxItems 15 -AutoRefresh -AsCard
        )
        New-PodeWebCell -Content @(
            New-PodeWebChart -Name 'Top Processes' -NoAuth -Type Bar -ScriptBlock $processData -AutoRefresh -RefreshInterval 10 -AsCard
        )
        New-PodeWebCell -Content @(
            New-PodeWebCounterChart -Counter '\Processor(_Total)\% Processor Time' -MinY 0 -MaxY 100 -NoAuth -AsCard
        )
    )

    $hero = New-PodeWebHero -Title 'Welcome!' -Message 'This is the home page for the full.ps1 example' -Content @(
        New-PodeWebText -Value 'Here you will see examples for close to everything Pode.Web can do.' -InParagraph -Alignment Center
        New-PodeWebParagraph -Alignment Center -Elements @(
            New-PodeWebButton -Name 'Repository' -Icon Link -Url 'https://github.com/Badgerati/Pode.Web' -NewTab
        )
    )

    $carousel = New-PodeWebCarousel -Slides @(
        New-PodeWebSlide -Title 'First Slide' -Message 'First slide message' -Content @(
            New-PodeWebContainer -Nobackground -Content @(
                New-PodeWebText -Value 'Slide 1' -Alignment Center
            )
        )
        New-PodeWebSlide -Title 'Second Slide' -Message 'Second slide message' -Content @(
            New-PodeWebContainer -Nobackground -Content @(
                New-PodeWebText -Value 'Slide 2' -Alignment Center
            )
        )
        New-PodeWebSlide -Title 'Third Slide' -Message 'Third slide message' -Content @(
            New-PodeWebContainer -Nobackground -Content @(
                New-PodeWebText -Value 'Slide 3' -Alignment Center
            )
        )
    )

    Set-PodeWebHomePage -NoAuth -Layouts $hero, $grid1, $section, $carousel, $section2, $section3, $codeEditor -NoTitle -PassThru |
        Register-PodeWebPageEvent -Type Load, Unload, BeforeUnload -NoAuth -ScriptBlock {
            Show-PodeWebToast -Message "Home page $($EventType)!"
        }


    # tabs and charts
    $tabs1 = New-PodeWebTabs -Cycle -Tabs @(
        New-PodeWebTab -Name 'Line' -Icon 'chart-line' -Layouts @(
            New-PodeWebChart -Name 'Line Example 2' -NoAuth -Type Line -ScriptBlock $chartData -Append -TimeLabels -MaxItems 30 -AutoRefresh -Height 250 -AsCard
        )
        New-PodeWebTab -Name 'Bar' -Icon 'chart-bar' -Layouts @(
            New-PodeWebChart -Name 'Bar Example 2' -NoAuth -Type Bar -ScriptBlock $chartData -AsCard
        )
        New-PodeWebTab -Name 'Doughnut' -Icon 'chart-donut' -Layouts @(
            New-PodeWebChart -Name 'Doughnut Example 1' -NoAuth -Type Doughnut -ScriptBlock $chartData -AsCard
        )
    )

    Add-PodeWebPage -Name Charts -Icon 'chart-bar' -Layouts $tabs1 -Title 'Cycling Tabs' -NoSidebar -PassThru |
        Register-PodeWebPageEvent -Type Load, Unload, BeforeUnload -ScriptBlock {
            Show-PodeWebToast -Message "Page $($EventType)!"
        }


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

    $table = New-PodeWebTable -Name 'Static' -DataColumn Name -AsCard -Filter -SimpleSort -Click -Paginate -ScriptBlock {
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

    Add-PodeStaticRoute -Path '/download' -Source '.\storage' -DownloadOnly

    $table | Add-PodeWebTableButton -Name 'Excel' -Icon 'chart-bar' -ScriptBlock {
        $path = Join-Path (Get-PodeServerPath) '.\storage\test.csv'
        $WebEvent.Data | Export-Csv -Path $path -NoTypeInformation
        Set-PodeResponseAttachment -Path '/download/test.csv'
    }

    $homeLink1 = New-PodeWebNavLink -Name 'Home' -Url '/'

    Add-PodeWebPage -Name Services -Icon 'cogs' -Group Tools -Layouts $editModal, $helpModal, $table -Navigation $homeLink1 -ScriptBlock {
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


    # add a page to search process (output as json in an appended textbox) [note: requires auth]
    $form = New-PodeWebForm -Name 'Search' -AsCard -ScriptBlock {
        if ($WebEvent.Data.Name.Length -le 3) {
            Out-PodeWebValidation -Name 'Name' -Message 'Name must be greater than 3 characters'
            return
        }

        Get-Process -Name $WebEvent.Data.Name -ErrorAction Ignore | Select-Object Name, ID, WorkingSet, CPU | Out-PodeWebTextbox -Multiline -Preformat -ReadOnly
    } -Content @(
        New-PodeWebTextbox -Name 'Name'
    )

    Add-PodeWebPage -Name Processes -Icon 'chart-box-outline' -Group Tools -AccessGroups Developer -Layouts $form


    # page with table showing csv data
    $table2 = New-PodeWebTable -Name 'Users' -DataColumn UserId -Filter -SimpleSort -Paginate -CsvFilePath './misc/data.csv' -AsCard
    Add-PodeWebPage -Name CSV -Icon Database -Group Tools -Layouts $table2


    # page with table show dynamic paging, filter, and sorting via a csv
    $table3 = New-PodeWebTable -Name 'Dynamic Users' -DataColumn UserId -Filter -Sort -Paginate -AsCard -ScriptBlock {
        # load the file
        $filePath = Join-Path (Get-PodeServerPath) 'misc/data.csv'
        $data = Import-Csv -Path $filePath

        # apply filter if present
        $filter = $WebEvent.Data.Filter
        if (![string]::IsNullOrWhiteSpace($filter)) {
            $filter = "*$($filter)*"
            $data = @($data | Where-Object { ($_.psobject.properties.value -ilike $filter).length -gt 0 })
        }

        # apply sorting
        $sortColumn = $WebEvent.Data.SortColumn
        if (![string]::IsNullOrWhiteSpace($sortColumn)) {
            $descending = ($WebEvent.Data.SortDirection -ieq 'desc')
            $data = @($data | Sort-Object -Property { $_.$sortColumn } -Descending:$descending)
        }

        # apply paging
        $totalCount = $data.Length
        $pageIndex = [int]$WebEvent.Data.PageIndex
        $pageSize = [int]$WebEvent.Data.PageSize
        $data = $data[(($pageIndex - 1) * $pageSize) .. (($pageIndex * $pageSize) - 1)]

        # update table
        $data | Update-PodeWebTable -Name 'Dynamic Users' -PageIndex $pageIndex -TotalItemCount $totalCount
    }

    Add-PodeWebPage -Name 'Dynamic Paging' -Icon Database -Group Tools -Layouts $table3


    # open twitter
    Add-PodeWebPageLink -Name Twitter -Icon Twitter -Group Social -NoAuth -ScriptBlock {
        Move-PodeWebUrl -Url 'https://twitter.com' -NewTab
    }
}
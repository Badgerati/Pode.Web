Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
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
    Use-PodeWebTemplates -Title Test
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
            New-PodeWebText -Value "!"
        )
        New-PodeWebImage -Source '/pode.web/images/icon.png' -Height 70 -Location Right
        New-PodeWebQuote -Value 'Pode is awesome!' -Source 'Badgerati'
        New-PodeWebButton -Name 'Click Me' -DataValue 'PowerShell Rules!' -NoAuth -ScriptBlock {
            Show-PodeWebToast -Message "Message of the day: $($InputData.Value)"
        }
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
        New-PodeWebChart -Name 'Months' -NoAuth -Type Line -ScriptBlock $chartData -Append -TimeLabels -MaxItems 30 -AutoRefresh
        New-PodeWebChart -Name 'Months' -NoAuth -Type Bar -ScriptBlock $chartData
        New-PodeWebChart -Name 'Months' -NoAuth -Type Doughnut -ScriptBlock $chartData
    )

    Set-PodeWebHomePage -NoAuth -Components $section, $grid1 -Title 'Awesome Homepage'


    # tabs and charts
    $tabs1 = New-PodeWebTabs -Tabs @(
        New-PodeWebTab -Name 'Line' -Components @(
            New-PodeWebChart -Name 'Months' -NoAuth -Type Line -ScriptBlock $chartData -Append -TimeLabels -MaxItems 30 -AutoRefresh -NoHeader
        )
        New-PodeWebTab -Name 'Bar' -Components @(
            New-PodeWebChart -Name 'Months' -NoAuth -Type Bar -ScriptBlock $chartData -NoHeader
        )
        New-PodeWebTab -Name 'Doughnut' -Components @(
            New-PodeWebChart -Name 'Months' -NoAuth -Type Doughnut -ScriptBlock $chartData -NoHeader
        )
    )

    Add-PodeWebPage -Name Charts -Icon 'bar-chart-2' -Components $tabs1


    # add a page to search and filter services (output in a new table component) [note: requires auth]
    $table = New-PodeWebTable -Name 'Results' -Id 'tbl_svc_results'
    $form = New-PodeWebForm -Name 'Search' -ScriptBlock {
        if ($InputData.Name.Length -lt 3) {
            Out-PodeWebValidation -Name 'Name' -Message 'Invalid service name supplied (Name should be 3+ characters)'
            return
        }

        $svcs = @(Get-Service -Name $InputData.Name -ErrorAction Ignore | Select-Object Name, Status)
        $svcs | Out-PodeWebTable -Id 'tbl_svc_results'
        Show-PodeWebToast -Message "Found $($svcs.Length) services"
    } -Elements @(
        New-PodeWebTextbox -Name 'Name'
    )

    $table2 = New-PodeWebTable -Name 'Static' -ScriptBlock {
        @(Get-Service | Select-Object Name, Status)
    }

    Add-PodeWebPage -Name Services -Icon Settings -Group Tools -Components $form, $table, $table2


    # add a page to search process (output as json in an appended textbox) [note: requires auth]
    $form = New-PodeWebForm -Name 'Search' -ScriptBlock {
        Get-Process -Name $InputData.Name -ErrorAction Ignore | Select-Object Name, ID, WorkingSet, CPU | Out-PodeWebTextbox -Multiline -Preformat
    } -Elements @(
        New-PodeWebTextbox -Name 'Name'
    )

    Add-PodeWebPage -Name Processes -Icon Activity -Group Tools -Components $form
}
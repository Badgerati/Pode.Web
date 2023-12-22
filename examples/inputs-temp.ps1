Import-Module Pode -MaximumVersion 2.99.99 -Force
# Import-Module ..\src\Pode.Web.psd1 -Force
Import-Module Pode.Web -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Inputs' -Theme Dark

    # set the home page controls (just a simple paragraph)
    # $form = New-PodeWebForm -Name 'Test' -ShowReset -AsCard -ScriptBlock {
    #     $WebEvent.Data |
    #         New-PodeWebTextbox -Name 'TestOutput' -Multiline -Preformat -AsJson |
    #         Out-PodeWebElement
    # } -Content @(
    #     # New-PodeWebCheckbox -Name 'Switches' -Options @('Terms', 'Privacy') -AsSwitch |
    #     #     Register-PodeWebEvent -Type Change -ScriptBlock {
    #     #         $x = $WebEvent.Data['Switches']
    #     #         Show-PodeWebToast -Message "'$($x)'"

    #     #         $y = $x.Split(',').Trim()
    #     #         $p = 'Privacy' -in $y
    #     #         $p | Out-Default
    #     #     }
    # )

    $container = New-PodeWebContainer -Content @(
        New-PodeWebCheckbox -Name 'Checkboxes' -Options @('Access to Email', 'Access to Personal drive', 'Mobile Phone') -AsSwitch # |
            # Register-PodeWebEvent -Type Change -ScriptBlock {
            #     Get-Module | Out-Default
            #     $x = $WebEvent.Data['Checkboxes']
            #     # if ($x) {
            #         $y = $x.Split(',').Trim()
            #     # } else {
            #     #     $y = @()
            #     # }
            #     write-host $y

            #     $ACE = 'Access to Email' -in $y
            #     Write-host $ACE
            #     $ACP = 'Access to Personal drive' -in $y
            #     Write-host $ACP
            #     $MBP = 'Mobile Phone' -in $y
            #     Write-host $MBP

            #     If ($MBP) {
            #         Show-PodeWebComponent -ID 'Mphone'
            #     }
            #     else {
            #         Hide-PodeWebComponent -ID 'Mphone'
            #     }
            # }

        New-PodeWebForm -Id "Form" -Name "Search for ESXiHost" -AsCard -ShowReset -ScriptBlock {
            'hello' | Out-Default
        } -Content @(
            New-PodeWebTextbox -Id "Search" -Name 'Search' -DisplayName 'HostName' -Type Text -Placeholder 'HostName' -NoForm -Width '960px' -CssClass 'no-form'
        )
    )

    Set-PodeWebHomePage -Layouts $container -Title 'Testing Inputs'






    Add-PodeWebPage -Group "Admin" -Name "Create User old" -Icon Activity -Layouts @(
        New-PodeWebCard -Content @(
            New-PodeWebForm -Name 'NewUser' -ScriptBlock {
                $WebEvent.Data | ConvertTo-Json | Out-File .\App_Data\Out.json

            } -Content @(
                New-PodeWebGrid -Cells @(
                    New-PodeWebCell -Content @(

                        New-PodeWebTextBox -Name 'Ticket' -Width 20 -PrependIcon Ticket -Required -placeholder '*i.e. 1234567'
                        
                        
                        New-PodeWebRadio -Name 'Employee Type' -Options @('Employee', 'Contractor') | Register-PodeWebEvent -Type Change -ScriptBlock {
                            . .\Functions\LittleHelpers.ps1
                            if ($($WebEvent.Data['Employee Type']) -ne 'Employee') {
                                # $NonEmployee = Get-EmpType -type 'NonEmployee'
                                # $Q = Get-QuartersDate
                                # Update-PodeWebTextbox -Name 'ValidToDate' -Value $Q
                                # Update-PodeWebTable -Name 'DefaultMemberships' -Data $NonEmployee
                                # $Global:SetEmployee = $false
                            }
                            else {
                                # $Employee = Get-EmpType -type 'Employee'
                                # Update-PodeWebTextbox -Name 'ValidToDate' -Value "Never"
                                # Update-PodeWebTable -Name 'DefaultMemberships' -Data $Employee
                                # $Global:SetEmployee = $true
                            }
                        } 

                        New-PodeWebTextbox -Name 'ValidToDate' -DisplayName 'Account Expires' -Value "Never" -Width 20 -ReadOnly -PrependIcon 'calendar'

                        New-PodeWebTextbox -Name 'FirstName' -DisplayName 'First Name' -Width 40 -PrependIcon 'account-alert' -Required -placeholder '*i.e. John'
                        New-PodeWebTextbox -Name 'LastName'  -DisplayName 'Last Name' -Width 40 -PrependIcon 'account-alert' -Required -placeholder '*i.e. Doe' | Register-PodeWebEvent -Type FocusOut -ScriptBlock {
                            Invoke-PodeWebButton -Name 'Generate'
                        }

                        New-PodeWebTextbox -Name 'SamAccountName'  -DisplayName 'Username' -ReadOnly -Width 40 -helptext 'If red, then it is occupied, if green, it is not' -PrependIcon 'account-key' -placeholder 'Username will be generated'
                        New-PodeWebTextbox -Name 'DBSamAccountName' -ReadOnly -Width 40


                        New-PodeWebButton -Name 'Generate' -ScriptBlock {
                            # $fn = $($WebEvent.Data['FirstName']).tolower().substring(0, 1)
                            # $ln = $($WebEvent.Data['LastName']).tolower()
                            # $concat = ($fn + $ln).replace(" ", "")
                            # . .\DB\DBcon.ps1
                            # $DBresult = Invoke-SqliteQuery -SQLiteConnection $DBConnection -Query "Select * FROM Users" | Where-Object { $_.SamAccountName -eq $concat }
                            # $ExistsInDB = $DBresult.Count

                            if ($ExistsInDB -eq 0) {
                                Update-PodeWebTextbox -Name 'SamAccountName' -Value $concat
                                Set-PodeWebComponentStyle -Type 'Textbox' -Name 'SamAccountName' -Property 'background-color' -Value '#0cb000'
                            }
                            else {
                                # $dbsam = $DBresult.SamAccountName
                                #$exists = $concat.Equals($dbsam)

                                Set-PodeWebComponentStyle -Type 'Textbox' -Name 'SamAccountName' -Property 'background-color' -Value '#D93333'
                                Update-PodeWebTextbox -Name 'DBSamAccountName' -Value $dbsam
                                Update-PodeWebTextbox -Name 'SamAccountName' -Value $concat
                            }
                        }

                        New-PodeWebLine
                        New-PodeWebTextbox -Name 'Start date' -Type Date -Width 30 -helptext 'Press the calendar on the right' -PrependIcon 'calendar'
                        New-PodeWebTextbox -Name 'Title' -Width 40 -PrependIcon 'format-title' -Required -Placeholder '*i.e. IT Supporter' -AutoComplete {
                            # . .\DB\DBcon.ps1
                            # $DBresult = Get-AllUsers | Select-Object Title | Where-Object { $_.Title -gt "" } | Sort-Object Title -Unique
                            # $v = $DBresult.Title
                            return @($v)
                        }

                        New-PodeWebTextbox -Name 'Office Phone' -DisplayName 'Desk Phone' -Width 35 -PrependIcon 'card-account-phone' -Placeholder 'i.e. +45 1234 5678'
                        New-PodeWebTextbox -Name 'Telephone Phone' -DisplayName 'Mobile Phone' -Width 35 -PrependIcon 'card-account-phone' -Placeholder 'i.e. +45 1234 5678'
                        New-PodeWebTextbox -Name 'Department' -Width 40 -PrependIcon 'account-group' -Required -Placeholder '*i.e. IT' -AutoComplete {
                            # . .\DB\DBcon.ps1
                            # $DBresult = Get-AllUsers | Select-Object Department | Where-Object { $_.Department -gt "" } | Sort-Object Department -Unique 
                            # $v = $DBresult.Department
                            return @($v)
                        }

                        New-PodeWebTextbox -Name 'Manager' -PrependIcon 'account-supervisor' -Required -Placeholder '*i.e. JDoe as John Doe' -helpText 'Use the managers username' -Width 40 -AutoComplete {
                            # . .\DB\DBcon.ps1
                            # $DBresult = Invoke-SqliteQuery -SQLiteConnection $DBConnection -Query "Select * FROM Users" | Sort-Object SamAccountName
                            # $v = $DBresult.SamAccountName
                            return @($v)
                        }
                        
                        New-PodeWebCheckbox -Name 'Checkboxes' -Options @('Access to Email', 'Access to Personal drive', 'Mobile Phone')  | Register-PodeWebEvent -Type Change -ScriptBlock {
                            $x = $WebEvent.Data['Checkboxes']
                            if (!$x) {
                                $x = ''
                            }

                            $y = $x.Split(',').Trim()
                            write-host $y

                            $ACE = 'Access to Email' -in $y
                            Write-host $ACE
                            $ACP = 'Access to Personal drive' -in $y
                            Write-host $ACP
                            $MBP = 'Mobile Phone' -in $y
                            Write-host $MBP

                            if ('Mobile Phone' -in $y) {
                                # Get-Module | Out-Default
                                Show-PodeWebComponent -ID 'Mphone'
                                Show-PodeWebToast -Message "Status: True"
                                Update-PodeWebTextbox -Name 'Model' -Value "N/A"
                            }
                            elseif ('Mobile Phone' -notin $y) {
                                Hide-PodeWebComponent -ID 'Mphone'
                                Show-PodeWebToast -Message "Status: False"
                                Update-PodeWebTextbox -Name 'Model' -Value "N/A"
                            }
                        }
                        
                        New-PodeWebTextbox -Name 'Password' -Width 25 -PrependIcon Lock -Value 'bob' #$(Get-NewPassword)
                
                        New-PodeWebButton -Name 'New Password' -Icon 'refresh' -ScriptBlock {
                            Update-PodeWebTextbox -Name 'Password' -Value 'bob' #$(Get-NewPassword)
                        }
                        New-PodeWebLine
                    )

                    New-PodeWebCell -Content @(
                        New-PodeWebContainer -Content @(
                            New-PodeWebText -Value 'Choose location' -Style Bold
                            
                            New-PodeWebSelect -Name 'Country' -Options ($json.Country | Sort-Object | Get-Unique) |
                            Register-PodeWebEvent -Type Change -ScriptBlock {
                                $adr = Get-Content .\json\Addresses.json | ConvertFrom-Json
                                $data = $adr | Where-Object { ($_.Country -eq $WebEvent.Data['Country']) -or ($_.Country -eq "-") }
                                'Company', 'Street', 'PostalCode', 'City' | ForEach-Object { Clear-PodeWebTextbox -Name $_ }

                                Update-PodeWebSelect -Name 'Location' -Options $data.City

                            }

                            New-PodeWebSelect -Name 'Location' |
                            Register-PodeWebEvent -Type Change -ScriptBlock {
                                $adr = Get-Content .\json\Addresses.json | ConvertFrom-Json
                                $data = $adr | Where-Object { $_.City -eq $WebEvent.Data['Location'] }

                                Update-PodeWebTextbox -Name 'PostalCode' -Value $data.PostalCode
                                Update-PodeWebTextbox -Name 'Street' -Value $data.StreetAddress
                                Update-PodeWebTextbox -Name 'City' -Value $data.City
                                Update-PodeWebTextbox -Name 'Company' -Value $data.Company

                            }

                            New-PodeWebTextbox -Name 'Company' -Width 60 -PrependIcon 'office-building' -Required -Placeholder '*i.e. Company' -ReadOnly 
                            New-PodeWebTextbox -Name 'Street' -Width 60 -PrependIcon 'home-city' -Required -Placeholder '*i.e. Street' -ReadOnly
                            New-PodeWebTextbox -Name 'PostalCode' -Width 30 -PrependIcon 'city' -Required -Placeholder '*i.e. Postal' -ReadOnly
                            New-PodeWebTextbox -Name 'City' -Width 60 -PrependIcon 'city' -Required -Placeholder '*i.e. City' -ReadOnly
                        )
                        
                        New-PodeWebContainer -ID 'Mphone' -Content @(
                            New-PodeWebTextbox -Name 'Model' -Width 20
                        )
                        
                        
                        New-PodeWebContainer -Content @(
                            New-PodeWebText -Value 'Memberships' -Style Bold 
                            New-PodeWebTable -Name 'DefaultMemberships' -Id 'DefaultMemberships' -NoExport -NoRefresh
                        )
                    )
                )
            )
        )
    )-PassThru | Register-PodeWebPageEvent -Type load -ScriptBlock {
        # $Employee = Get-EmpType -type 'Employee'
        # Update-PodeWebTable -Name 'DefaultMemberships' -Data $Employee
        Hide-PodeWebComponent -ID 'Mphone'
    }









}

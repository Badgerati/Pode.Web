Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8091 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Initialize-PodeWebTemplates -Title 'Autocomplete' -Theme Dark

    # form with load once autocomplete
    $onceInstant = New-PodeWebForm -Name 'OnceInstant' -ButtonType Submit -AsCard -ScriptBlock {
        $WebEvent.Data.OnceInstantOutput | Show-PodeWebToast
    } -Content @(
        New-PodeWebTextbox -Name 'OnceInstantInput' -AutoComplete {
            return @('One', 'Two', 'Three', 'Four', 'Five')
        }
    )

    # form with load every time autocomplete
    $alwaysInstant = New-PodeWebForm -Name 'AlwaysInstant' -ButtonType Submit -AsCard -ScriptBlock {
        $WebEvent.Data.AlwaysInstantOutput | Show-PodeWebToast
    } -Content @(
        New-PodeWebTextbox -Name 'AlwaysInstantInput' -AutoCompleteType Always -AutoComplete {
            return @('One', 'Two', 'Three', 'Four', 'Five') | Where-Object { $_ -imatch "^$($WebEvent.Data.Value)" }
        }
    )

    # form with load once autocomplete on 3 char delay
    $onceDelay = New-PodeWebForm -Name 'OnceDelay' -ButtonType Submit -AsCard -ScriptBlock {
        $WebEvent.Data.OnceDelayOutput | Show-PodeWebToast
    } -Content @(
        New-PodeWebTextbox -Name 'OnceDelayInput' -AutoCompleteMinLength 3 -AutoComplete {
            return @('One', 'Two', 'Three', 'Four', 'Five')
        }
    )

    # form with load every time autocomplete on 3 char delay
    $alwaysDelay = New-PodeWebForm -Name 'AlwaysDelay' -ButtonType Submit -AsCard -ScriptBlock {
        $WebEvent.Data.AlwaysDelayOutput | Show-PodeWebToast
    } -Content @(
        New-PodeWebTextbox -Name 'AlwaysDelayInput' -AutoCompleteType Always -AutoCompleteMinLength 3 -AutoComplete {
            return @('One', 'Two', 'Three', 'Four', 'Five') | Where-Object { $_ -imatch "^$($WebEvent.Data.Value)" }
        }
    )

    # add forms to page
    Add-PodeWebPage -Name 'Home' -Path '/' -Content $onceInstant, $alwaysInstant, $onceDelay, $alwaysDelay -Title 'Testing Autocomplete' -HomePage
}
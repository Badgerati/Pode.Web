Import-Module ..\..\Pode\src\Pode.psm1 -Force #-MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force


Start-PodeServer -StatusPageExceptions Show {
    $outer_var = 'Kenobi'
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Basic Example' -Theme Dark
    $state:card_name = 'Hello, there!'

    # set the home page controls (just a simple paragraph)
    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Title 'Awesome Homepage' -ScriptBlock {
        $name = $state:card_name
        New-PodeWebCard -Name $name -Content @(
            New-PodeWebParagraph -Value "This is an example homepage, with some example text, including $($using:outer_var)"
            New-PodeWebParagraph -Value 'Using some example paragraphs'
        )
    }

    # add a page to search process (output as json in an appended textbox)
    Add-PodeWebPage -Name Processes -Icon 'chart-box-outline' -ScriptBlock {
        New-PodeWebForm -Name 'Search' -ShowReset -SubmitText 'Search' -ResetText 'Clear' -AsCard -ScriptBlock {
            $procs = @(Get-Process -Name $WebEvent.Data.Name -ErrorAction Ignore |
                    Select-Object Name, ID, WorkingSet, CPU)

            $procs |
                New-PodeWebTextbox -Name 'Output' -Multiline -Preformat -AsJson -Size ((6 * $procs.Length) + 2) |
                Out-PodeWebElement
        } -Content @(
            New-PodeWebTextbox -Name 'Name'
        )
    }
}
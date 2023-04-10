Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # endpoint
    Add-PodeEndpoint -Port 8090 -Protocol Http

    # login/auth
    Enable-PodeSessionMiddleware -Secret 'schwifty' -Duration (10 * 60) -Extend
    New-PodeAuthScheme -Form | Add-PodeAuth -Name Example -ScriptBlock {
        param($username, $password)

        if ($username -eq 'morty' -and $password -eq 'pickle') {
            return @{
                User = @{ ID ='M0R7Y302'; Name = 'Morty'; Type = 'Human' }
            }
        }

        return @{ Message = 'Invalid details supplied' }
    }

    # templates / login page
    Use-PodeWebTemplates -Title Test -Theme Dark
    Set-PodeWebLoginPage -Authentication Example

    # processes - table for results, and a form to search
    $table = New-PodeWebTable -Name 'Results' -Id 'tbl_process_results' -AsCard
    $form = New-PodeWebForm -Name 'Search' -AsCard -ScriptBlock {
        $processes = Get-Process -Name $WebEvent.Data.Name -ErrorAction Ignore | Select-Object Name, ID, WorkingSet, CPU
        $processes | Update-PodeWebTable -Id 'tbl_process_results'
        Show-PodeWebToast -Message "Found $($processes.Length) processes"
    } -Content @(
        New-PodeWebTextbox -Name 'Name'
    )

    Add-PodeWebPage -Name Processes -Icon 'chart-box-outline' -Layouts $form, $table

    # services
    Add-PodeWebPage -Name Services -Icon 'cogs'
}
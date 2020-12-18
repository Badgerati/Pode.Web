Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # endpoint
    Add-PodeEndpoint -Port 5001 -Protocol Http

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
    $table = New-PodeWebTable -Name 'Results' -Id 'tbl_process_results' -Filter
    $form = New-PodeWebForm -Name 'Search' -ScriptBlock {
        $processes = Get-Process -Name $InputData.Name -ErrorAction Ignore | Select-Object Name, ID, WorkingSet, CPU
        $processes | Out-PodeWebTable -Id 'tbl_process_results'
        Show-PodeWebToast -Message "Found $($processes.Length) processes"
    } -Elements @(
        New-PodeWebTextbox -Name 'Name'
    )

    Add-PodeWebPage -Name Processes -Icon Activity -Components $form, $table

    # services
    Add-PodeWebPage -Name Services -Icon Settings
}
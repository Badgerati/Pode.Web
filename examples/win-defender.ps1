Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer -Threads 2 {
    <#
        .SYNOPSIS
        Run a Pode.Web Server on port 11111 over http.

        .DESCRIPTION
        Check if the User has Administrative privilege.
        If not, show a Web Alert.
        Else, show Windows Defender properties.

        .NOTES
        This server is useful for those who wish
        enhance their overall cyber posture.
    #>
    Add-PodeEndpoint -Address localhost -Port 11111 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    Initialize-PodeWebTemplates -Title 'Windows Defender' -Theme Dark

    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Title 'Windows Defender' -ScriptBlock {
        $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $currentPrincipal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
        $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        # Show a warning when the server is not running as admin.
        if (! $isAdmin) {
            New-PodeWebAlert -Type Warning -Value 'You Must Be An Admin to view Defender'
            return
        }

        New-PodeWebTable -Name 'Defender Preferences' -AsCard -Paginate -PageSize 15 -Filter -SimpleSort -Compact -ScriptBlock {
            $preferences = (Get-MpPreference).PSObject.Properties

            foreach ($prop in $preferences) {
                [ordered]@{
                    Setting = "$($prop.Name)"
                    Value   = "$($prop.Value)"
                }
            }
        } -Columns @(
            Initialize-PodeWebTableColumn -Key 'Setting' -Width 30
            Initialize-PodeWebTableColumn -Key 'Value'
        )
    }
}
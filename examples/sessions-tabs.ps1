Import-Module Pode -MaximumVersion 2.99.99 -Force
# Import-Module ..\..\Pode\src\Pode.psm1 -Force
Import-Module ..\src\Pode.Web.psd1 -Force

Start-PodeServer -StatusPageExceptions Show {
    # add a simple endpoint
    Add-PodeEndpoint -Address * -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging


    # enable sessions and authentication
    Enable-PodeSessionMiddleware -Duration 600 -Extend -Scope Tab

    New-PodeAuthScheme -Form | Add-PodeAuth -Name Example -SuccessUseOrigin -ScriptBlock {
        param($username, $password)

        # here you'd check a real user storage, this is just for example
        if ($username -eq 'morty' -and $password -eq 'pickle') {
            return @{
                User = @{
                    ID   = 'M0R7Y302'
                    Name = 'Morty'
                    Type = 'Human'
                }
            }
        }

        return @{ Message = 'Invalid details supplied' }
    }


    # set the use of templates
    Use-PodeWebTemplates -Title 'Sessions' -Theme Dark

    # set login page
    Set-PodeWebLoginPage -Authentication Example -PassThru


    # set home page with session counter
    Add-PodeWebPage -Name 'Home' -Path '/' -NoTitle -HomePage -ScriptBlock {
        #lorem
        $session:Views++

        New-PodeWebCard -Name 'Counter' -Content @(
            New-PodeWebParagraph -Value "You have viewed this page $($session:Views) time(s)!"
        )
    }
}
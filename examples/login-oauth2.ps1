Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging -Levels Error

    # enable sessions and authentication
    Enable-PodeSessionMiddleware -Duration (10 * 60) -Extend

    # setup a mock oauth2 client
    $clientId = 'mock-ouath2-client-id'
    $clientSecret = 'mock-ouath2-client-secret'

    Add-PodeRoute -Method Get -Path '/mock/oauth2/authorise' -ScriptBlock {
        $code = 1337
        $state = $WebEvent.Query.state
        $url = "$($WebEvent.Query.redirect_uri)?code=$code&state=$state"
        Move-PodeResponseUrl -Url $url
    }

    Add-PodeRoute -Method Post -Path '/mock/oauth2/token' -ScriptBlock {
        Write-PodeJsonResponse -Value @{
            access_token  = 'mock-oauth2-access-token'
            refresh_token = 'mock-oauth-refresh-token'
        }
    }

    Add-PodeRoute -Method Post -Path '/mock/oauth2/userinfo' -ScriptBlock {
        Write-PodeJsonResponse -Value @{
            Username = 'Luffy'
            Name     = 'Monkey D. Luffy'
        }
    }

    $scheme = New-PodeAuthScheme `
        -OAuth2 `
        -ClientId $clientId `
        -ClientSecret $clientSecret `
        -AuthoriseUrl '/mock/oauth2/authorise' `
        -TokenUrl 'http://127.0.0.1:8090/mock/oauth2/token' `
        -UserUrl 'http://127.0.0.1:8090/mock/oauth2/userinfo'

    $scheme | Add-PodeAuth -Name 'MockOAuth2' -SuccessUseOrigin -ScriptBlock {
        param($user, $accessToken, $refreshToken)
        return @{ User = $user }
    }

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Login Example' -Theme Dark
    Set-PodeWebLoginPage -Authentication MockOAuth2

    # set the home page controls (just a simple paragraph)
    Add-PodeWebPage -Name 'Home' -Path '/' -HomePage -Title 'Awesome Homepage' -ScriptBlock {
        New-PodeWebCard -Name 'Welcome' -NoTitle -Content @(
            New-PodeWebParagraph -Value 'This is an example homepage, with some example text'
            New-PodeWebParagraph -Value 'Using some example paragraphs'
        )
    }

    # add a page to search process (output as json in an appended textbox)
    Add-PodeWebPage -Name Processes -Icon 'chart-box-outline' -ScriptBlock {
        New-PodeWebForm -Name 'Search' -AsCard -ScriptBlock {
            Get-Process -Name $WebEvent.Data.Name -ErrorAction Ignore |
                Select-Object Name, ID, WorkingSet, CPU |
                New-PodeWebTextbox -Name 'Output' -Multiline -Preformat -AsJson |
                Out-PodeWebElement
        } -Content @(
            New-PodeWebTextbox -Name 'Name'
        )
    }
}
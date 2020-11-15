function Set-PodeWebLoginPage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Authentication,

        [Parameter()]
        [string]
        $Icon,

        [Parameter()]
        [string]
        $Copyright
    )

    Set-PodeWebState -Name 'auth' -Value $Authentication

    if ([string]::IsNullOrWhiteSpace($Icon)) {
        $Icon = '/pode.web/images/icon.png'
    }

    $auth = Get-PodeAuth -Name $Authentication
    $auth.Failure.Url = '/login'
    $auth.Success.Url = '/'

    Add-PodeRoute -Method Get -Path '/login' -Authentication $Authentication -Login -ScriptBlock {
        Write-PodeWebViewResponse -Path 'login' -Data @{
            Icon = $using:Icon
            Copyright = $using:Copyright
        }
    }

    Add-PodeRoute -Method Post -Path '/login' -Authentication $Authentication -Login

    Add-PodeRoute -Method Post -Path '/logout' -Authentication $Authentication -Logout

    Remove-PodeRoute -Method Get -Path '/'
    Add-PodeRoute -Method Get -Path '/' -Authentication $Authentication -ScriptBlock {
        $authData = $WebEvent.Auth
        if (($null -eq $authData) -or ($authData.Count -eq 0)) {
            $authData = $WebEvent.Session.Data.Auth
        }

        Write-PodeWebViewResponse -Path 'index' -Data @{
            Name = 'Home'
            Username = $authData.User.Name
            Auth = @{
                Enabled = $true
                Authenticated = $authData.IsAuthenticated
            }
        }
    }
}

function Set-PodeWebHomePage
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable[]]
        $Components,

        [Parameter()]
        [string]
        $Title,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    $auth = $null
    if (!$NoAuthentication) {
        $auth = (Get-PodeWebState -Name 'auth')
    }

    if ([string]::IsNullOrWhiteSpace($Title)) {
        $Title = 'Home'
    }

    Remove-PodeRoute -Method Get -Path '/'

    Add-PodeRoute -Method Get -Path '/' -Authentication $auth -ScriptBlock {
        $authData = $WebEvent.Auth
        if (($null -eq $authData) -or ($authData.Count -eq 0)) {
            $authData = $WebEvent.Session.Data.Auth
        }

        Write-PodeWebViewResponse -Path 'index' -Data @{
            Name = 'Home'
            Title = $using:Title
            Username = $authData.User.Name
            Components = $using:Components
            Auth = @{
                Enabled = ![string]::IsNullOrWhiteSpace((Get-PodeWebState -Name 'auth'))
                Authenticated = $authData.IsAuthenticated
            }
        }
    }
}

function Add-PodeWebPage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Title,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Icon = 'file',

        [Parameter()]
        [hashtable[]]
        $Components,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    # test if page exists
    if (Test-PodeWebPage -Name $Name) {
        throw " Web page already exists: $($Name)"
    }

    Set-PodeWebState -Name 'pages' -Value  (@(Get-PodeWebState -Name 'pages') + @{ Name = $Name; Icon = $Icon})

    if ([string]::IsNullOrWhiteSpace($Title)) {
        $Title = $Name
    }

    $auth = $null
    if (!$NoAuthentication) {
        $auth = (Get-PodeWebState -Name 'auth')
    }

    Add-PodeRoute -Method Get -Path "/pages/$($Name)" -Authentication $auth -ScriptBlock {
        $authData = $WebEvent.Auth
        if (($null -eq $authData) -or ($authData.Count -eq 0)) {
            $authData = $WebEvent.Session.Data.Auth
        }

        Write-PodeWebViewResponse -Path 'index' -Data @{
            Name = $using:Name
            Title = $using:Title
            Username = $authData.User.Name
            Components = $using:Components
            Auth = @{
                Enabled = ![string]::IsNullOrWhiteSpace((Get-PodeWebState -Name 'auth'))
                Authenticated = $authData.IsAuthenticated
            }
        }
    }
}
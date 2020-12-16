function Get-PodeWebTemplatePath
{
    $path = Split-Path -Parent -Path ((Get-Module -Name 'Pode.Web').Path)
    return (Join-Path $path 'Templates')
}

function Get-PodeWebAuthData
{
    $authData = $WebEvent.Auth
    if (($null -eq $authData) -or ($authData.Count -eq 0)) {
        $authData = $WebEvent.Session.Data.Auth
    }

    return $authData
}

function Get-PodeWebAuthUsername
{
    param(
        [Parameter()]
        $AuthData
    )

    # nothing if no auth data
    if (($null -eq $AuthData) -or ($null -eq $AuthData.User)) {
        return [string]::Empty
    }

    $user = $AuthData.User

    # name
    if (![string]::IsNullOrWhiteSpace($user.Name)) {
        return $user.Name
    }

    # full name
    if (![string]::IsNullOrWhiteSpace($user.FullName)) {
        return $user.Name
    }

    # username
    if (![string]::IsNullOrWhiteSpace($user.Username)) {
        return $user.Username
    }

    # email - spli on @ though
    if (![string]::IsNullOrWhiteSpace($user.Email)) {
        return ($user.Email -split '@')[0]
    }

    # nothing
    return [string]::Empty
}

function Write-PodeWebViewResponse
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        [Parameter()]
        [hashtable]
        $Data = @{}
    )

    Write-PodeViewResponse -Path "$($Path).pode" -Data $Data -Folder 'pode.web.views' -FlashMessages
}

function Use-PodeWebPartialView
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        [Parameter()]
        [hashtable]
        $Data = @{}
    )

    Use-PodePartialView -Path "$($Path).pode" -Data $Data -Folder 'pode.web.views'
}

function Set-PodeWebState
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [object]
        $Value
    )

    Set-PodeState -Name "pode.web.$($Name)" -Value $Value -Scope 'pode.web' | Out-Null
}

function Get-PodeWebState
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    return (Get-PodeState -Name "pode.web.$($Name)")
}

function Get-PodeWebRandomName
{
    param(
        [Parameter()]
        [int]
        $Length = 5
    )

    $value = (65..90) | Get-Random -Count $Length | ForEach-Object { [char]$_ }
    return [String]::Concat($value)
}

function Protect-PodeWebName
{
    param(
        [Parameter()]
        [string]
        $Name
    )

    return ($Name -ireplace '[^a-z0-9 ]', '').Trim()
}

function Test-PodeWebPage
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    return (Get-PodeWebState -Name 'pages' | Where-Object { $_.Name -ieq $Name } | Measure-Object).Count -ne 0
}

function Get-PodeWebElementId
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Tag,

        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [string]
        $Name
    )

    if (![string]::IsNullOrWhiteSpace($Id)) {
        return $Id
    }

    $_id = [string]::Empty
    if (![string]::IsNullOrWhiteSpace($ComponentData.ID)) {
        $_id = "$($ComponentData.ID)_"
    }

    $_id += "$($Tag)"
    if (![string]::IsNullOrWhiteSpace($Name)) {
        $_id += "_$($Name)"
    }

    if ([string]::IsNullOrWhiteSpace($ComponentData.ID)) {
        $_id += "_$(Get-PodeWebRandomName)"
    }

    return ($_id -replace '\s+', '_').ToLowerInvariant()
}

function Convert-PodeWebAlertTypeToClass
{
    param(
        [Parameter()]
        [string]
        $Type
    )

    switch ($Type.ToLowerInvariant()) {
        'error' {
            return 'danger'
        }

        'warning' {
            return 'warning'
        }

        'tip' {
            return 'success'
        }

        'note' {
            return 'secondary'
        }

        'info' {
            return 'info'
        }

        'important' {
            return 'primary'
        }

        default {
            return 'primary'
        }
    }
}

function Convert-PodeWebAlertTypeToIcon
{
    param(
        [Parameter()]
        [string]
        $Type
    )

    switch ($Type.ToLowerInvariant()) {
        'error' {
            return 'alert-circle'
        }

        'warning' {
            return 'alert-triangle'
        }

        'tip' {
            return 'thumbs-up'
        }

        'note' {
            return 'book-open'
        }

        'info' {
            return 'info'
        }

        'important' {
            return 'paperclip'
        }

        default {
            return 'paperclip'
        }
    }
}

function Convert-PodeWebColourToClass
{
    param(
        [Parameter()]
        [string]
        $Colour
    )

    switch ($Colour.ToLowerInvariant()) {
        'blue' {
            return 'primary'
        }

        'green' {
            return 'success'
        }

        'grey' {
            return 'secondary'
        }

        'red' {
            return 'danger'
        }

        'yellow' {
            return 'warning'
        }

        'cyan' {
            return 'info'
        }

        'light' {
            return 'light'
        }

        'dark' {
            return 'dark'
        }

        default {
            return 'primary'
        }
    }
}
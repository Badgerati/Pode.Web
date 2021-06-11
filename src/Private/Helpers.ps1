function Get-PodeWebTemplatePath
{
    $path = Split-Path -Parent -Path ((Get-Module -Name 'Pode.Web').Path)
    return (Join-PodeWebPath $path 'Templates')
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

    # check username prop
    $prop = (Get-PodeWebState -Name 'auth-props').Username
    if (![string]::IsNullOrWhiteSpace($prop) -and ![string]::IsNullOrWhiteSpace($user.$prop)) {
        return $user.$prop
    }

    # name
    if (![string]::IsNullOrWhiteSpace($user.Name)) {
        return $user.Name
    }

    # full name
    if (![string]::IsNullOrWhiteSpace($user.FullName)) {
        return $user.FullName
    }

    # username
    if (![string]::IsNullOrWhiteSpace($user.Username)) {
        return $user.Username
    }

    # email - split on @ though
    if (![string]::IsNullOrWhiteSpace($user.Email)) {
        return ($user.Email -split '@')[0]
    }

    # nothing
    return [string]::Empty
}

function Get-PodeWebAuthGroups
{
    param(
        [Parameter()]
        $AuthData
    )

    # nothing if no auth data
    if (($null -eq $AuthData) -or ($null -eq $AuthData.User)) {
        return @()
    }

    $user = $AuthData.User

    # check group prop
    $prop = (Get-PodeWebState -Name 'auth-props').Group
    if (![string]::IsNullOrWhiteSpace($prop) -and !(Test-PodeWebArrayEmpty -Array $user.$prop)) {
        return @($user.$prop)
    }

    # groups
    if (!(Test-PodeWebArrayEmpty -Array $user.Groups)) {
        return @($user.Groups)
    }

    # roles
    if (!(Test-PodeWebArrayEmpty -Array $user.Roles)) {
        return @($user.Roles)
    }

    # scopes
    if (!(Test-PodeWebArrayEmpty -Array $user.Scopes)) {
        return @($user.Scopes)
    }

    # nothing
    return @()
}

function Get-PodeWebAuthAvatarUrl
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

    # nothing if no property set
    $prop = (Get-PodeWebState -Name 'auth-props').Avatar
    if (![string]::IsNullOrWhiteSpace($prop) -and ![string]::IsNullOrWhiteSpace($user.$prop)) {
        return $user.$prop
    }

    # avatar url
    if (![string]::IsNullOrWhiteSpace($user.AvatarUrl)) {
        return $user.AvatarUrl
    }

    return [string]::Empty
}

function Get-PodeWebAuthTheme
{
    param(
        [Parameter()]
        $AuthData
    )

    # nothing if no auth data
    if (($null -eq $AuthData) -or ($null -eq $AuthData.User)) {
        return $null
    }

    $user = $AuthData.User

    # nothing if no property set
    $prop = (Get-PodeWebState -Name 'auth-props').Theme
    if (![string]::IsNullOrWhiteSpace($prop) -and ![string]::IsNullOrWhiteSpace($user.$prop)) {
        return $user.$prop
    }

    # theme
    if (![string]::IsNullOrWhiteSpace($user.Theme)) {
        return $user.Theme
    }

    return [string]::Empty
}

function Get-PodeWebInbuiltThemes
{
    return @('Auto', 'Light', 'Dark', 'Terminal', 'Custom')
}

function Test-PodeWebThemeCustom
{
    param(
        [Parameter()]
        [string]
        $Name
    )

    $inbuildThemes = Get-PodeWebInbuiltThemes
    if ($Name -iin $inbuildThemes) {
        return $false
    }

    $customThemes = Get-PodeWebState -Name 'custom-themes'
    if ($customThemes.Themes.Keys -icontains $Name) {
        return $true
    }

    return $false
}

function Test-PodeWebArrayEmpty
{
    param(
        [Parameter()]
        $Array
    )

    return (($null -eq $Array) -or (@($Array).Length -eq 0))
}

function Test-PodeWebPageAccess
{
    param(
        [Parameter()]
        $PageAccess,

        [Parameter()]
        $Auth
    )

    $hasGroups = (!(Test-PodeWebArrayEmpty -Array $PageAccess.Groups))
    $hasUsers = (!(Test-PodeWebArrayEmpty -Array $PageAccess.Users))

    # if page has no access restriction, just return
    if (!$hasGroups -and !$hasUsers) {
        return $true
    }

    # check groups
    if ($hasGroups -and !(Test-PodeWebArrayEmpty -Array $Auth.Groups)) {
        foreach ($group in $PageAccess.Groups) {
            if ($Auth.Groups -icontains $group) {
                return $true
            }
        }
    }

    # check users
    if ($hasUsers -and ![string]::IsNullOrWhiteSpace($Auth.Username)) {
        if ($PageAccess.Users -icontains $Auth.Username) {
            return $true
        }
    }

    return $false
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

function Get-PodeWebCookie
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    return (Get-PodeCookie -Name "pode.web.$($Name)")
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

    return ($Name -ireplace '[^a-z0-9_]', '').Trim()
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

function Test-PodeWebRoute
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )

    $route = (Get-PodeRoute -Method Post -Path $Path)

    if ([string]::IsNullOrWhiteSpace($PageData.Name) -and [string]::IsNullOrWhiteSpace($ElementData.Name) -and ($null -ne $route)) {
        throw "An element with ID '$(Split-Path -Path $Path -Leaf)' already exists"
    }

    return ($null -ne $route)
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
        $Name,

        [switch]
        $RandomToken,

        [switch]
        $NameAsToken
    )

    if (![string]::IsNullOrWhiteSpace($Id)) {
        return $Id
    }

    # prepend the parent element's ID
    $_id = [string]::Empty
    if (![string]::IsNullOrWhiteSpace($ElementData.ID)) {
        $_id = "$($ElementData.ID)_"
    }

    # start with element tag
    $_id += "$($Tag)"

    # add page name if we have one
    if (![string]::IsNullOrWhiteSpace($PageData.Name)) {
        $_id += "_$($PageData.Name)"
    }

    # add name if we have one
    if (![string]::IsNullOrWhiteSpace($Name)) {
        $_id += "_$($Name)"
    }

    # add random token - if forced, or if no page
    if ($RandomToken -or ($NameAsToken -and [string]::IsNullOrWhiteSpace($Name))) {
        $_id += "_$(Get-PodeWebRandomName)"
    }

    $_id = Protect-PodeWebName -Name $_id
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

        'success' {
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
            return 'alert'
        }

        'tip' {
            return 'thumb-up'
        }

        'success' {
            return 'check-circle'
        }

        'note' {
            return 'book-open'
        }

        'info' {
            return 'information'
        }

        'important' {
            return 'bell'
        }

        default {
            return 'bell'
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

function Test-PodeWebContent
{
    param(
        [Parameter()]
        [hashtable[]]
        $Content,

        [Parameter()]
        [string[]]
        $ComponentType,

        [Parameter()]
        [string[]]
        $ElementType,

        [Parameter()]
        [string[]]
        $LayoutType
    )

    # if no content, then it's true
    if (Test-PodeWebArrayEmpty -Array $Content) {
        return $true
    }

    # ensure the content ComponentTypes are correct
    if (!(Test-PodeWebArrayEmpty -Array $ComponentType)) {
        foreach ($item in $Content) {
            if ($item.ComponentType -inotin $ComponentType) {
                return $false
            }
        }
    }

    # ensure the content ElementTypes are correct
    if (!(Test-PodeWebArrayEmpty -Array $ElementType)) {
        foreach ($item in $Content) {
            if ($item.ElementType -inotin $ElementType) {
                return $false
            }
        }
    }

    # ensure the content LayoutTypes are correct
    if (!(Test-PodeWebArrayEmpty -Array $LayoutType)) {
        foreach ($item in $Content) {
            if ($item.LayoutType -inotin $LayoutType) {
                return $false
            }
        }
    }

    return $true
}

function Remove-PodeWebRoute
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Method,

        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        [Parameter()]
        [string[]]
        $EndpointName
    )

    if (Test-PodeIsEmpty $EndpointName) {
        Remove-PodeRoute -Method $Method -Path $Path
    }
    else {
        foreach ($endpoint in $EndpointName) {
            Remove-PodeRoute -Method $Method -Path $Path -EndpointName $endpoint
        }
    }
}

function Test-PodeWebOutputWrapped
{
    param(
        [Parameter()]
        $Output
    )

    if ($null -eq $Output) {
        return $false
    }

    if ($Output -is [array]) {
        $Output = $Output[0]
    }

    return (($Output -is [hashtable]) -and ($Output.Operation -ieq 'Output') -and ![string]::IsNullOrWhiteSpace($Output.ElementType))
}
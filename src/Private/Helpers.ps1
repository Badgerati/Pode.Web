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
        return (Add-PodeWebAppPath -Url $user.$prop)
    }

    # avatar url
    if (![string]::IsNullOrWhiteSpace($user.AvatarUrl)) {
        return (Add-PodeWebAppPath -Url $user.AvatarUrl)
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

    $customThemes = Get-PodeWebState -Name 'custom-themes'
    return ($customThemes.Themes.Keys -icontains $Name)
}

function Test-PodeWebThemeInbuilt
{
    param(
        [Parameter()]
        [string]
        $Name
    )

    $inbuildThemes = Get-PodeWebInbuiltThemes
    return ($Name -iin $inbuildThemes)
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

    $Data['AppPath'] = (Get-PodeWebState -Name 'app-path')
    Write-PodeViewResponse -Path "$($Path).pode" -Data $Data -Folder 'pode.web.views' -FlashMessages
}

function Add-PodeWebAppPath
{
    param(
        [Parameter()]
        [string]
        $Url
    )

    if (![string]::IsNullOrWhiteSpace($Url) -and $Url.StartsWith('/')) {
        $appPath = Get-PodeWebState -Name 'app-path'
        $Url = "$($appPath)$($Url)"
    }

    return $Url
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

function Protect-PodeWebValue
{
    param(
        [Parameter()]
        [string]
        $Value,

        [Parameter()]
        [string]
        $Default,

        [switch]
        $Encode
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        if ($Encode) {
            return [System.Net.WebUtility]::HtmlEncode($Default)
        }
        else {
            return $Default
        }
    }

    if ($Encode) {
        return [System.Net.WebUtility]::HtmlEncode($Value)
    }
    else {
        return $Value
    }
}

function Protect-PodeWebValues
{
    param(
        [Parameter()]
        [string[]]
        $Value,

        [Parameter()]
        [string[]]
        $Default,

        [switch]
        $EqualCount,

        [switch]
        $Encode
    )

    if (($null -eq $Value) -or ($Value.Length -eq 0)) {
        if ($Encode -and ($null -ne $Default) -and ($Default.Length -gt 0)) {
            return @(foreach ($v in $Default) {
                [System.Net.WebUtility]::HtmlEncode($v)
            })
        }
        else {
            return $Default
        }
    }

    if ($EqualCount -and ($Value.Length -ne $Default.Length)) {
        throw "Expected an equal number of values in both arrays"
    }

    if ($Encode) {
        return @(foreach ($v in $Value) {
            [System.Net.WebUtility]::HtmlEncode($v)
        })
    }
    else {
        return $Value
    }
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

    # add page name and group if we have one
    if (![string]::IsNullOrWhiteSpace($PageData.Name)) {
        $_id += "_$($PageData.Name)"
    }

    if (![string]::IsNullOrWhiteSpace($PageData.Group)) {
        $_id += "_$($PageData.Group)"
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
        $ObjectType
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

    # ensure the content elements are correct
    if (!(Test-PodeWebArrayEmpty -Array $ObjectType)) {
        foreach ($item in $Content) {
            if ($item.ObjectType -inotin $ObjectType) {
                return $false
            }
        }
    }

    # ensure the content elements are correct
    if (!(Test-PodeWebArrayEmpty -Array $ObjectType)) {
        foreach ($item in $Content) {
            if ($item.ObjectType -inotin $ObjectType) {
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

    return (($Output -is [hashtable]) -and ![string]::IsNullOrWhiteSpace($Output.Operation) -and ![string]::IsNullOrWhiteSpace($Output.ObjectType))
}

function Get-PodeWebFirstPublicPage
{
    $pages = Get-PodeWebState -Name 'pages'
    if (($null -eq $pages) -or ($pages.Count -eq 0)) {
        return $null
    }

    foreach ($page in ($pages.Values | Sort-Object -Property { $_.Group }, { $_.Name })) {
        if ((Test-PodeWebArrayEmpty -Array $page.Access.Groups) -and (Test-PodeWebArrayEmpty -Array $page.Access.Users)) {
            return $page
        }
    }

    return $null
}

function Get-PodeWebPagePath
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(ParameterSetName='Name')]
        [string]
        $Group,

        [Parameter(ParameterSetName='Page')]
        [hashtable]
        $Page,

        [switch]
        $NoAppPath
    )

    $path = [string]::Empty

    if ($null -ne $Page) {
        $Name = $Page.Name
        $Group = $Page.Group
    }

    if (![string]::IsNullOrWhiteSpace($Group)) {
        $path += "/groups/$($Group)"
    }

    $path += "/pages/$($Name)"

    if (!$NoAppPath) {
        $path = (Add-PodeWebAppPath -Url $path)
    }

    return $path
}

function ConvertTo-PodeWebEvents
{
    param(
        [Parameter()]
        [string[]]
        $Events
    )

    $js_events = [string]::Empty

    if (($null -eq $Events) -or ($Events.Length -eq 0)) {
        return $js_events
    }

    foreach ($evt in $Events) {
        $js_events += " on$($evt)=`"invokeEvent('$($evt)', this);`""
    }

    return $js_events
}

function ConvertTo-PodeWebStyles
{
    param(
        [Parameter()]
        [hashtable]
        $Style
    )

    $styles = [string]::Empty

    if (($null -eq $Style) -or ($Style.Count -eq 0)) {
        return $styles
    }

    foreach ($key in $Style.Keys) {
        $styles += " $($key.ToLowerInvariant()): $($Style[$key].ToLowerInvariant()) !important;"
    }

    return $styles
}

function ConvertTo-PodeWebSize
{
    param(
        [Parameter()]
        [string]
        $Value,

        [Parameter()]
        [string]
        $Default = 0,

        [Parameter(Mandatory=$true)]
        [ValidateSet('px', '%', 'em')]
        [string]
        $Type
    )

    $pattern = '^\-?\d+(\.\d+){0,1}$'
    $defIsNumber = ($Default -match $pattern)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        if ($defIsNumber) {
            return "$($Default)$($Type)"
        }
        else {
            return $Default
        }
    }

    if ($Value -match $pattern) {
        $_val = [double]$Value
        if ($_val -le 0) {
            if ($defIsNumber) {
                $Value = $Default
            }
            else {
                return $Default
            }
        }
        elseif (($Type -eq '%') -and ($_val -gt 100)) {
            $Value = 100
        }

        return "$($Value)$($Type)"
    }

    return $Value
}
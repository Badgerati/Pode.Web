function Get-PodeWebTemplatePath {
    $path = Split-Path -Parent -Path ((Get-Module -Name 'Pode.Web' | Sort-Object -Property Version -Descending | Select-Object -First 1).Path)
    return (Join-PodeWebPath $path 'Templates')
}

function Get-PodeWebAuthData {
    $authData = $WebEvent.Auth
    if (($null -eq $authData) -or ($authData.Count -eq 0)) {
        $authData = $WebEvent.Session.Data.Auth
    }

    return $authData
}

function Get-PodeWebAuthUsername {
    param(
        [Parameter()]
        $User
    )

    # nothing if no user
    if ($null -eq $User) {
        return [string]::Empty
    }

    # check username prop
    $prop = (Get-PodeWebState -Name 'auth-props').Username
    if (![string]::IsNullOrEmpty($prop) -and ![string]::IsNullOrEmpty($User.$prop)) {
        return $User.$prop
    }

    # name
    if (![string]::IsNullOrEmpty($User.Name)) {
        return $User.Name
    }

    # full name
    if (![string]::IsNullOrEmpty($User.FullName)) {
        return $User.FullName
    }

    # username
    if (![string]::IsNullOrEmpty($User.Username)) {
        return $User.Username
    }

    # email - split on @ though
    if (![string]::IsNullOrEmpty($User.Email)) {
        return ($User.Email -split '@')[0]
    }

    # nothing
    return [string]::Empty
}

function Get-PodeWebAuthGroups {
    param(
        [Parameter()]
        $User
    )

    # nothing if no auth data
    if ($null -eq $User) {
        return @()
    }

    # check group prop
    $prop = (Get-PodeWebState -Name 'auth-props').Group
    if (![string]::IsNullOrEmpty($prop) -and !(Test-PodeWebArrayEmpty -Array $User.$prop)) {
        return @($User.$prop)
    }

    # groups
    if (!(Test-PodeWebArrayEmpty -Array $User.Groups)) {
        return @($User.Groups)
    }

    # roles
    if (!(Test-PodeWebArrayEmpty -Array $User.Roles)) {
        return @($User.Roles)
    }

    # scopes
    if (!(Test-PodeWebArrayEmpty -Array $User.Scopes)) {
        return @($User.Scopes)
    }

    # nothing
    return @()
}

function Get-PodeWebAuthAvatarUrl {
    param(
        [Parameter()]
        $User
    )

    # nothing if no auth data
    if ($null -eq $User) {
        return [string]::Empty
    }

    # nothing if no property set
    $prop = (Get-PodeWebState -Name 'auth-props').Avatar
    if (![string]::IsNullOrEmpty($prop) -and ![string]::IsNullOrEmpty($User.$prop)) {
        return (Add-PodeWebAppPath -Url $User.$prop)
    }

    # avatar url
    if (![string]::IsNullOrEmpty($User.AvatarUrl)) {
        return (Add-PodeWebAppPath -Url $User.AvatarUrl)
    }

    return [string]::Empty
}

function Get-PodeWebAuthTheme {
    param(
        [Parameter()]
        $User
    )

    # nothing if no auth data
    if ($null -eq $User) {
        return $null
    }

    # nothing if no property set
    $prop = (Get-PodeWebState -Name 'auth-props').Theme
    if (![string]::IsNullOrEmpty($prop) -and ![string]::IsNullOrEmpty($User.$prop)) {
        return $User.$prop
    }

    # theme
    if (![string]::IsNullOrEmpty($User.Theme)) {
        return $User.Theme
    }

    return [string]::Empty
}

function Get-PodeWebInbuiltThemes {
    return @('Auto', 'Light', 'Dark', 'Terminal', 'Custom')
}

function Test-PodeWebThemeCustom {
    param(
        [Parameter()]
        [string]
        $Name
    )

    $customThemes = Get-PodeWebState -Name 'custom-themes'
    return ($customThemes.Themes.Keys -icontains $Name)
}

function Test-PodeWebThemeInbuilt {
    param(
        [Parameter()]
        [string]
        $Name
    )

    $inbuildThemes = Get-PodeWebInbuiltThemes
    return ($Name -iin $inbuildThemes)
}

function Test-PodeWebArrayEmpty {
    param(
        [Parameter()]
        $Array
    )

    return (($null -eq $Array) -or (@($Array).Length -eq 0))
}

function Test-PodeWebPageAccess {
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

    # if no auth object, just return
    if ($null -eq $Auth) {
        return $false
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

function Write-PodeWebViewResponse {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter()]
        [hashtable]
        $Data = @{}
    )

    $Data['AppPath'] = (Get-PodeWebState -Name 'app-path')
    Write-PodeViewResponse -Path "$($Path).pode" -Data $Data -Folder 'pode.web.views' -FlashMessages
}

function Add-PodeWebAppPath {
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

function Set-PodeWebSystemUrlDefaults {
    Set-PodeWebState -Name 'system-urls' -Value @{
        Home     = @{
            Path     = '/'
            Url      = (Add-PodeWebAppPath -Url '/')
            IsCustom = $false
        }
        Register = @{
            Path = '/register'
            Url  = (Add-PodeWebAppPath -Url '/register')
        }
        Login    = @{
            Path = '/login'
            Url  = (Add-PodeWebAppPath -Url '/login')
        }
        Logout   = @{
            Path = '/logout'
            Url  = (Add-PodeWebAppPath -Url '/logout')
        }
    }
}

function Use-PodeWebPartialView {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter()]
        [hashtable]
        $Data = @{}
    )

    Use-PodePartialView -Path "$($Path).pode" -Data $Data -Folder 'pode.web.views'
}

function Set-PodeWebState {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        [object]
        $Value
    )

    Set-PodeState -Name "pode.web.$($Name)" -Value $Value -Scope 'pode.web' | Out-Null
}

function Get-PodeWebState {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name
    )

    return (Get-PodeState -Name "pode.web.$($Name)")
}

function Get-PodeWebCookie {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name
    )

    return (Get-PodeCookie -Name "pode.web.$($Name)")
}

function Get-PodeWebRandomName {
    param(
        [Parameter()]
        [int]
        $Length = 5
    )

    if ($PSVersionTable.PSVersion.Major -eq 5) {
        return [string]::Concat(@(foreach ($i in 1..$Length) {
                    [char](Get-Random -Minimum 65 -Maximum 90)
                }))
    }
    else {
        $r = [System.Random]::new()
        return [string]::Concat(@(foreach ($i in 1..$Length) {
                    [char]$r.Next(65, 90)
                }))
    }
}

function Protect-PodeWebName {
    param(
        [Parameter()]
        [string]
        $Name
    )

    return ($Name -ireplace '[^a-z0-9_]', '').Trim()
}

function Protect-PodeWebSpecialCharacters {
    param(
        [Parameter()]
        [string]
        $Value
    )

    return ($Value -replace "[\s!`"#\$%&'\(\)*+,\./:;<=>?@\[\\\]^``{\|}~]", '_')
}

function Protect-PodeWebValue {
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

function Protect-PodeWebValues {
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
        if (($null -eq $Default) -or ($Default.Length -eq 0)) {
            return
        }

        if ($Encode) {
            return @(foreach ($v in $Default) {
                    [System.Net.WebUtility]::HtmlEncode($v)
                })
        }

        return $Default
    }

    if ($EqualCount -and ($Value.Length -ne $Default.Length)) {
        throw 'Expected an equal number of values in both arrays'
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

function Test-PodeWebRoute {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    $route = (Get-PodeRoute -Method Post -Path $Path)

    if ([string]::IsNullOrWhiteSpace($PageData.Name) -and [string]::IsNullOrWhiteSpace($ElementData.Name) -and ($null -ne $route)) {
        throw "An element with ID '$(Split-Path -Path $Path -Leaf)' already exists"
    }

    return ($null -ne $route)
}

function Register-PodeWebPage {
    param(
        [Parameter(Mandatory)]
        [hashtable]
        $Metadata
    )

    # check home page
    if ($Metadata.IsHomePage) {
        $sysUrls = Get-PodeWebState -Name 'system-urls'
        if ($sysUrls.Home.IsCustom) {
            throw "A home page has already been defined at '$($sysUrls.Home.Path)'"
        }

        # update auth success url to home page
        if (![string]::IsNullOrEmpty($Metadata.Authentication)) {
            $auth = Get-PodeAuth -Name $Metadata.Authentication
            if ([string]::IsNullOrWhiteSpace($auth.Success.Url) -or ($auth.Success.Url -ieq $sysUrls.Home.Url)) {
                $auth.Success.Url = $Metadata.Url
            }
        }

        $sysUrls.Home = @{
            Path     = $Metadata.Path
            Url      = $Metadata.Url
            IsCustom = $true
        }
    }

    # register page
    $pages = Get-PodeWebState -Name 'pages'
    $pages[$Metadata.ID] = $Metadata

    # register page to group
    $group = (Get-PodeWebState -Name 'groups')[$Metadata.Group]

    if (!$group.Pages.ContainsKey($Metadata.Index)) {
        $group.Pages.Add($Metadata.Index, @())
    }

    $group.Pages[$Metadata.Index] += $Metadata.ID
}

function Get-PodeWebPageId {
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Group,

        [switch]
        $System
    )

    if (![string]::IsNullOrWhiteSpace($Id)) {
        return $Id
    }

    # prep id
    $_id = [string]::Empty

    # internal?
    if ($System) {
        $_id += 'system_'
    }

    # add group
    if (![string]::IsNullOrWhiteSpace($Group)) {
        $_id += "group_$($Group)_"
    }

    # add page
    $_id += "page_$($Name)"

    # protect id, and return
    $_id = Protect-PodeWebName -Name $_id
    return ($_id -replace '\s+', '_').ToLowerInvariant()
}

function Get-PodeWebElementId {
    param(
        [Parameter(Mandatory = $true)]
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

    # prepend the parent element's ID
    $_id = [string]::Empty
    if (![string]::IsNullOrWhiteSpace($ElementData.ID)) {
        $_id = "$($ElementData.ID)_"
    }
    elseif (![string]::IsNullOrWhiteSpace($ElementData.Name)) {
        $_id = "$($ElementData.Name)_"
    }

    # start with element tag
    $_id += "$($Tag)"

    # add page name and group if we have one
    if (![string]::IsNullOrWhiteSpace($PageData.ID)) {
        $_id += "_$($PageData.ID)"
    }

    # add name if we have one, or a random name
    if (![string]::IsNullOrWhiteSpace($Name)) {
        $_id += "_$($Name)"
    }
    else {
        $_id += "_$(Get-PodeWebRandomName)"
    }

    $_id = Protect-PodeWebName -Name $_id
    return ($_id -replace '\s+', '_').ToLowerInvariant()
}

function Convert-PodeWebAlertTypeToClass {
    param(
        [Parameter()]
        [string]
        $Type
    )

    $map = @{
        error     = 'danger'
        warning   = 'warning'
        tip       = 'success'
        success   = 'success'
        note      = 'secondary'
        info      = 'info'
        important = 'primary'
    }

    if ($map.ContainsKey($Type)) {
        return $map[$Type]
    }

    return 'primary'
}

function Convert-PodeWebAlertTypeToIcon {
    param(
        [Parameter()]
        [string]
        $Type
    )

    $map = @{
        error     = 'alert-circle'
        warning   = 'alert'
        tip       = 'thumb-up'
        success   = 'check-circle'
        note      = 'book-open'
        info      = 'information'
        important = 'bell'
    }

    if ($map.ContainsKey($Type)) {
        return $map[$Type]
    }

    return 'bell'
}

function Convert-PodeWebColourToClass {
    param(
        [Parameter()]
        [string]
        $Colour
    )

    $map = @{
        blue   = 'primary'
        green  = 'success'
        grey   = 'secondary'
        red    = 'danger'
        yellow = 'warning'
        cyan   = 'info'
        light  = 'light'
        dark   = 'dark'
    }

    if ($map.ContainsKey($Colour)) {
        return $map[$Colour]
    }

    return 'primary'
}

function Convert-PodeWebButtonSizeToClass {
    param(
        [Parameter()]
        [string]
        $Size,

        [switch]
        $FullWidth,

        [switch]
        $Group
    )

    $css = (@{
            small = 'btn-sm'
            large = 'btn-lg'
        })[$Size]

    if ($Group) {
        $css = $css -replace 'btn-', 'btn-group-'
    }

    if ($FullWidth) {
        $css += ' btn-block'
    }

    return $css
}

function Test-PodeWebContent {
    param(
        [Parameter()]
        [hashtable[]]
        $Content,

        [Parameter()]
        [ValidateSet('Element', 'Layout', 'Navigation', 'Page', 'Group')]
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
            if (($item.ComponentType -inotin $ComponentType) -and ($item.Reference.ComponentType -inotin $ComponentType)) {
                return $false
            }
        }
    }

    # ensure the content elements are correct
    if (!(Test-PodeWebArrayEmpty -Array $ObjectType)) {
        foreach ($item in $Content) {
            if (($item.ObjectType -inotin $ObjectType) -and ($item.Reference.ObjectType -inotin $ObjectType)) {
                return $false
            }
        }
    }

    return $true
}

function Remove-PodeWebRoute {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Method,

        [Parameter(Mandatory = $true)]
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

function Test-PodeWebOutputWrapped {
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

function Split-PodeWebDynamicOutput {
    param(
        [Parameter()]
        [object[]]
        $Output
    )

    if (($null -eq $Output) -or ($Output.Length -eq 0)) {
        return $null, $null
    }

    for ($i = 0; $i -lt $Output.Length; $i++) {
        if (!(Test-PodeWebOutputWrapped -Output $Output[$i])) {
            break
        }
    }

    $wrapped = @()
    if ($i -gt 0) {
        $wrapped = $Output[0..($i - 1)]

        if ($i -lt $Output.Length) {
            $Output = $Output[$i..($Output.Length - 1)]
        }
        else {
            $Output = @()
        }
    }

    return $wrapped, $Output
}

function Join-PodeWebDynamicOutput {
    param(
        [Parameter()]
        [object[]]
        $Wrapped,

        [Parameter()]
        [object[]]
        $Output
    )

    if (($null -eq $Wrapped) -or ($Wrapped.Length -eq 0)) {
        return $Output
    }

    if (($null -eq $Output) -or ($Output.Length -eq 0)) {
        return $Wrapped
    }

    return $Wrapped + $Output
}

function Get-PodeWebFirstPublicPage {
    $pages = Get-PodeWebState -Name 'pages'
    if (($null -eq $pages) -or ($pages.Count -eq 0)) {
        return $null
    }

    foreach ($page in ($pages.Values | Sort-Object -Property { $_.Group }, { $_.Name })) {
        if ($page.IsSystem) {
            continue
        }

        if ((Test-PodeWebArrayEmpty -Array $page.Access.Groups) -and (Test-PodeWebArrayEmpty -Array $page.Access.Users)) {
            return $page
        }
    }

    return $null
}

function Get-PodeWebPagePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Group,

        [Parameter()]
        [string]
        $Path = [string]::Empty,

        [switch]
        $NoAppPath
    )

    # inbuilt page route path if custom not supplied
    if ([string]::IsNullOrEmpty($Path)) {
        $Name = Protect-PodeWebSpecialCharacters -Value $Name
        $Group = Protect-PodeWebSpecialCharacters -Value $Group

        if (![string]::IsNullOrEmpty($Group)) {
            $Path += "/groups/$($Group)"
        }

        $Path += "/pages/$($Name)"
    }

    # check forward slash
    if (!$Path.StartsWith('/')) {
        $Path = "/$($Path)"
    }

    # add app path from IIS
    if (!$NoAppPath) {
        $Path = (Add-PodeWebAppPath -Url $Path)
    }

    return $Path
}

function ConvertTo-PodeWebEvents {
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

function Protect-PodeWebRange {
    param(
        [Parameter()]
        [string]
        $Value,

        [Parameter(Mandatory = $true)]
        [int]
        $Min,

        [Parameter(Mandatory = $true)]
        [int]
        $Max
    )

    # null for no value
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $pattern = Get-PodeWebNumberRegex

    # if it's a percentage, calculate value
    if ($Value.EndsWith('%')) {
        $_val = [double]$Value.TrimEnd('%')
        $Value = $Max * $_val * 0.01
    }

    # if value is number, check range
    if ($Value -match $pattern) {
        $_val = [int]$Value

        if ($_val -lt $Min) {
            return $Min
        }

        if ($_val -gt $Max) {
            return $Max
        }

        return $_val
    }

    # invalid value
    throw "Invalid value supplied for range: $($Value). Expected a value between $($Min)-$($Max), or a percentage."
}

function ConvertTo-PodeWebSize {
    param(
        [Parameter()]
        [string]
        $Value,

        [Parameter()]
        [string]
        $Default = 0,

        [Parameter(Mandatory = $true)]
        [ValidateSet('px', '%', 'em')]
        [string]
        $Type,

        [switch]
        $AllowNull
    )

    if ($AllowNull -and [string]::IsNullOrEmpty($Value)) {
        return $null
    }

    $pattern = Get-PodeWebNumberRegex
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

function Get-PodeWebNumberRegex {
    return '^\-?\d+(\.\d+){0,1}$'
}

function Set-PodeWebSecurity {
    param(
        [Parameter()]
        [ValidateSet('None', 'Default', 'Simple', 'Strict')]
        [string]
        $Security,

        [switch]
        $UseHsts
    )

    if ($Security -ieq 'none') {
        Remove-PodeSecurity
        return
    }

    switch ($Security.ToLowerInvariant()) {
        'default' {
            Set-PodeSecurity -Type Simple -UseHsts:$UseHsts
            Remove-PodeSecurityCrossOrigin

            Add-PodeSecurityContentSecurityPolicy `
                -Default 'http', 'https' `
                -Style 'http', 'https' `
                -Scripts 'http', 'https' `
                -Image 'http', 'https'
        }

        'simple' {
            Set-PodeSecurity -Type Simple -UseHsts:$UseHsts
        }

        'strict' {
            Set-PodeSecurity -Type Strict -UseHsts:$UseHsts
        }
    }

    Add-PodeSecurityContentSecurityPolicy `
        -Style 'self', 'unsafe-inline' `
        -Scripts 'self', 'unsafe-inline' `
        -Image 'self', 'data'
}

function Test-PodeWebParameter {
    param(
        [Parameter(Mandatory = $true)]
        $Parameters,

        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        $Value
    )

    if ($Parameters.ContainsKey($Name)) {
        return $Value
    }

    return $null
}

function Protect-PodeWebIconType {
    param(
        [Parameter()]
        [object]
        $Icon,

        [Parameter(Mandatory = $true)]
        [string]
        $Element
    )

    # just null or string
    if (($null -eq $Icon) -or ($Icon -is [string])) {
        return $Icon
    }

    # if hashtable, check object type
    if (($Icon -is [hashtable]) -and ($Icon.ObjectType -ieq 'icon')) {
        return $Icon
    }

    # error
    throw "Icon for '$($Element)' is not a string or hashtable from New-PodeWebIcon"
}

function Protect-PodeWebIconPreset {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Icon,

        [Parameter()]
        [hashtable]
        $Preset
    )

    if (($null -eq $Preset) -or ($Preset.Length -eq 0)) {
        return $null
    }

    if ([string]::IsNullOrWhiteSpace($Preset.Name)) {
        $Preset.Name = $Icon.Name
    }

    if ([string]::IsNullOrWhiteSpace($Preset.Colour)) {
        $Preset.Colour = $Icon.Colour
    }

    if ([string]::IsNullOrWhiteSpace($Preset.Title)) {
        $Preset.Title = $Icon.Title
    }

    if ([string]::IsNullOrWhiteSpace($Preset.Flip)) {
        $Preset.Flip = $Icon.Flip
    }

    if ($Preset.Rotate -le -1) {
        $Preset.Rotate = $Icon.Rotate
    }

    if ($Preset.Size -le -1) {
        $Preset.Size = $Icon.Size
    }

    if ($null -eq $Preset.Spin) {
        $Preset.Spin = $Icon.Spin
    }

    return $Preset
}

function Invoke-PodeWebScriptBlock {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Logic,

        [Parameter()]
        $Arguments = $null
    )

    $result = Invoke-PodeScriptBlock -ScriptBlock $Logic.ScriptBlock -Arguments $Arguments -UsingVariables $Logic.UsingVariables -Splat -Return
    if ($null -eq $result) {
        $result = @()
    }

    return $result
}

function Set-PodeWebMetadata {
    $WebEvent.Metadata.SenderId = Get-PodeHeader -Name 'X-PODE-WEB-SENDER-ID'
}

function Test-PodeWebResponseType {
    param(
        [Parameter()]
        [ValidateSet('Http', 'Sse')]
        [string]
        $Type
    )

    return ((Get-PodeWebState -Name 'resp-type') -ieq $Type)
}

function Get-PodeWebResponseType {
    return (Get-PodeWebState -Name 'resp-type')
}
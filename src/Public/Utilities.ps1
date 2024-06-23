function Use-PodeWebTemplates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Title,

        [Parameter()]
        [string]
        $Logo,

        [Parameter()]
        [string]
        $FavIcon,

        [Parameter()]
        [ValidateSet('Auto', 'Light', 'Dark', 'Midnight', 'Sepia', 'Forest', 'Terminal', 'Custom')]
        [string]
        $Theme = 'Auto',

        [Parameter()]
        [string[]]
        $EndpointName,

        [Parameter()]
        [ValidateSet('None', 'Default', 'Simple', 'Strict')]
        [string]
        $Security = 'Default',

        [Parameter()]
        [ValidateSet('Sse', 'Http')]
        [string]
        $ResponseType = 'Sse',

        [Parameter()]
        [string]
        $SseSecret,

        [switch]
        $NoPageFilter,

        [switch]
        $HideSidebar,

        [switch]
        $UseHsts,

        [switch]
        $RootRedirect
    )

    # has Pode.Web already been initialised?
    if (Get-PodeWebState -Name 'enabled') {
        throw 'Pode.Web templates have already been enabled.'
    }

    # get a favicon path
    if ([string]::IsNullOrWhiteSpace($FavIcon)) {
        $FavIcon = '/pode.web-static/images/favicon.ico'
    }

    # tell Pode to export the module for auto-loading
    Export-PodeModule -Name Pode.Web

    # if available, do we need an IIS sub-path?
    $appPath = Get-PodeIISApplicationPath
    if ([string]::IsNullOrWhiteSpace($appPath) -or ($appPath -eq '/')) {
        $appPath = [string]::Empty
    }
    Set-PodeWebState -Name 'app-path' -Value ($appPath.ToLowerInvariant())

    # setup settings
    Set-PodeWebState -Name 'enabled' -Value $true
    Set-PodeWebState -Name 'title' -Value ([System.Net.WebUtility]::HtmlEncode($Title))
    Set-PodeWebState -Name 'logo' -Value (Add-PodeWebAppPath -Url $Logo)
    Set-PodeWebState -Name 'favicon' -Value (Add-PodeWebAppPath -Url $FavIcon)
    Set-PodeWebState -Name 'no-page-filter' -Value $NoPageFilter.IsPresent
    Set-PodeWebState -Name 'hide-sidebar' -Value $HideSidebar.IsPresent
    Set-PodeWebState -Name 'root-redirect' -Value $RootRedirect.IsPresent
    Set-PodeWebState -Name 'social' -Value ([ordered]@{})
    Set-PodeWebState -Name 'pages' -Value @{}
    Set-PodeWebState -Name 'groups' -Value @{}
    Set-PodeWebState -Name 'default-nav' -Value $null
    Set-PodeWebState -Name 'endpoint-name' -Value $EndpointName
    Set-PodeWebState -Name 'custom-css' -Value @()
    Set-PodeWebState -Name 'custom-js' -Value @()
    Set-PodeWebState -Name 'resp-type' -Value $ResponseType.ToLowerInvariant()

    # themes
    Set-PodeWebState -Name 'theme' -Value $Theme.ToLowerInvariant()
    Set-PodeWebState -Name 'custom-themes' -Value @{
        Default = $null
        Themes  = [ordered]@{}
    }

    # system urls
    Set-PodeWebSystemUrlDefaults

    # public and view folders
    $templatePath = Get-PodeWebTemplatePath
    Add-PodeStaticRoute -Path '/pode.web-static' -Source (Join-PodeWebPath $templatePath 'Public')
    Add-PodeViewFolder -Name 'pode.web.views' -Source (Join-PodeWebPath $templatePath 'Views')

    # setup default security headers
    Set-PodeWebSecurity -Security $Security -UseHsts:$UseHsts

    # initialise SSE connections
    if (Test-PodeWebResponseType -Type Sse) {
        if ([string]::IsNullOrEmpty($SseSecret)) {
            $SseSecret = Get-PodeServerDefaultSecret
        }

        Enable-PodeSseSigning -Strict -Secret $SseSecret
    }

    # add an empty root route, which simply redirects to the first available page
    if ($RootRedirect) {
        Add-PodeRoute -Method Get -Path '/' -EndpointName $EndpointName -ScriptBlock {
            # get first page and redirect
            $page = Get-PodeWebFirstPublicPage
            if ($null -ne $page) {
                Move-PodeResponseUrl -Url $page.Url
                return
            }

            # fail if no pages found
            Set-PodeResponseStatus -Code 421
        }
    }
}

function Import-PodeWebStylesheet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Url
    )

    Set-PodeWebState -Name 'custom-css' -Value  (@(Get-PodeWebState -Name 'custom-css') + (Add-PodeWebAppPath -Url $Url))
}

function Import-PodeWebJavaScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Url
    )

    Set-PodeWebState -Name 'custom-js' -Value  (@(Get-PodeWebState -Name 'custom-js') + (Add-PodeWebAppPath -Url $Url))
}

function Set-PodeWebSocial {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('GitHub', 'Twitter', 'Facebook', 'LinkedIn', 'Twitch', 'GitLab', 'Instagram', 'Telegram',
            'Pinterest', 'Slack', 'Discord', 'BitBucket', 'Jira', 'YouTube')]
        [string]
        $Type,

        [Parameter(Mandatory = $true)]
        [string]
        $Url,

        [Parameter()]
        [string]
        $Tooltip
    )

    if ([string]::IsNullOrWhiteSpace($Tooltip)) {
        $Tooltip = $Type
    }

    $socials = Get-PodeWebState -Name 'social'
    $socials[$Type] = @{
        Url     = $Url
        Tooltip = $Tooltip
    }
}

function Get-PodeWebTheme {
    [CmdletBinding()]
    param(
        [switch]
        $IgnoreCookie
    )

    $theme = [string]::Empty

    # check cookies
    if (!$IgnoreCookie) {
        $theme = Get-PodeWebCookie -Name 'theme'
        if (($null -ne $theme) -and ![string]::IsNullOrWhiteSpace($theme.Value)) {
            $theme = $theme.Value
        }
    }

    # check auth data
    if ([string]::IsNullOrWhiteSpace($theme)) {
        $theme = Get-PodeWebAuthTheme -User (Get-PodeAuthUser)
    }

    # check state
    if ([string]::IsNullOrWhiteSpace($theme)) {
        $theme = (Get-PodeWebState -Name 'theme')
    }

    # if 'custom', set as default custom theme
    if ($theme -ieq 'custom') {
        $theme = (Get-PodeWebState -Name 'custom-themes').Default
    }

    if ([string]::IsNullOrWhiteSpace($theme)) {
        $theme = 'Auto'
    }

    return $theme.ToLowerInvariant()
}

function Test-PodeWebTheme {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [ValidateSet('Any', 'Inbuilt', 'Custom')]
        [string]
        $Type = 'Any'
    )

    if ($Type -iin 'Inbuilt', 'Any') {
        return (Test-PodeWebThemeInbuilt -Name $Name)
    }

    if ($Type -iin 'Custom', 'Any') {
        return (Test-PodeWebThemeCustom -Name $Name)
    }
}

function Get-PodeWebUsername {
    [CmdletBinding()]
    param()

    $authData = Get-PodeWebAuthData
    return (Get-PodeWebAuthUsername -AuthData $authData)
}

function Set-PodeWebCustomThemeDefault {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name
    )

    # test that the custom theme exists
    if (!(Test-PodeWebTheme -Name $Name -Type 'Custom')) {
        throw "The custom theme '$($Name)' does not exist"
    }

    $customThemes = Get-PodeWebState -Name 'custom-themes'
    $customThemes.Default = $Name.ToLowerInvariant()
}

function Add-PodeWebCustomTheme {
    [CmdletBinding(DefaultParameterSetName = 'Url')]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        [ValidateSet('None', 'Light', 'Dark', 'Midnight', 'Terminal')]
        [string]
        $Base = 'None',

        [Parameter(Mandatory = $true, ParameterSetName = 'Url')]
        [string]
        $Url,

        [Parameter(ParameterSetName = 'Config')]
        [ValidateSet('Normal', 'Light', 'Dark')]
        [string]
        $ColourScheme,

        [Parameter(ParameterSetName = 'Config')]
        [string[]]
        $FontFamily,

        [Parameter(ParameterSetName = 'Config')]
        [hashtable]
        $BackgroundColourConfig,

        [Parameter(ParameterSetName = 'Config')]
        [hashtable]
        $BorderColourConfig,

        [Parameter(ParameterSetName = 'Config')]
        [hashtable]
        $TextColourConfig,

        [Parameter(ParameterSetName = 'Config')]
        [hashtable]
        $NavColourConfig,

        [Parameter(ParameterSetName = 'Config')]
        [hashtable]
        $ToastColourConfig,

        [Parameter(ParameterSetName = 'Config')]
        [hashtable]
        $CalendarIconColourConfig,

        [Parameter(ParameterSetName = 'Config')]
        [hashtable]
        $ChartColourConfig,

        [Parameter(ParameterSetName = 'Config')]
        [ValidateSet('Light', 'Dark', 'HighContrast')]
        [string]
        $CodeEditorTheme,

        [Parameter(ParameterSetName = 'Config')]
        [ValidateSet('Light', 'Dark')]
        [string]
        $CodeTheme
    )

    # is the theme already inbuilt?
    if (Test-PodeWebTheme -Name $Name -Type 'Inbuilt') {
        throw "There is already an inbuilt theme for '$($Name)' defined"
    }

    # is the theme already defined?
    if (Test-PodeWebTheme -Name $Name -Type 'Custom') {
        throw "There is already a custom theme for '$($Name)' defined"
    }

    # if using config, set appropriate URL, and create route if it doesn't already exist
    if ($PSCmdlet.ParameterSetName -ieq 'Config') {
        # build the url
        $Url = Get-PodeWebCustomThemeRoutePath
        $Url += "?name=$($Name)"

        # add route
        Add-PodeWebCustomThemeRoute
    }

    # add the custom theme
    $Name = $Name.ToLowerInvariant()
    $customThemes = Get-PodeWebState -Name 'custom-themes'

    $customThemes.Themes[$Name] = @{
        Url      = (Add-PodeWebAppPath -Url $Url)
        Base     = $Base
        IsStatic = ($PSCmdlet.ParameterSetName -ieq 'Url')
        Config   = @{
            ColourScheme             = $ColourScheme
            FontFamily               = $FontFamily
            BackgroundColourConfig   = $BackgroundColourConfig
            BorderColourConfig       = $BorderColourConfig
            TextColourConfig         = $TextColourConfig
            NavColourConfig          = $NavColourConfig
            ToastColourConfig        = $ToastColourConfig
            CalendarIconColourConfig = $CalendarIconColourConfig
            CodeEditorTheme          = $CodeEditorTheme
            CodeTheme                = $CodeTheme
            ChartColourConfig        = $ChartColourConfig
        }
    }

    # set as theme if first one
    $currentTheme = Get-PodeWebState -Name 'theme'
    if ($currentTheme -ieq 'custom') {
        Set-PodeWebState -Name 'theme' -Value $Name
    }

    if ([string]::IsNullOrWhiteSpace($customThemes.Default)) {
        $customThemes.Default = $Name
    }
}

function New-PodeWebBackgroundColourConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Page,

        [Parameter()]
        [string]
        $Hero,

        [Parameter()]
        [string]
        $Primary,

        [Parameter()]
        [string]
        $Secondary,

        [Parameter()]
        [string]
        $Tertiary
    )

    return @{
        Page      = (Test-PodeWebColour -Colour $Page -AllowEmpty)
        Hero      = (Test-PodeWebColour -Colour $Hero -AllowEmpty)
        Primary   = (Test-PodeWebColour -Colour $Primary -AllowEmpty)
        Secondary = (Test-PodeWebColour -Colour $Secondary -AllowEmpty)
        Tertiary  = (Test-PodeWebColour -Colour $Tertiary -AllowEmpty)
    }
}

function New-PodeWebBorderColourConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Primary,

        [Parameter()]
        [string]
        $Secondary,

        [Parameter()]
        [string]
        $Tertiary
    )

    return @{
        Primary   = (Test-PodeWebColour -Colour $Primary -AllowEmpty)
        Secondary = (Test-PodeWebColour -Colour $Secondary -AllowEmpty)
        Tertiary  = (Test-PodeWebColour -Colour $Tertiary -AllowEmpty)
    }
}

function New-PodeWebTextColourConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Primary,

        [Parameter()]
        [string]
        $Secondary,

        [Parameter()]
        [string]
        $Tertiary,

        [Parameter()]
        [string]
        $Link,

        [Parameter()]
        [string]
        $HoverPrimary,

        [Parameter()]
        [string]
        $HoverSecondary,

        [Parameter()]
        [string]
        $Disabled,

        [Parameter()]
        [string]
        $Enabled
    )

    return @{
        Primary           = (Test-PodeWebColour -Colour $Primary -AllowEmpty)
        Secondary         = (Test-PodeWebColour -Colour $Secondary -AllowEmpty)
        Tertiary          = (Test-PodeWebColour -Colour $Tertiary -AllowEmpty)
        Link              = (Test-PodeWebColour -Colour $Link -AllowEmpty)
        'Hover-Primary'   = (Test-PodeWebColour -Colour $HoverPrimary -AllowEmpty)
        'Hover-Secondary' = (Test-PodeWebColour -Colour $HoverSecondary -AllowEmpty)
        Disabled          = (Test-PodeWebColour -Colour $Disabled -AllowEmpty)
        Enabled           = (Test-PodeWebColour -Colour $Enabled -AllowEmpty)
    }
}

function New-PodeWebNavColourConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Background,

        [Parameter()]
        [string]
        $Border,

        [Parameter()]
        [string]
        $Text,

        [Parameter()]
        [string]
        $HoverText
    )

    return @{
        Background   = (Test-PodeWebColour -Colour $Background -AllowEmpty)
        Border       = (Test-PodeWebColour -Colour $Border -AllowEmpty)
        Text         = (Test-PodeWebColour -Colour $Text -AllowEmpty)
        'Hover-Text' = (Test-PodeWebColour -Colour $HoverText -AllowEmpty)
    }
}

function New-PodeWebToastColourConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $BackgroundPrimary,

        [Parameter()]
        [string]
        $BackgroundSecondary,

        [Parameter()]
        [string]
        $Border,

        [Parameter()]
        [string]
        $TextPrimary,

        [Parameter()]
        [string]
        $TextSecondary
    )

    return @{
        'Primary-Background'   = (Test-PodeWebColour -Colour $BackgroundPrimary -AllowEmpty)
        'Secondary-Background' = (Test-PodeWebColour -Colour $BackgroundSecondary -AllowEmpty)
        Border                 = (Test-PodeWebColour -Colour $Border -AllowEmpty)
        'Primary-Text'         = (Test-PodeWebColour -Colour $TextPrimary -AllowEmpty)
        'Secondary-Text'       = (Test-PodeWebColour -Colour $TextSecondary -AllowEmpty)
    }
}

function New-PodeWebCalendarIconColourConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Primary,

        [Parameter()]
        [string]
        $Hover
    )

    return @{
        Indicator         = $Primary
        'Indicator-Hover' = $Hover
    }
}

function New-PodeWebChartColourConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]
        $Point,

        [Parameter()]
        [string]
        $Grid,

        [Parameter()]
        [string]
        $Tick,

        [Parameter()]
        [string]
        $Border
    )

    return @{
        Point  = (Test-PodeWebColour -Colour $Point -AllowEmpty)
        Grid   = (Test-PodeWebColour -Colour $Grid -AllowEmpty)
        Tick   = (Test-PodeWebColour -Colour $Tick -AllowEmpty)
        Border = (Test-PodeWebColour -Colour $Border -AllowEmpty)
    }
}

function Join-PodeWebPath {
    param(
        [Parameter()]
        [string]
        $Path,

        [Parameter()]
        [string]
        $ChildPath,

        [switch]
        $ReplaceSlashes
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $result = $ChildPath
    }
    elseif ([string]::IsNullOrWhiteSpace($ChildPath)) {
        $result = $Path
    }
    else {
        $result = (Join-Path $Path $ChildPath)
    }

    if ($ReplaceSlashes) {
        $result = ($result -ireplace '\\', '/')
    }

    return $result
}

function Set-PodeWebAuth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Authentication,

        [Parameter()]
        [string]
        $UsernameProperty,

        [Parameter()]
        [string]
        $GroupProperty,

        [Parameter()]
        [string]
        $AvatarProperty,

        [Parameter()]
        [string]
        $ThemeProperty
    )

    Set-PodeWebState -Name 'auth' -Value $Authentication
    Set-PodeWebState -Name 'auth-props' -Value @{
        Username = $UsernameProperty
        Group    = $GroupProperty
        Avatar   = $AvatarProperty
        Theme    = $ThemeProperty
        Logout   = $false
    }

    # set default failure/success urls
    $auth = Get-PodeAuth -Name $Authentication

    if ([string]::IsNullOrWhiteSpace($auth.Failure.Url)) {
        $auth.Failure.Url = (Add-PodeWebAppPath -Url '/')
    }

    if ([string]::IsNullOrWhiteSpace($auth.Success.Url)) {
        $auth.Success.Url = (Add-PodeWebAppPath -Url '/')
    }

    if ($PassThru) {
        return $pageMeta
    }
}
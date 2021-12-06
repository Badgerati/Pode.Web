function Use-PodeWebTemplates
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Title,

        [Parameter()]
        [string]
        $Logo,

        [Parameter()]
        [string]
        $FavIcon,

        [Parameter()]
        [ValidateSet('Auto', 'Light', 'Dark', 'Terminal', 'Custom')]
        [string]
        $Theme = 'Auto',

        [Parameter()]
        [string[]]
        $EndpointName,

        [switch]
        $NoPageFilter,

        [switch]
        $HideSidebar
    )

    $mod = (Get-Module -Name Pode -ErrorAction Ignore | Sort-Object -Property Version -Descending | Select-Object -First 1)
    if (($null -eq $mod) -or ($mod.Version -lt [version]'2.5.0')) {
        throw "The Pode module is not loaded. You need at least Pode v2.5.0 to use this version of the Pode.Web module."
    }

    if ([string]::IsNullOrWhiteSpace($FavIcon)) {
        $FavIcon = '/pode.web/images/favicon.ico'
    }

    Export-PodeModule -Name Pode.Web

    $appPath = Get-PodeIISApplicationPath
    if ([string]::IsNullOrWhiteSpace($appPath) -or ($appPath -eq '/')) {
        $appPath = [string]::Empty
    }
    Set-PodeWebState -Name 'app-path' -Value ($appPath.ToLowerInvariant())

    Set-PodeWebState -Name 'title' -Value $Title
    Set-PodeWebState -Name 'logo' -Value (Add-PodeWebAppPath -Url $Logo)
    Set-PodeWebState -Name 'favicon' -Value (Add-PodeWebAppPath -Url $FavIcon)
    Set-PodeWebState -Name 'no-page-filter' -Value $NoPageFilter.IsPresent
    Set-PodeWebState -Name 'hide-sidebar' -Value $HideSidebar.IsPresent
    Set-PodeWebState -Name 'social' -Value ([ordered]@{})
    Set-PodeWebState -Name 'pages' -Value @{}
    Set-PodeWebState -Name 'default-nav' -Value $null
    Set-PodeWebState -Name 'endpoint-name' -Value $EndpointName
    Set-PodeWebState -Name 'custom-css' -Value @()
    Set-PodeWebState -Name 'custom-js' -Value @()

    Set-PodeWebState -Name 'theme' -Value $Theme.ToLowerInvariant()
    Set-PodeWebState -Name 'custom-themes' -Value @{
        Default = $null
        Themes = [ordered]@{}
    }

    $templatePath = Get-PodeWebTemplatePath

    Add-PodeStaticRoute -Path '/pode.web' -Source (Join-PodeWebPath $templatePath 'Public')
    Add-PodeViewFolder -Name 'pode.web.views' -Source (Join-PodeWebPath $templatePath 'Views')

    Add-PodeRoute -Method Get -Path '/' -EndpointName $EndpointName -ScriptBlock {
        $page = Get-PodeWebFirstPublicPage
        if ($null -ne $page) {
            Move-PodeResponseUrl -Url (Get-PodeWebPagePath -Page $page)
        }

        Write-PodeWebViewResponse -Path 'index' -Data @{
            Page = @{
                Name = 'Home'
                Path = '/'
                IsSystem = $true
            }
        }
    }
}

function Import-PodeWebStylesheet
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Url
    )

    Set-PodeWebState -Name 'custom-css' -Value  (@(Get-PodeWebState -Name 'custom-css') + (Add-PodeWebAppPath -Url $Url))
}

function Import-PodeWebJavaScript
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Url
    )

    Set-PodeWebState -Name 'custom-js' -Value  (@(Get-PodeWebState -Name 'custom-js') + (Add-PodeWebAppPath -Url $Url))
}

function Set-PodeWebSocial
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('GitHub', 'Twitter', 'Facebook', 'LinkedIn', 'Twitch', 'GitLab', 'Instagram', 'Telegram',
            'Pinterest', 'Slack', 'Discord', 'BitBucket', 'Jira', 'YouTube')]
        [string]
        $Type,

        [Parameter(Mandatory=$true)]
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
        Url = $Url
        Tooltip = $Tooltip
    }
}

function Get-PodeWebTheme
{
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
        $theme = Get-PodeWebAuthTheme -AuthData (Get-PodeWebAuthData)
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

function Test-PodeWebTheme
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name
    )

    return ((Test-PodeWebThemeInbuilt -Name $Name) -or (Test-PodeWebThemeCustom -Name $Name))
}

function Get-PodeWebUsername
{
    [CmdletBinding()]
    param()

    $authData = Get-PodeWebAuthData
    return (Get-PodeWebAuthUsername -AuthData $authData)
}

function Add-PodeWebCustomTheme
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $Url
    )

    $Name = $Name.ToLowerInvariant()

    # is the theme already inbuilt?
    $inbuildThemes = Get-PodeWebInbuiltThemes
    if ($Name -iin $inbuildThemes) {
        throw "There is already an inbuilt theme for $($Name) defined"
    }

    # is the theme already defined?
    $customThemes = Get-PodeWebState -Name 'custom-themes'
    if ($customThemes.Themes.Keys -icontains $Name) {
        throw "There is already a custom theme for $($Name) defined"
    }

    # add the custom theme
    $customThemes.Themes[$Name] = @{
        Url = (Add-PodeWebAppPath -Url $Url)
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

function Join-PodeWebPath
{
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
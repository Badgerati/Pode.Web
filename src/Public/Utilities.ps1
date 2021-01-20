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
        [ValidateSet('Auto', 'Light', 'Dark', 'Terminal')]
        [string]
        $Theme = 'Auto'
    )

    $mod = (Get-Module -Name Pode -ErrorAction Ignore)
    if (($null -eq $mod) -or ($mod.Version.Major -lt 2)) {
        throw "The Pode module is not loaded. You need at least Pode 2.0 to use the Pode.Web module."
    }

    if ([string]::IsNullOrWhiteSpace($FavIcon)) {
        $FavIcon = '/pode.web/images/favicon.ico'
    }

    Export-PodeModule -Name Pode.Web

    Set-PodeWebState -Name 'title' -Value $Title
    Set-PodeWebState -Name 'logo' -Value $Logo
    Set-PodeWebState -Name 'favicon' -Value $FavIcon
    Set-PodeWebState -Name 'theme' -Value $Theme.ToLowerInvariant()
    Set-PodeWebState -Name 'social' -Value @{}
    Set-PodeWebState -Name 'pages' -Value @()
    Set-PodeWebState -Name 'custom-css' -Value @()
    Set-PodeWebState -Name 'custom-js' -Value @()

    $templatePath = Get-PodeWebTemplatePath

    Add-PodeStaticRoute -Path '/pode.web' -Source (Join-Path $templatePath 'Public')
    Add-PodeViewFolder -Name 'pode.web.views' -Source (Join-Path $templatePath 'Views')

    Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
        $pages = @(Get-PodeWebState -Name 'pages')
        if (($null -ne $pages) -and ($pages.Length -gt 0)) {
            Move-PodeResponseUrl -Url "/pages/$($pages[0].Name)"
            return
        }

        Write-PodeWebViewResponse -Path 'index' -Data @{
            Page = @{
                Name = 'Home'
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

    Set-PodeWebState -Name 'custom-css' -Value  (@(Get-PodeWebState -Name 'custom-css') + $Url)
}

function Import-PodeWebJavaScript
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Url
    )

    Set-PodeWebState -Name 'custom-js' -Value  (@(Get-PodeWebState -Name 'custom-js') + $Url)
}

function Set-PodeWebSocial
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('GitHub', 'Twitter', 'Facebook', 'LinkedIn', 'Twitch', 'GitLab', 'Instagram')]
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

    if (!$IgnoreCookie) {
        $theme = Get-PodeWebCookie -Name 'theme'
        if (($null -ne $theme) -and ![string]::IsNullOrWhiteSpace($theme.Value)) {
            return $theme.Value.ToLowerInvariant()
        }
    }

    $theme = Get-PodeWebAuthTheme -AuthData (Get-PodeWebAuthData)
    if (![string]::IsNullOrWhiteSpace($theme)) {
        return $theme.ToLowerInvariant()
    }

    return (Get-PodeWebState -Name 'theme').ToLowerInvariant()
}
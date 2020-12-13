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
        [string]
        $Stylesheet,

        [switch]
        $DarkMode
    )

    $mod = (Get-Module -Name Pode -ErrorAction Ignore)
    if (($null -eq $mod) -or ($mod.Version.Major -lt 2)) {
        throw "The Pode module is not loaded. You need at least Pode 2.0 to use the Pode.Web module."
    }

    if ([string]::IsNullOrWhiteSpace($FavIcon)) {
        $FavIcon = '/pode.web/images/favicon.ico'
    }

    Set-PodeWebState -Name 'title' -Value $Title
    Set-PodeWebState -Name 'logo' -Value $Logo
    Set-PodeWebState -Name 'favicon' -Value $FavIcon
    Set-PodeWebState -Name 'stylesheet' -Value $Stylesheet
    Set-PodeWebState -Name 'darkmode' -Value $DarkMode.IsPresent
    Set-PodeWebState -Name 'pages' -Value @()

    $templatePath = Get-PodeWebTemplatePath

    Add-PodeStaticRoute -Path '/pode.web' -Source (Join-Path $templatePath 'Public')
    Add-PodeViewFolder -Name 'pode.web.views' -Source (Join-Path $templatePath 'Views')

    Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
        Write-PodeWebViewResponse -Path 'index' -Data @{ Name = 'Home' }
    }
}
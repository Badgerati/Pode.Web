function New-PodeWebNavLink
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Url,

        [switch]
        $Disabled
    )

    return @{
        ComponentType = 'Navigation'
        NavType = 'Link'
        Name = $Name
        ID = (Get-PodeWebElementId -Tag 'Nav-Link' -Id $Id -Name $Name)
        Url = $Url
        Disabled = $Disabled.IsPresent
        InDropdown = $false
    }
}

function New-PodeWebNavDropdown
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Items,

        [switch]
        $Disabled,

        [switch]
        $Hover
    )

    foreach ($item in $Items) {
        $item.InDropdown = $true
    }

    return @{
        ComponentType = 'Navigation'
        NavType = 'Dropdown'
        Name = $Name
        ID = (Get-PodeWebElementId -Tag 'Nav-Dropdown' -Id $Id -Name $Name)
        Items = $Items
        Disabled = $Disabled.IsPresent
        Hover = $Hover.IsPresent
        InDropdown = $false
    }
}

function New-PodeWebNavDivider
{
    [CmdletBinding()]
    param()

    return @{
        ComponentType = 'Navigation'
        NavType = 'Divider'
        InDropdown = $false
    }
}

function Set-PodeWebNavDefault
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Items
    )

    Set-PodeWebState -Name 'default-nav' -Value $Items
}

function Get-PodeWebNavDefault
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable[]]
        $Items
    )

    if (($null -eq $Items) -or ($items.Length -eq 0)) {
        return (Get-PodeWebState -Name 'default-nav')
    }
    
    return $Items
}
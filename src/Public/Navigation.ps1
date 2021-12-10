function New-PodeWebNavLink
{
    [CmdletBinding(DefaultParameterSetName='Url')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $DisplayName,

        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Url')]
        [string]
        $Url,

        [Parameter(Mandatory=$true, ParameterSetName='ScriptBlock')]
        [scriptblock]
        $ScriptBlock,

        [Parameter(ParameterSetName='ScriptBlock')]
        [object[]]
        $ArgumentList,

        [Parameter()]
        [string]
        $Icon,

        [switch]
        $Disabled,

        [Parameter(ParameterSetName='ScriptBlock')]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [Parameter(ParameterSetName='Url')]
        [switch]
        $NewTab
    )

    $Id = (Get-PodeWebElementId -Tag 'Nav-Link' -Id $Id -Name $Name)

    $nav = @{
        ComponentType = 'Navigation'
        NavType = 'Link'
        Name = $Name
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name -Encode)
        ID = $Id
        Url = (Add-PodeWebAppPath -Url $Url)
        Icon = $Icon
        IsDynamic = ($null -ne $ScriptBlock)
        Disabled = $Disabled.IsPresent
        InDropdown = $false
        NewTab = $NewTab.IsPresent
    }

    $routePath = "/nav/link/$($Id)"
    if (($null -ne $ScriptBlock) -and !(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        if (Test-PodeIsEmpty $EndpointName) {
            $EndpointName = Get-PodeWebState -Name 'endpoint-name'
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $global:NavData = $using:nav

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            if (!$WebEvent.Response.Headers.ContainsKey('Content-Disposition')) {
                Write-PodeJsonResponse -Value $result
            }

            $global:NavData = $null
        }
    }

    return $nav
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
        $DisplayName,

        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Items,

        [Parameter()]
        [string]
        $Icon,

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
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name -Encode)
        ID = (Get-PodeWebElementId -Tag 'Nav-Dropdown' -Id $Id -Name $Name)
        Items = $Items
        Icon = $Icon
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
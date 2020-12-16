function New-PodeWebGrid
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable[]]
        $Components,

        [switch]
        $Vertical
    )

    # ensure components are correct
    foreach ($component in $Components) {
        if ([string]::IsNullOrWhiteSpace($component.ComponentType)) {
            throw "Invalid component supplied: $($component)"
        }
    }

    return @{
        ComponentType = 'Grid'
        Components = $Components
        Vertical = $Vertical.IsPresent
    }
}

function New-PodeWebTabs
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Tabs
    )

    return @{
        ComponentType = 'Tabs'
        Tabs = $Tabs
    }
}

function New-PodeWebTab
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [hashtable[]]
        $Components
    )

    # ensure components are correct
    foreach ($component in $Components) {
        if ([string]::IsNullOrWhiteSpace($component.ComponentType)) {
            throw "Invalid component supplied: $($component)"
        }
    }

    return @{
        ComponentType = 'Tab'
        Name = $Name
        ID = ("tab_$(Protect-PodeWebName -Name $Name)_$(Get-PodeWebRandomName)" -replace '\s+', '_')
        Components = $Components
    }
}
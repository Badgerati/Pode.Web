function Get-PodeWebSidebarOrderedArray {
    param(
        [Parameter(Mandatory = $true)]
        [array]
        $Items,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Ascending', 'Descending', 'Creation')]
        [string]
        $Order
    )

    if (($Order -ieq 'creation') -or ($null -eq $Items) -or ($Items.Length -eq 0)) {
        return $Items
    }

    [array]::Sort($Items)

    if ($Order -ieq 'descending') {
        [array]::Reverse($Items)
    }

    return $Items
}

function Get-PodeWebSidebarParentGroupNames {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable[]]
        $Groups
    )

    # get only parent groups
    $groupNames = @(foreach ($grp in $Groups) {
            if ([string]::IsNullOrEmpty($grp.Parent)) {
                $grp.Name
            }
        })

    if ($groupNames.Length -eq 0) {
        return @()
    }

    # order the groups
    $groupNames = Get-PodeWebSidebarOrderedGroupNames -Names $groupNames

    # preserve empty group at start
    if ($groupNames -contains '') {
        $groupNames = @('') + @(foreach ($name in $groupNames) {
                if ($name -ne '') {
                    $name
                }
            })
    }

    # return the group names
    return $groupNames
}

function Get-PodeWebSidebarOrderedGroupNames {
    param(
        [Parameter()]
        [string[]]
        $Names
    )

    if ($Names.Length -eq 0) {
        return @()
    }

    $groupOrder = Get-PodeWebState -Name 'group-order'
    $groupNames = Get-PodeWebSidebarOrderedArray -Items $Names -Order $groupOrder
    return $groupNames
}
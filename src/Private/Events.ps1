function Register-PodeWebComponentEventInternal
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [hashtable]
        $Component,

        [Parameter(Mandatory=$true)]
        [string]
        $Type,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [object[]]
        $ArgumentList,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    # does component support events?
    if ($Component.NoEvents -or ($Component.ComponentType -ine 'element')) {
        throw "$($Component.ObjectType) $($Component.ComponentType) with ID '$($Component.ID)' does not support events"
    }

    # add events map if not present
    if ($null -eq $Component.Events) {
        $Component.Events = @()
    }

    # ensure not already defined
    if ($Component.Events -icontains $Type) {
        throw "$($Component.ObjectType) $($Component.ComponentType) with ID '$($Component.ID)' already has the $($Type) event defined"
    }

    # add event type
    $Component.Events += $Type.ToLowerInvariant()

    # setup the route
    $routePath = "/components/$($Component.ObjectType.ToLowerInvariant())/$($Component.ID)/events/$($Type.ToLowerInvariant())"
    if (!(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication -and !$Component.NoAuthentication -and !$PageData.NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $Component.EndpointName -ScriptBlock {
            param($Data)
            $global:ComponentData = $using:Component
            $global:EventType = $using:Type

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            if (!$WebEvent.Response.Headers.ContainsKey('Content-Disposition')) {
                Write-PodeJsonResponse -Value $result
            }

            $global:ComponentData = $null
        }
    }
}

function Register-PodeWebPageEventInternal
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [hashtable]
        $Page,

        [Parameter(Mandatory=$true)]
        [string]
        $Type,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [object[]]
        $ArgumentList,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    # does page support events?
    if ($Page.NoEvents -or ($Page.ComponentType -ine 'page')) {
        throw "$($Page.ObjectType) '$($Page.Name) [Group: $($Page.Group)]' does not support events"
    }

    # add events map if not present
    if ($null -eq $Page.Events) {
        $Page.Events = @()
    }

    # ensure not already defined
    if ($Page.Events -icontains $Type) {
        throw "$($Page.ObjectType) '$($Page.Name) [Group: $($Page.Group)]' already has the $($Type) event defined"
    }

    # add event type
    $Page.Events += $Type.ToLowerInvariant()

    # setup the route
    $routePath = "$($Page.Path)/events/$($Type.ToLowerInvariant())"
    if (!(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication -and !$Page.NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $Page.EndpointName -ScriptBlock {
            param($Data)
            $global:PageData = $using:Page
            $global:EventType = $using:Type

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            if (!$WebEvent.Response.Headers.ContainsKey('Content-Disposition')) {
                Write-PodeJsonResponse -Value $result
            }

            $global:PageData = $null
        }
    }
}
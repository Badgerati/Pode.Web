function Register-PodeWebElementEventInternal
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [hashtable]
        $Element,

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
    if ($Element.NoEvents -or ($Element.ComponentType -ine 'element')) {
        throw "$($Element.ObjectType) $($Element.ComponentType) with ID '$($Element.ID)' does not support events"
    }

    # add events map if not present
    if ($null -eq $Element.Events) {
        $Element.Events = @()
    }

    # ensure not already defined
    if ($Element.Events -icontains $Type) {
        throw "$($Element.ObjectType) $($Element.ComponentType) with ID '$($Element.ID)' already has the $($Type) event defined"
    }

    # add event type
    $Element.Events += $Type.ToLowerInvariant()

    # setup the route
    $routePath = "/elements/$($Element.ObjectType.ToLowerInvariant())/$($Element.ID)/events/$($Type.ToLowerInvariant())"
    if (!(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication -and !$Element.NoAuthentication -and !$PageData.NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $Element.EndpointName -ScriptBlock {
            param($Data)
            $global:ElementData = $using:Element
            $global:EventType = $using:Type

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            if (!$WebEvent.Response.Headers.ContainsKey('Content-Disposition')) {
                Write-PodeJsonResponse -Value $result
            }

            $global:ElementData = $null
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
    $pagePath = $Page.Path
    if ($pagePath -eq '/') {
        $pagePath = '/home'
    }

    $routePath = "$($pagePath)/events/$($Type.ToLowerInvariant())"

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
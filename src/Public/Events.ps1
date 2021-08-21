function Register-PodeWebEvent
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNull()]
        [hashtable]
        $Component,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Change', 'Focus', 'FocusOut', 'Click', 'MouseOver', 'MouseOut', 'KeyDown', 'KeyUp')]
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

    # return the component back
    return $Component
}
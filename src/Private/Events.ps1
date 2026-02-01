function Register-PodeWebElementEventInternal {
    [CmdletBinding(DefaultParameterSetName = 'ScriptBlock')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]
        $Element,

        [Parameter(Mandatory = $true)]
        [string]
        $Type,

        [Parameter(Mandatory = $true, ParameterSetName = 'ScriptBlock')]
        [scriptblock]
        $ScriptBlock,

        [Parameter(Mandatory = $true, ParameterSetName = 'JSFunction')]
        [string]
        $JSFunction,

        [Parameter(ParameterSetName = 'ScriptBlock')]
        [object[]]
        $ArgumentList,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SessionState]
        $PSSession,

        [Parameter(ParameterSetName = 'ScriptBlock')]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    $Type = $Type.ToLowerInvariant()

    # does element support events?
    if ($Element.NoEvents -or ($Element.ComponentType -ine 'element')) {
        throw "$($Element.ObjectType) $($Element.ComponentType) with ID '$($Element.ID)' does not support events"
    }

    # add events map if not present
    if ($null -eq $Element.Events) {
        $Element.Events = @()
    }

    # add event type
    $eventObj = @{
        Type         = $Type
        ID           = $Element.Events.Length + 1
        IsClientSide = $PSCmdlet.ParameterSetName -ieq 'JSFunction'
    }

    # setup params for client-side events
    if ($eventObj.IsClientSide) {
        $eventObj.JSFunction = $JSFunction
    }

    # setup the route for server-side events
    if (!$eventObj.IsClientSide) {
        $routePath = "/pode.web-dynamic/elements/$($Element.ObjectType.ToLowerInvariant())/$($Element.ID)/events/$($Type.ToLowerInvariant())/$($eventObj.ID)"

        if (!(Test-PodeWebRoute -Path $routePath)) {
            # check for scoped vars
            $ScriptBlock, $usingVars = Convert-PodeScopedVariables -ScriptBlock $ScriptBlock -PSSession $PSSession
            $eventLogic = @{
                ScriptBlock    = $ScriptBlock
                UsingVariables = $usingVars
            }

            $auth = $null
            if (!$NoAuthentication -and !$Element.NoAuthentication -and !$PageData.NoAuthentication) {
                $auth = (Get-PodeWebState -Name 'auth')
            }

            $argList = @(
                @{ Data = $ArgumentList },
                $Element,
                $Type,
                $eventLogic
            )

            Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList $argList -EndpointName $Element.EndpointName -ScriptBlock {
                param($Data, $Element, $Type, $Logic)
                $global:ElementData = $Element
                $global:EventType = $Type
                Set-PodeWebMetadata

                $result = Invoke-PodeWebScriptBlock -Logic $Logic -Arguments $Data.Data

                if (($null -ne $result) -and !$WebEvent.Response.Headers.ContainsKey('Content-Disposition')) {
                    Write-PodeJsonResponse -Value $result
                }

                $global:ElementData = $null
            }
        }
    }

    # add event to element
    $Element.Events += $eventObj
}

function Register-PodeWebPageEventInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]
        $Page,

        [Parameter(Mandatory = $true)]
        [string]
        $Type,

        [Parameter(Mandatory = $true)]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [object[]]
        $ArgumentList,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SessionState]
        $PSSession,

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
    $routePath = "/pode.web-dynamic/pages/$($Page.ID)/events/$($Type.ToLowerInvariant())"

    if (!(Test-PodeWebRoute -Path $routePath)) {
        # check for scoped vars
        $ScriptBlock, $usingVars = Convert-PodeScopedVariables -ScriptBlock $ScriptBlock -PSSession $PSSession
        $eventLogic = @{
            ScriptBlock    = $ScriptBlock
            UsingVariables = $usingVars
        }

        $auth = $null
        if (!$NoAuthentication -and !$Page.NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        $argList = @(
            @{ Data = $ArgumentList },
            $Page,
            $Type,
            $eventLogic
        )

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList $argList -EndpointName $Page.EndpointName -ScriptBlock {
            param($Data, $Page, $Type, $Logic)
            $global:PageData = $Page
            $global:EventType = $Type
            Set-PodeWebMetadata

            $result = Invoke-PodeWebScriptBlock -Logic $Logic -Arguments $Data.Data

            if (($null -ne $result) -and !$WebEvent.Response.Headers.ContainsKey('Content-Disposition')) {
                Write-PodeJsonResponse -Value $result
            }

            $global:PageData = $null
        }
    }
}
function Register-PodeWebEvent {
    [CmdletBinding(DefaultParameterSetName = 'ScriptBlock')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [hashtable]
        $Element,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Change', 'Focus', 'FocusOut', 'Click', 'MouseOver', 'MouseOut', 'KeyDown', 'KeyUp')]
        [string[]]
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

        [Parameter(ParameterSetName = 'ScriptBlock')]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    # ensure component is and Element
    if (!(Test-PodeWebContent -Content $Element -ComponentType Element)) {
        throw "General events can only be registered on Elements, '$($Element.ComponentType)' given"
    }

    # params for internal call
    $params = @{
        Element   = $Element
        PSSession = $PSCmdlet.SessionState
    }

    switch ($PSCmdlet.ParameterSetName) {
        'ScriptBlock' {
            $params.ScriptBlock = $ScriptBlock
            $params.ArgumentList = $ArgumentList
            $params.NoAuthentication = $NoAuthentication.IsPresent
        }
        'JSFunction' {
            $params.JSFunction = $JSFunction
        }
    }

    # register event
    foreach ($t in $Type) {
        $params.Type = $t
        $null = Register-PodeWebElementEventInternal @params
    }

    return $Element
}

function Register-PodeWebMediaEvent {
    [CmdletBinding(DefaultParameterSetName = 'ScriptBlock')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [hashtable]
        $Element,

        [Parameter(Mandatory = $true)]
        [ValidateSet('CanPlay', 'Pause', 'Play', 'Ended')]
        [string[]]
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

        [Parameter(ParameterSetName = 'ScriptBlock')]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    # ensure component is Audio or Video only
    if (!(Test-PodeWebContent -Content $Element -ComponentType Element -ObjectType Audio, Video)) {
        throw "Media events can only be registered on Audio/Video elements, '$($Element.ObjectType)' given"
    }

    # params for internal call
    $params = @{
        Element   = $Element
        PSSession = $PSCmdlet.SessionState
    }

    switch ($PSCmdlet.ParameterSetName) {
        'ScriptBlock' {
            $params.ScriptBlock = $ScriptBlock
            $params.ArgumentList = $ArgumentList
            $params.NoAuthentication = $NoAuthentication.IsPresent
        }
        'JSFunction' {
            $params.JSFunction = $JSFunction
        }
    }

    # register event
    foreach ($t in $Type) {
        $params.Type = $t
        $null = Register-PodeWebElementEventInternal @params
    }

    return $Element
}

function Register-PodeWebPageEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [hashtable]
        $Page,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Load', 'Unload', 'BeforeUnload')]
        [string[]]
        $Type,

        [Parameter(Mandatory = $true)]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [object[]]
        $ArgumentList,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [switch]
        $PassThru
    )

    # ensure page is a page
    if (!(Test-PodeWebContent -Content $Page -ComponentType Page)) {
        throw "Page events can only be registered onto pages, '$($Page.ComponentType)' given"
    }

    # register event
    foreach ($t in $Type) {
        $null = Register-PodeWebPageEventInternal `
            -Page $Page `
            -Type $t `
            -ScriptBlock $ScriptBlock `
            -ArgumentList $ArgumentList `
            -PSSession $PSCmdlet.SessionState `
            -NoAuthentication:$NoAuthentication
    }

    if ($PassThru) {
        return $Page
    }
}
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
        [string[]]
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

    foreach ($t in $Type) {
        Register-PodeWebEventInternal -Component $Component -Type $t -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList -NoAuthentication:$NoAuthentication | Out-Null
    }

    return $Component
}

function Register-PodeWebMediaEvent
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNull()]
        [hashtable]
        $Component,

        [Parameter(Mandatory=$true)]
        [ValidateSet('CanPlay', 'Pause', 'Play', 'Ended')]
        [string[]]
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

    # ensure component is Audio or Video only
    if (!(Test-PodeWebContent -Content $Component -ComponentType Element -ObjectType Audio, Video)) {
        throw 'Media events can only be registered on Audio/Video elements'
    }

    # register event
    foreach ($t in $Type) {
        Register-PodeWebEventInternal -Component $Component -Type $t -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList -NoAuthentication:$NoAuthentication | Out-Null
    }

    return $Component
}
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

    return (Register-PodeWebEventInternal -Component $Component -Type $Type -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList -NoAuthentication:$NoAuthentication)
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

    # ensure component is Audio or Video only
    if (!(Test-PodeWebContent -Content $Component -ComponentType Element -ObjectType Audio)) {
        throw 'Media events can only be registered on Audio elements'
    }

    # register event
    return (Register-PodeWebEventInternal -Component $Component -Type $Type -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList -NoAuthentication:$NoAuthentication)
}
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
        Register-PodeWebComponentEventInternal `
            -Component $Component `
            -Type $t `
            -ScriptBlock $ScriptBlock `
            -ArgumentList $ArgumentList `
            -NoAuthentication:$NoAuthentication | Out-Null
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
        Register-PodeWebComponentEventInternal `
            -Component $Component `
            -Type $t `
            -ScriptBlock $ScriptBlock `
            -ArgumentList $ArgumentList `
            -NoAuthentication:$NoAuthentication | Out-Null
    }

    return $Component
}

function Register-PodeWebPageEvent
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNull()]
        [hashtable]
        $Page,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Load', 'Unload', 'BeforeUnload')]
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
        $NoAuthentication,

        [switch]
        $PassThru
    )

    # ensure page is a page
    if (!(Test-PodeWebContent -Content $Page -ComponentType Page)) {
        throw 'Page events can only be registered onto pages'
    }

    # register event
    foreach ($t in $Type) {
        Register-PodeWebPageEventInternal `
            -Page $Page `
            -Type $t `
            -ScriptBlock $ScriptBlock `
            -ArgumentList $ArgumentList `
            -NoAuthentication:$NoAuthentication | Out-Null
    }

    if ($PassThru) {
        return $Page
    }
}
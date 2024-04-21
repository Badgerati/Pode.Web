function Set-PodeWebAsyncEvent {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(ParameterSetName = 'AsyncEvent', ValueFromPipeline = $true)]
        [hashtable]
        $InputObject = $null,

        [Parameter(ParameterSetName = 'Default')]
        [string[]]
        $ClientId = $null,

        [Parameter(ParameterSetName = 'Default')]
        [string[]]
        $Group = $null,

        [Parameter(ParameterSetName = 'Default')]
        [string]
        $SenderId = $null,

        [Parameter(ParameterSetName = 'All')]
        [switch]
        $All
    )

    if ($All) {
        $ClientId = $null
        $Group = $null
        $SenderId = $null
    }
    elseif ($null -ne $InputObject) {
        $ClientId = $InputObject.ClientId
        $Group = $InputObject.Group
        $SenderId = $InputObject.SenderId
    }

    $Script:AsyncEvent = @{
        ClientId = $ClientId
        Group    = $Group
        SenderId = $SenderId
    }
}

function Get-PodeWebAsyncEvent {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return $Script:AsyncEvent
}

function New-PodeWebAsyncEvent {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([hashtable])]
    param(
        [Parameter(ParameterSetName = 'Default')]
        [string[]]
        $ClientId = $null,

        [Parameter(ParameterSetName = 'Default')]
        [string[]]
        $Group = $null,

        [Parameter(ParameterSetName = 'Default')]
        [string]
        $SenderId = $null,

        [Parameter(ParameterSetName = 'All')]
        [switch]
        $All
    )

    if ($All) {
        $ClientId = $null
        $Group = $null
        $SenderId = $null
    }

    return @{
        ClientId = $ClientId
        Group    = $Group
        SenderId = $SenderId
    }
}

function Export-PodeWebAsyncEvent {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        ClientId = $WebEvent.Sse.ClientId
        Group    = $WebEvent.Sse.Group
        SenderId = $WebEvent.Metadata.SenderId
    }
}
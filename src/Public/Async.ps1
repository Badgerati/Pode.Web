function Set-PodeWebAsyncEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]
        $InputObject
    )

    $Script:AsyncEvent = @{
        ClientId = $InputObject.ClientId
        Group    = $InputObject.Group
        SenderId = $InputObject.SenderId
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

function Set-PodeWebAsyncHeader {
    [CmdletBinding()]
    param()

    Set-PodeHeader -Name 'X-PODE-WEB-PROCESSING-ASYNC' -Value '1'
}
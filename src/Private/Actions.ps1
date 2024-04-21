function Send-PodeWebAction {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Value,

        [switch]
        $PassThru
    )

    # for http, just return
    if (Test-PodeWebResponseType -Type Http) {
        return $Value
    }

    # otherwise, we're dealing with SSE; get clientId/group
    $ClientId = Get-PodeWebSseClientId
    $Group = Get-PodeWebSseGroup

    # inject senderId
    $SenderId = Get-PodeWebSenderId
    if (![string]::IsNullOrEmpty($SenderId)) {
        $Value['SenderId'] = $SenderId
    }

    # send over sse to client
    Send-PodeSseEvent `
        -Name 'Pode.Web.Actions' `
        -ClientId $ClientId `
        -Group $Group `
        -EventType 'pode.web.action' `
        -Data $Value

    # return the value if required
    if ($PassThru) {
        return $Value
    }
}

function Test-PodeWebActionsAsync {
    [OutputType([bool])]
    param()

    return !(Test-PodeWebResponseType -Type Http)
}

function Get-PodeWebSseClientId {
    [OutputType([string[]])]
    param()

    if (![string]::IsNullOrEmpty($WebEvent.Sse.ClientId)) {
        return $WebEvent.Sse.ClientId
    }

    return $Script:AsyncEvent.ClientId
}

function Get-PodeWebSseGroup {
    [OutputType([string[]])]
    param()

    if (![string]::IsNullOrEmpty($WebEvent.Sse.Group)) {
        return $WebEvent.Sse.Group
    }

    return $Script:AsyncEvent.Group
}

function Get-PodeWebSenderId {
    [OutputType([string])]
    param()

    if (![string]::IsNullOrEmpty($WebEvent.Metadata.SenderId)) {
        return $WebEvent.Metadata.SenderId
    }

    return $Script:AsyncEvent.SenderId
}
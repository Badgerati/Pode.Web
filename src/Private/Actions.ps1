function Send-PodeWebAction {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Value,

        [switch]
        $PassThru
    )

    # check for clientId header
    #TODO: how to do this for actions called within an async Task or Timer?
    $clientId = Get-PodeHeader -Name 'X-PODE-CLIENTID'

    # if no clientId, just return, otherwise we're using sse
    if ([string]::IsNullOrEmpty($clientId)) {
        return $Value
    }

    #TODO: how to get "ConnectionId" header? similar problem to Tasks above

    # inject connectionId
    $connId = Get-PodeHeader -Name 'X-PODE-WEB-CONNECTION-ID'
    if (![string]::IsNullOrEmpty($connId)) {
        $Value['ConnectionId'] = Get-PodeHeader -Name 'X-PODE-WEB-CONNECTION-ID'
    }

    # send over sse to client
    Send-PodeSseMessage `
        -Name 'Pode.Web.Actions' `
        -ClientId $clientId `
        -EventType 'pode.web.action' `
        -Data $Value

    if ($PassThru) {
        return $Value
    }
}

function Test-PodeWebAsyncActions {
    [CmdletBinding()]
    param()

    return ![string]::IsNullOrEmpty((Get-PodeHeader -Name 'X-PODE-CLIENTID'))
}
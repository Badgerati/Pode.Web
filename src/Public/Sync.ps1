function Sync-PodeWebTable
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Id
    )

    return @{
        Operation = 'Sync'
        ElementType = 'Table'
        ID = $Id
    }
}
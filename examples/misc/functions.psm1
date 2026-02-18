function Get-Noun {
    [CmdletBinding()]
    param (
        [String]$V1
    )

    return "Ok = $V1"
}

function Get-CustomObject {
    [CmdletBinding()]
    param (
        [String]$V1
    )

    return [PSCustomObject]@{
        Ok = $V1
    }
}
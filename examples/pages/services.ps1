Add-PodeWebPage -Name Services -Icon Activity -ScriptBlock {
    New-PodeWebForm -Name 'Search' -AsCard -ScriptBlock {
        Get-Service -Name $WebEvent.Data.Name -ErrorAction Ignore | Select-Object DisplayName, Name, Status | Out-PodeWebTextbox -Multiline -Preformat -AsJson
    } -Content @(
        New-PodeWebTextbox -Name 'Name'
    )
}
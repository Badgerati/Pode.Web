Add-PodeWebPage -Name Services -Icon Activity -ScriptBlock {
    New-PodeWebForm -Name 'Search' -AsCard -ScriptBlock {
        Get-Service -Name $WebEvent.Data.Name -ErrorAction Ignore |
            Select-Object DisplayName, Name, Status |
            New-PodeWebTextbox -Name 'Output' -Multiline -Preformat -AsJson |
            Out-PodeWebElement
    } -Content @(
        New-PodeWebTextbox -Name 'Name'
    )
}
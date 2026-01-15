# root path
$root = Split-Path -Parent -Path $MyInvocation.MyCommand.Path

try {
    # load binaries
    Add-Type -AssemblyName System.Web
    Add-Type -AssemblyName System.Net.Http

    # stop ansi colours in ps7.2+
    if ($PSVersionTable.PSVersion -ge [version]'7.2.0') {
        $PSStyle.OutputRendering = 'PlainText'
    }

    # import everything if in a runspace
    if ($PODE_SCOPE_RUNSPACE) {
        $sysFuncs = Get-ChildItem Function:
        $sysAliases = Get-ChildItem Alias:
    }

    # load private functions
    Get-ChildItem "$($root)/Private/*.ps1" | Resolve-Path | ForEach-Object { . $_ }

    # only import public functions/aliases if not in a runspace
    if (!$PODE_SCOPE_RUNSPACE) {
        $sysFuncs = Get-ChildItem Function:
        $sysAliases = Get-ChildItem Alias:
    }

    # load public functions
    Get-ChildItem "$($root)/Public/*.ps1" | Resolve-Path | ForEach-Object { . $_ }

    # get functions/aliases from memory and compare to existing to find new functions added
    $funcs = Get-ChildItem Function: | Where-Object { $sysFuncs -notcontains $_ }
    $aliases = Get-ChildItem Alias: | Where-Object { $sysAliases -notcontains $_ }

    # export the module's public functions/aliases
    if ($funcs) {
        if ($aliases) {
            Export-ModuleMember -Function $funcs.Name -Alias $aliases.Name
        }
        else {
            Export-ModuleMember -Function $funcs.Name
        }
    }
}
catch {
    throw "Failed to load the Pode.Web module: $($_.Exception.Message)`n$($_.Exception.StackTrace)"
}
finally {
    Remove-Variable -ErrorAction SilentlyContinue -Name @(
        'root',
        'sysFuncs',
        'sysAliases',
        'funcs',
        'aliases'
    )
}
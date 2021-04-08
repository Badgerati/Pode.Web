Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Basic Example' -Theme Dark

    Add-PodeWebPage -Name Table -Icon Activity -NoBackArrow -ScriptBlock {
        $value = $WebEvent.Query['value']
        $base = $WebEvent.Query['base']
        $path = (Join-PodeWebPath -Path $base -ChildPath $value -ReplaceSlashes)

        $text = (@{
            'File-1-0' = (New-PodeWebCodeBlock -Value 'Hello, world')
            'Folder-1-0/Folder-2-0/File-3-0' = (New-PodeWebCodeBlock -Value 'Hello, there')
        })[$path]

        if ($null -ne $text) {
            return (New-PodeWebCard -Name 'FileData' -NoTitle -Content $text)
        }

        New-PodeWebCard -Name 'TableData' -NoTitle -Content @(
            New-PodeWebTable -Name 'Table' -Click -DataColumn Name -ScriptBlock {
                $value = $WebEvent.Query['value']
                $base = $WebEvent.Query['base']

                if ([string]::IsNullOrWhiteSpace($value) -and [string]::IsNullOrWhiteSpace($base)) {
                    return @(
                        @{ Name = 'Folder-1-0'; Type = 'Folder' },
                        @{ Name = 'File-1-0'; Type = 'File' }
                    )
                }

                $path = (Join-PodeWebPath -Path $base -ChildPath $value -ReplaceSlashes)

                return (@{
                    'Folder-1-0' = @(@{ Name = 'Folder-2-0'; Type = 'Folder' })
                    'Folder-1-0/Folder-2-0' = @(@{ Name = 'File-3-0'; Type = 'File' })
                })[$path]
            }
        )
    }

}
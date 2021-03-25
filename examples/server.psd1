@{
    Server = @{
        AutoImport = @{
            Modules = @{
                Enable = $true
                ExportOnly = $true
            }
        }
    }
    Web = @{
        Static = @{
            Cache = @{
                Enable = $true
            }
        }
    }
}
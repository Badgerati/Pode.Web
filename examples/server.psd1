@{
    Server = @{
        Request = @{
            Timeout = 600
        }
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
function New-PodeWebTable
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [string]
        $Message,

        [Parameter()]
        [string]
        $DataColumn,

        [Parameter()]
        [scriptblock]
        $ScriptBlock,

        [switch]
        $Filter,

        [switch]
        $Sort,

        [switch]
        $NoExport,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [switch]
        $AutoRefresh,

        [switch]
        $NoHeader
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "table_$($Name)_$(Get-PodeWebRandomName)" -replace '\s+', '_'
    }

    $component = @{
        ComponentType = 'Table'
        Name = $Name
        ID = $Id
        DataColumn = $DataColumn
        Message = $Message
        Filter = $Filter.IsPresent
        Sort = $Sort.IsPresent
        IsDynamic = ($null -ne $ScriptBlock)
        NoExport = $NoExport.IsPresent
        AutoRefresh = $AutoRefresh.IsPresent
        NoHeader = $NoHeader.IsPresent
    }

    if ($null -ne $ScriptBlock) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        $routePath = "/components/table/$($Id)"
        Remove-PodeRoute -Method Post -Path $routePath

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ScriptBlock {
            $global:ComponentData = $using:component

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Return
            if ($null -eq $result) {
                $result = @()
            }

            if (($result.Length -gt 0) -and [string]::IsNullOrWhiteSpace($result[0].OutputType)) {
                $result = ($result | Out-PodeWebTable -Id $using:Id)
            }

            Write-PodeJsonResponse -Value $result
        }
    }

    return $component
}

function New-PodeWebForm
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [string]
        $Message,

        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Elements,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [switch]
        $NoHeader
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "form_$($Name)_$(Get-PodeWebRandomName)" -replace '\s+', '_'
    }

    $auth = $null
    if (!$NoAuthentication) {
        $auth = (Get-PodeWebState -Name 'auth')
    }

    Add-PodeRoute -Method Post -Path "/components/form/$($Id)" -Authentication $auth -ScriptBlock {
        $global:InputData = $WebEvent.Data
        $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Return
        if ($null -eq $result) {
            $result = @()
        }

        Write-PodeJsonResponse -Value $result
    }

    return @{
        ComponentType = 'Form'
        Name = $Name
        ID = $Id
        Message = $Message
        Elements = $Elements
        NoHeader = $NoHeader.IsPresent
    }
}

function New-PodeWebSection
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Elements,

        [switch]
        $NoHeader
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        $Name = Get-PodeWebRandomName
    }

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "section_$($Name)_$(Get-PodeWebRandomName)" -replace '\s+', '_'
    }

    return @{
        ComponentType = 'Section'
        Name = $Name
        ID = $Id
        Elements = $Elements
        NoHeader = $NoHeader.IsPresent
    }
}

function New-PodeWebChart
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [string]
        $Message,

        [Parameter()]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [ValidateSet('line', 'pie', 'doughnut', 'bar')]
        [string]
        $Type = 'line',

        [Parameter()]
        [int]
        $MaxItems = 0,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [switch]
        $Append,

        [switch]
        $TimeLabels,

        [switch]
        $AutoRefresh,

        [switch]
        $NoHeader
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "chart_$($Name)_$(Get-PodeWebRandomName)" -replace '\s+', '_'
    }

    if ($MaxItems -lt 0) {
        $MaxItems = 0
    }

    if ($null -ne $ScriptBlock) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path "/components/chart/$($Id)" -Authentication $auth -ScriptBlock {
            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Return
            if ($null -eq $result) {
                $result = @()
            }

            if (($result.Length -gt 0) -and [string]::IsNullOrWhiteSpace($result[0].OutputType)) {
                $result = ($result | Out-PodeWebChart -Id $using:Id)
            }

            Write-PodeJsonResponse -Value $result
        }
    }

    return @{
        ComponentType = 'Chart'
        Name = $Name
        ID = $Id
        Message = $Message
        ChartType = $Type
        IsDynamic = ($null -ne $ScriptBlock)
        Append = $Append.IsPresent
        MaxItems = $MaxItems
        TimeLabels = $TimeLabels.IsPresent
        AutoRefresh = $AutoRefresh.IsPresent
        NoHeader = $NoHeader.IsPresent
    }
}
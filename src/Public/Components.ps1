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
        [scriptblock]
        $ScriptBlock,

        [switch]
        $Filter,

        [switch]
        $NoExport,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [switch]
        $AutoRefresh
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "table_$($Name)_$(Get-PodeWebRandomName)"
    }

    if ($null -ne $ScriptBlock) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path "/components/table/$($Id)" -Authentication $auth -ScriptBlock {
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

    return @{
        ComponentType = 'Table'
        Name = $Name
        ID = $Id
        Message = $Message
        Filter = $Filter.IsPresent
        IsDynamic = ($null -ne $ScriptBlock)
        NoExport = $NoExport.IsPresent
        AutoRefresh = $AutoRefresh.IsPresent
    }
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
        $Controls,

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
        $Id = "form_$($Name)_$(Get-PodeWebRandomName)"
    }

    $auth = $null
    if (!$NoAuthentication) {
        $auth = (Get-PodeWebState -Name 'auth')
    }

    Add-PodeRoute -Method Post -Path "/components/form/$($Id)" -Authentication $auth -ScriptBlock {
        $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $WebEvent.Data -Splat -Return
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
        Controls = $Controls
        ScriptBlock = $ScriptBlock
        NoHeader = $NoHeader.IsPresent
    }
}

function New-PodeWebSection
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Controls,

        [switch]
        $NoHeader
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "section_$($Name)_$(Get-PodeWebRandomName)"
    }

    return @{
        ComponentType = 'Section'
        Name = $Name
        ID = $Id
        Controls = $Controls
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
        $AutoRefresh
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "chart_$($Name)_$(Get-PodeWebRandomName)"
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
    }
}

function New-PodeWebGrid
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable[]]
        $Components,

        [switch]
        $Vertical
    )

    return @{
        ComponentType = 'Grid'
        Components = $Components
        Vertical = $Vertical.IsPresent
    }
}
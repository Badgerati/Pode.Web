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
        [hashtable[]]
        $Columns,

        [Parameter(ParameterSetName='Dynamic')]
        [scriptblock]
        $ScriptBlock,

        [Parameter(ParameterSetName='Dynamic')]
        [object[]]
        $ArgumentList,

        [Parameter(ParameterSetName='Csv')]
        [string]
        $CsvFilePath,

        [Parameter(ParameterSetName='Dynamic')]
        [Parameter(ParameterSetName='Csv')]
        [int]
        $PageAmount = 20,

        [switch]
        $Filter,

        [switch]
        $Sort,

        [switch]
        $Click,

        [Parameter(ParameterSetName='Dynamic')]
        [Parameter(ParameterSetName='Csv')]
        [switch]
        $Paginate,

        [switch]
        $NoExport,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [Parameter(ParameterSetName='Dynamic')]
        [Parameter(ParameterSetName='Csv')]
        [switch]
        $AutoRefresh,

        [switch]
        $NoHeader
    )

    $Id = Get-PodeWebElementId -Tag Table -Id $Id -Name $Name

    if (![string]::IsNullOrWhiteSpace($CsvFilePath) -and $CsvFilePath.StartsWith('.')) {
        $CsvFilePath = Join-Path (Get-PodeServerPath) $CsvFilePath
    }

    $component = @{
        ComponentType = 'Table'
        Name = $Name
        ID = $Id
        DataColumn = $DataColumn
        Columns = $Columns
        Message = $Message
        Filter = $Filter.IsPresent
        Sort = $Sort.IsPresent
        Click = $Click.IsPresent
        IsDynamic = ($PSCmdlet.ParameterSetName -iin @('dynamic', 'csv'))
        NoExport = $NoExport.IsPresent
        AutoRefresh = $AutoRefresh.IsPresent
        NoHeader = $NoHeader.IsPresent
        Paging = @{
            Enabled = $Paginate.IsPresent
            Amount = $PageAmount
        }
    }

    $routePath = "/components/table/$($Id)"
    $buildRoute = (($null -ne $ScriptBlock) -or ![string]::IsNullOrWhiteSpace($CsvFilePath))

    if ($buildRoute -and !(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -ScriptBlock {
            param($Data)
            $global:ComponentData = $using:component

            $csvFilePath = $using:CsvFilePath
            if ([string]::IsNullOrWhiteSpace($csvFilePath)) {
                $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            }
            else {
                $result = Import-Csv -Path $csvFilePath
            }

            if ($null -eq $result) {
                $result = @()
            }

            if (($result.Length -gt 0) -and [string]::IsNullOrWhiteSpace($result[0].OutputType)) {
                $paginate = $ComponentData.Paging.Enabled
                $result = ($result | Out-PodeWebTable -Id $using:Id -Columns $ComponentData.Columns -Paginate:$paginate)
            }

            Write-PodeJsonResponse -Value $result
            $global:ComponentData = $null
        }
    }

    return $component
}

function Initialize-PodeWebTableColumn
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Key,

        [Parameter()]
        [int]
        $Width = 0
    )

    return @{
        Key = $Key
        Width = $Width
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
        $Elements,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [object[]]
        $ArgumentList,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [switch]
        $NoHeader
    )

    # ensure elements are correct
    foreach ($element in $Elements) {
        if ([string]::IsNullOrWhiteSpace($element.ElementType)) {
            throw "Invalid element supplied: $($element)"
        }
    }

    $Id = Get-PodeWebElementId -Tag Form -Id $Id -Name $Name

    $routePath = "/components/form/$($Id)"
    if (!(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -ScriptBlock {
            param($Data)

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            Write-PodeJsonResponse -Value $result
        }
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

function New-PodeWebTimer
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
        [int]
        $Interval = 60,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [object[]]
        $ArgumentList,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    $Id = Get-PodeWebElementId -Tag Timer -Id $Id -Name $Name

    if ($Interval -lt 10) {
        $Interval = 10
    }

    $routePath = "/components/timer/$($Id)"
    if (!(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -ScriptBlock {
            param($Data)

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            Write-PodeJsonResponse -Value $result
        }
    }

    return @{
        ComponentType = 'Timer'
        Name = $Name
        ID = $Id
        Interval = ($Interval * 1000)
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

    # ensure elements are correct
    foreach ($element in $Elements) {
        if ([string]::IsNullOrWhiteSpace($element.ElementType)) {
            throw "Invalid element supplied: $($element)"
        }
    }

    $Id = Get-PodeWebElementId -Tag Section -Id $Id -Name $Name -NameAsToken

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

        [Parameter(Mandatory=$true)]
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
        [int]
        $Height = 0,

        [Parameter()]
        [object[]]
        $ArgumentList,

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

    $Id = Get-PodeWebElementId -Tag Chart -Id $Id -Name $Name

    if ($MaxItems -lt 0) {
        $MaxItems = 0
    }

    $routePath = "/components/chart/$($Id)"
    if (!(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -ScriptBlock {
            param($Data)

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
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
        Height = $Height
        TimeLabels = $TimeLabels.IsPresent
        AutoRefresh = $AutoRefresh.IsPresent
        NoHeader = $NoHeader.IsPresent
    }
}

function New-PodeWebModal
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
        [hashtable[]]
        $Elements,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $SubmitText = 'Submit',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $CloseText = 'Close',

        [Parameter()]
        [ValidateSet('Small', 'Medium', 'Large')]
        [string]
        $Size = 'Small',

        [Parameter()]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [object[]]
        $ArgumentList,

        [switch]
        $Form,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    # ensure elements are correct
    foreach ($element in $Elements) {
        if ([string]::IsNullOrWhiteSpace($element.ElementType)) {
            throw "Invalid element supplied: $($element)"
        }
    }

    $Id = Get-PodeWebElementId -Tag Modal -Id $Id -Name $Name

    $routePath = "/components/modal/$($Id)"
    if (($null -ne $ScriptBlock) -and !(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -ScriptBlock {
            param($Data)

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            Write-PodeJsonResponse -Value $result
        }
    }

    return @{
        ComponentType = 'Modal'
        Name = $Name
        ID = $Id
        Elements = $Elements
        CloseText = $CloseText
        SubmitText = $SubmitText
        Size = $Size
        Form = $Form.IsPresent
        ShowSubmit = ($null -ne $ScriptBlock)
    }
}

function New-PodeWebCounterChart
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Counter,

        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        $Name = Split-Path -Path $Counter -Leaf
    }

    New-PodeWebChart `
        -Name $Name `
        -Type Line `
        -MaxItems 30 `
        -ArgumentList $Counter `
        -Append `
        -TimeLabels `
        -AutoRefresh `
        -NoAuthentication:$NoAuthentication `
        -ScriptBlock {
            param($counter)
            @{
                Value = ((Get-Counter -Counter $counter -SampleInterval 1 -MaxSamples 2).CounterSamples.CookedValue | Measure-Object -Average).Average
            }
        }
}
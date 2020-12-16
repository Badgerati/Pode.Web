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

        [Parameter(ParameterSetName='Dynamic')]
        [int]
        $PageAmount = 20,

        [switch]
        $Filter,

        [switch]
        $Sort,

        [switch]
        $Click,

        [Parameter(ParameterSetName='Dynamic')]
        [switch]
        $Paginate,

        [switch]
        $NoExport,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [Parameter(ParameterSetName='Dynamic')]
        [switch]
        $AutoRefresh,

        [switch]
        $NoHeader
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "table_$(Protect-PodeWebName -Name $Name)_$(Get-PodeWebRandomName)" -replace '\s+', '_'
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
        IsDynamic = ($null -ne $ScriptBlock)
        NoExport = $NoExport.IsPresent
        AutoRefresh = $AutoRefresh.IsPresent
        NoHeader = $NoHeader.IsPresent
        Paging = @{
            Enabled = $Paginate.IsPresent
            Amount = $PageAmount
        }
    }

    if ($null -ne $ScriptBlock) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        $routePath = "/components/table/$($Id)"
        Remove-PodeRoute -Method Post -Path $routePath

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -ScriptBlock {
            param($Data)
            $global:ComponentData = $using:component

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            if (($result.Length -gt 0) -and [string]::IsNullOrWhiteSpace($result[0].OutputType)) {
                $pageNumber = 0
                $pageAmount = 0

                if ($ComponentData.Paging.Enabled) {
                    $pageNumber = [int]$WebEvent.Data['PageNumber']
                    $pageAmount = [int]$WebEvent.Data['PageAmount']

                    if ($pageNumber -le 0) {
                        $pageNumber = 1
                        $pageAmount = $ComponentData.Paging.Amount
                    }
                }

                $result = ($result | Out-PodeWebTable -Id $using:Id -Columns $ComponentData.Columns -PageNumber $pageNumber -PageAmount $pageAmount)
            }

            Write-PodeJsonResponse -Value $result
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

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "form_$(Protect-PodeWebName -Name $Name)_$(Get-PodeWebRandomName)" -replace '\s+', '_'
    }

    $auth = $null
    if (!$NoAuthentication) {
        $auth = (Get-PodeWebState -Name 'auth')
    }

    Add-PodeRoute -Method Post -Path "/components/form/$($Id)" -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -ScriptBlock {
        param($Data)
        $global:InputData = $WebEvent.Data

        $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
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

    # ensure elements are correct
    foreach ($element in $Elements) {
        if ([string]::IsNullOrWhiteSpace($element.ElementType)) {
            throw "Invalid element supplied: $($element)"
        }
    }

    if ([string]::IsNullOrWhiteSpace($Name)) {
        $Name = Get-PodeWebRandomName
    }

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "section_$(Protect-PodeWebName -Name $Name)_$(Get-PodeWebRandomName)" -replace '\s+', '_'
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

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "chart_$(Protect-PodeWebName -Name $Name)_$(Get-PodeWebRandomName)" -replace '\s+', '_'
    }

    if ($MaxItems -lt 0) {
        $MaxItems = 0
    }

    $auth = $null
    if (!$NoAuthentication) {
        $auth = (Get-PodeWebState -Name 'auth')
    }

    Add-PodeRoute -Method Post -Path "/components/chart/$($Id)" -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -ScriptBlock {
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

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "modal_$(Protect-PodeWebName -Name $Name)_$(Get-PodeWebRandomName)" -replace '\s+', '_'
    }

    $auth = $null
    if (!$NoAuthentication) {
        $auth = (Get-PodeWebState -Name 'auth')
    }

    if ($null -ne $ScriptBlock) {
        Add-PodeRoute -Method Post -Path "/components/modal/$($Id)" -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -ScriptBlock {
            param($Data)
            $global:InputData = $WebEvent.Data

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
                Value = ((Get-Counter -Counter $counter -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue | Measure-Object -Average).Average
            }
        }
}
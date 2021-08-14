function Out-PodeWebTable
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Data,

        [Parameter()]
        [hashtable[]]
        $Columns,

        [Parameter()]
        [switch]
        $Sort
    )

    begin {
        $items = @()
    }

    process {
        $items += $Data
    }

    end {
        # columns
        $_columns = @{}
        if (($null -ne $Columns) -and ($Columns.Length -gt 0)) {
            foreach ($col in $Columns) {
                $_columns[$col.Key] = $col
            }
        }

        # table output
        return @{
            Operation = 'Output'
            ElementType = 'Table'
            Data = $items
            Sort = $Sort.IsPresent
            Columns = $_columns
        }
    }
}

function Update-PodeWebTable
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Data,

        [Parameter(Mandatory=$true, ParameterSetName='ID_and_AutoPage')]
        [Parameter(Mandatory=$true, ParameterSetName='ID_and_DynamicPage')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name_and_AutoPage')]
        [Parameter(Mandatory=$true, ParameterSetName='Name_and_DynamicPage')]
        [string]
        $Name,

        [Parameter()]
        [hashtable[]]
        $Columns,

        [Parameter(ParameterSetName='ID_and_AutoPage')]
        [Parameter(ParameterSetName='Name_and_AutoPage')]
        [switch]
        $Paginate,

        [Parameter(Mandatory=$true, ParameterSetName='ID_and_DynamicPage')]
        [Parameter(Mandatory=$true, ParameterSetName='Name_and_DynamicPage')]
        [int]
        $PageIndex,

        [Parameter(Mandatory=$true, ParameterSetName='ID_and_DynamicPage')]
        [Parameter(Mandatory=$true, ParameterSetName='Name_and_DynamicPage')]
        [int]
        $TotalItemCount
    )

    begin {
        $items = @()
    }

    process {
        $items += $Data
    }

    end {
        # columns
        $_columns = @{}
        if (($null -ne $Columns) -and ($Columns.Length -gt 0)) {
            foreach ($col in $Columns) {
                $_columns[$col.Key] = $col
            }
        }

        # paging
        $maxPages = 0
        $totalItems = 0
        $pageSize = 20

        # - is table paginated?
        if ($Paginate -or (($PageIndex -gt 0) -and ($TotalItemCount -gt 0))) {
            if ($null -ne $ElementData) {
                if (!$ElementData.Paging.Enabled) {
                    throw "You cannot paginate a table that does not have paging enabled: $($ElementData.ID)"
                }

                $pageSize = $ElementData.Paging.Size
            }

            if (![string]::IsNullOrWhiteSpace($WebEvent.Data['PageSize'])) {
                $pageSize = [int]$WebEvent.Data['PageSize']
            }
        }

        # - auto-paging
        if ($Paginate) {
            $pageIndex = 1
            $totalItems = $items.Length

            if ($null -ne $WebEvent) {
                $_index = [int]$WebEvent.Data['PageIndex']

                if ($_index -gt 0) {
                    $pageIndex = $_index
                }
            }

            $maxPages = [int][math]::Ceiling(($totalItems / $pageSize))
            if ($pageIndex -gt $maxPages) {
                $pageIndex = $maxPages
            }

            $items = $items[(($pageIndex - 1) * $pageSize) .. (($pageIndex * $pageSize) - 1)]
        }

        # - dynamic paging
        elseif (($PageIndex -gt 0) -and ($TotalItemCount -gt 0)) {
            $totalItems = $TotalItemCount

            $maxPages = [int][math]::Ceiling(($totalItems / $pageSize))
            if ($pageIndex -gt $maxPages) {
                $pageIndex = $maxPages
            }

            if ($items.Length -gt $pageSize) {
                $items = $items[0 .. ($pageSize - 1)]
            }
        }

        # table output
        return @{
            Operation = 'Update'
            ElementType = 'Table'
            Data = $items
            ID = $Id
            Name = $Name
            Columns = $_columns
            Paging = @{
                Index = $pageIndex
                Size = $pageSize
                Total = $totalItems
                Max = $maxPages
            }
        }
    }
}

function Sync-PodeWebTable
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name
    )

    return @{
        Operation = 'Sync'
        ElementType = 'Table'
        ID = $Id
        Name = $Name
    }
}

function Clear-PodeWebTable
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name
    )

    return @{
        Operation = 'Clear'
        ElementType = 'Table'
        ID = $Id
        Name = $Name
    }
}

function Update-PodeWebTableRow
{
    [CmdletBinding(DefaultParameterSetName='Name_and_DataValue')]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Data,

        [Parameter(Mandatory=$true, ParameterSetName='ID_and_DataValue')]
        [Parameter(Mandatory=$true, ParameterSetName='ID_and_Index')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name_and_DataValue')]
        [Parameter(Mandatory=$true, ParameterSetName='Name_and_Index')]
        [string]
        $Name,

        [Parameter(Mandatory=$true, ParameterSetName='ID_and_DataValue')]
        [Parameter(Mandatory=$true, ParameterSetName='Name_and_DataValue')]
        [string]
        $DataValue,

        [Parameter(Mandatory=$true, ParameterSetName='ID_and_Index')]
        [Parameter(Mandatory=$true, ParameterSetName='Name_and_Index')]
        [int]
        $Index
    )

    return @{
        Operation = 'Update'
        ElementType = 'TableRow'
        ID = $Id
        Name = $Name
        Row = @{
            Type = $PSCmdlet.ParameterSetName.ToLowerInvariant()
            DataValue = $DataValue
            Index = $Index
        }
        Data = $Data
    }
}

function Out-PodeWebChart
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Data,

        [Parameter()]
        [ValidateSet('line', 'pie', 'doughnut', 'bar')]
        [string]
        $Type = 'line'
    )

    begin {
        $items = @()
    }

    process {
        if ($Data.Values -isnot [array]) {
            if ($Data.Values -is [hashtable]) {
                $Data.Values = @($Data.Values)
            }
            else {
                $Data.Values = @(@{
                    Key = 'Default'
                    Value = $Data.Values
                })
            }
        }

        $items += $Data
    }

    end {
        return @{
            Operation = 'Output'
            ElementType = 'Chart'
            Data = $items
            ChartType = $Type
        }
    }
}

function Update-PodeWebChart
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Data,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id
    )

    begin {
        $items = @()
    }

    process {
        if ($Data.Values -isnot [array]) {
            if ($Data.Values -is [hashtable]) {
                $Data.Values = @($Data.Values)
            }
            else {
                $Data.Values = @(@{
                    Key = 'Default'
                    Value = $Data.Values
                })
            }
        }

        $items += $Data
    }

    end {
        return @{
            Operation = 'Update'
            ElementType = 'Chart'
            Data = $items
            ID = $Id
            Name = $Name
        }
    }
}

function ConvertTo-PodeWebChartData
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Data,

        [Parameter(Mandatory=$true)]
        [Alias('Label')]
        [string]
        $LabelProperty,

        [Parameter(Mandatory=$true)]
        [Alias('Dataset')]
        [string[]]
        $DatasetProperty
    )

    begin {
        $items = @()
    }

    process {
        $items += $Data
    }

    end {
        foreach ($item in $items) {
            @{
                Key = $item.$LabelProperty
                Values = @(foreach ($prop in $DatasetProperty) {
                    @{
                        Key = $prop
                        Value = $item.$prop
                    }
                })
            }
        }
    }
}

function Sync-PodeWebChart
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name
    )

    return @{
        Operation = 'Sync'
        ElementType = 'Chart'
        ID = $Id
        Name = $Name
    }
}

function Clear-PodeWebChart
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name
    )

    return @{
        Operation = 'Clear'
        ElementType = 'Chart'
        ID = $Id
        Name = $Name
    }
}

function Out-PodeWebTextbox
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [Alias('Data')]
        $Value,

        [Parameter()]
        [Alias('Height')]
        [int]
        $Size = 10,

        [Parameter()]
        [switch]
        $AsJson,

        [Parameter()]
        [switch]
        $Multiline,

        [Parameter()]
        [switch]
        $Preformat,

        [Parameter()]
        [switch]
        $ReadOnly
    )

    begin {
        $items = @()
    }

    process {
        $items += $Value
    }

    end {
        if (!$AsJson) {
            $items = ($items | Out-String)
        }

        if ($Size -le 0) {
            $Size = 10
        }

        return @{
            Operation = 'Output'
            ElementType = 'Textbox'
            Value = $items
            AsJson = $AsJson.IsPresent
            Multiline = $Multiline.IsPresent
            Size = $Size
            Preformat = $Preformat.IsPresent
            ReadOnly = $ReadOnly.IsPresent
        }
    }
}

function Update-PodeWebTextbox
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [Alias('Data')]
        $Value,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter()]
        [switch]
        $AsJson,

        [Parameter()]
        [switch]
        $Multiline
    )

    begin {
        $items = @()
    }

    process {
        $items += $Value
    }

    end {
        if (!$AsJson) {
            $items = ($items | Out-String)
        }

        return @{
            Operation = 'Update'
            ElementType = 'Textbox'
            Value = $items
            ID = $Id
            Name = $Name
            AsJson = $AsJson.IsPresent
            Multiline = $Multiline.IsPresent
        }
    }
}

function Clear-PodeWebTextbox
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter()]
        [switch]
        $Multiline
    )

    return @{
        Operation = 'Clear'
        ElementType = 'Textbox'
        ID = $Id
        Name = $Name
        Multiline = $Multiline.IsPresent
    }
}

function Show-PodeWebToast
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Message,

        [Parameter()]
        [string]
        $Title = 'Message',

        [Parameter()]
        [int]
        $Duration = 3000,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Icon = 'information'
    )

    if ($Duration -le 0) {
        $Duration = 3000
    }

    return @{
        Operation = 'Show'
        ElementType = 'Toast'
        Message = [System.Net.WebUtility]::HtmlEncode($Message)
        Title = [System.Net.WebUtility]::HtmlEncode($Title)
        Duration = $Duration
        Icon = $Icon
    }
}

function Out-PodeWebValidation
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Message
    )

    return @{
        Operation = 'Output'
        ElementType = 'Validation'
        Name = $Name
        ID = $Id
        Message = [System.Net.WebUtility]::HtmlEncode($Message)
    }
}

function Reset-PodeWebForm
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id
    )

    return @{
        Operation = 'Reset'
        ElementType = 'Form'
        ID = $Id
        Name = $Name
    }
}

function Update-PodeWebText
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]
        $Value
    )

    return @{
        Operation = 'Update'
        ElementType = 'Text'
        ID = $Id
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
    }
}

function Set-PodeWebSelect
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]
        $Value
    )

    return @{
        Operation = 'Set'
        ElementType = 'Select'
        Name = $Name
        ID = $Id
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
    }
}

function Update-PodeWebSelect
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string[]]
        $Options
    )

    begin {
        $items = @()
    }

    process {
        $items += $Options
    }

    end {
        return @{
            Operation = 'Update'
            ElementType = 'Select'
            Name = $Name
            ID = $Id
            Options = $items
        }
    }
}

function Clear-PodeWebSelect
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id
    )

    return @{
        Operation = 'Clear'
        ElementType = 'Select'
        Name = $Name
        ID = $Id
    }
}

function Sync-PodeWebSelect
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id
    )

    return @{
        Operation = 'Sync'
        ElementType = 'Select'
        Name = $Name
        ID = $Id
    }
}

function Update-PodeWebBadge
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Id,

        [Parameter()]
        [string]
        $Value,

        [Parameter()]
        [ValidateSet('', 'Blue', 'Grey', 'Green', 'Red', 'Yellow', 'Cyan', 'Light', 'Dark')]
        [string]
        $Colour = ''
    )

    $colourType = Convert-PodeWebColourToClass -Colour $Colour

    return @{
        Operation = 'Update'
        ElementType = 'Badge'
        ID = $Id
        Colour = $Colour
        ColourType = $ColourType.ToLowerInvariant()
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
    }
}

function Update-PodeWebCheckbox
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter()]
        [int]
        $OptionId = 0,

        [Parameter()]
        [switch]
        $Checked
    )

    return @{
        Operation = 'Update'
        ElementType = 'Checkbox'
        ID = $Id
        Name = $Name
        OptionId = $OptionId
        Checked = $Checked.IsPresent
    }
}

function Show-PodeWebModal
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter()]
        [string]
        $DataValue,

        [Parameter()]
        [hashtable[]]
        $Actions
    )

    return @{
        Operation = 'Show'
        ElementType = 'Modal'
        ID = $Id
        Name = $Name
        DataValue = $DataValue
        Actions = $Actions
    }
}

function Hide-PodeWebModal
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(ParameterSetName='Name')]
        [string]
        $Name
    )

    return @{
        Operation = 'Hide'
        ElementType = 'Modal'
        ID = $Id
        Name = $Name
    }
}

function Out-PodeWebError
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Message
    )

    return @{
        Operation = 'Output'
        ElementType = 'Error'
        Message = $Message
    }
}

function Show-PodeWebNotification
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Title,

        [Parameter()]
        [string]
        $Body,

        [Parameter()]
        [string]
        $Icon
    )

    return @{
        Operation = 'Show'
        ElementType = 'Notification'
        Title = $Title
        Body = $Body
        Icon = $Icon
    }
}

function Move-PodeWebPage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Group,

        [Parameter()]
        [string]
        $DataValue,

        [switch]
        $NewTab
    )

    $page = ((Get-PodeWebPagePath -Name $Name -Group $Group) -replace '\s+', '+')

    if (![string]::IsNullOrWhiteSpace($DataValue)) {
        $page += "?Value=$($DataValue)"
    }

    return @{
        Operation = 'Move'
        ElementType = 'Href'
        Url = $page
        NewTab = $NewTab.IsPresent
    }
}

function Move-PodeWebUrl
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Url,

        [switch]
        $NewTab
    )

    return @{
        Operation = 'Move'
        ElementType = 'Href'
        Url = $Url
        NewTab = $NewTab.IsPresent
    }
}

function Move-PodeWebTab
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id
    )

    return @{
        Operation = 'Move'
        ElementType = 'Tab'
        ID = $Id
        Name = $Name
    }
}

function Move-PodeWebAccordion
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id
    )

    return @{
        Operation = 'Move'
        ElementType = 'Accordion'
        ID = $Id
        Name = $Name
    }
}

function Reset-PodeWebPage
{
    [CmdletBinding()]
    param()

    return @{
        Operation = 'Reset'
        ElementType = 'Page'
    }
}

function Out-PodeWebBreadcrumb
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable[]]
        $Items = @()
    )

    if (($null -eq $Items)) {
        $Items = @()
    }

    $foundActive = $false
    foreach ($item in $Items) {
        if ($foundActive -and $item.Active) {
            throw "Cannot have two active breadcrumb items"
        }

        $foundActive = $item.Active
    }

    return @{
        Operation = 'Output'
        ElementType = 'Breadcrumb'
        Items = $Items
    }
}

function Update-PodeWebProgress
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter()]
        [int]
        $Value = -1,

        [Parameter()]
        [ValidateSet('', 'Blue', 'Grey', 'Green', 'Red', 'Yellow', 'Cyan', 'Light', 'Dark')]
        [string]
        $Colour = ''
    )

    $colourType = Convert-PodeWebColourToClass -Colour $Colour

    return @{
        Operation = 'Update'
        ElementType = 'Progress'
        ID = $Id
        Name = $Name
        Colour = $Colour
        ColourType = $ColourType.ToLowerInvariant()
        Value = $Value
    }
}

function Update-PodeWebTile
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string]
        $Value,

        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter()]
        [ValidateSet('', 'Blue', 'Grey', 'Green', 'Red', 'Yellow', 'Cyan', 'Light', 'Dark')]
        [string]
        $Colour = ''
    )

    $colourType = Convert-PodeWebColourToClass -Colour $Colour

    return @{
        Operation = 'Update'
        ElementType = 'Tile'
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        ID = $Id
        Name = $Name
        Colour = $Colour
        ColourType = $ColourType.ToLowerInvariant()
    }
}

function Sync-PodeWebTile
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name
    )

    return @{
        Operation = 'Sync'
        ElementType = 'Tile'
        ID = $Id
        Name = $Name
    }
}

function Update-PodeWebTheme
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    if (!(Test-PodeWebTheme -Name $Name)) {
        throw "Theme does not exist: $($Name)"
    }

    return @{
        Operation = 'Update'
        ElementType = 'Theme'
        Name = $Name.ToLowerInvariant()
    }
}

function Reset-PodeWebTheme
{
    [CmdletBinding()]
    param()

    return @{
        Operation = 'Reset'
        ElementType = 'Theme'
    }
}
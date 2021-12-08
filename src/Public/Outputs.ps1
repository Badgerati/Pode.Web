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
            ObjectType = 'Table'
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

        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter()]
        [hashtable[]]
        $Columns,

        [Parameter()]
        [switch]
        $Paginate,

        [Parameter()]
        [int]
        $PageIndex,

        [Parameter()]
        [int]
        $TotalItemCount,

        [switch]
        $Force
    )

    begin {
        $items = @()
    }

    process {
        $items += $Data
    }

    end {
        # columns
        $_columns = [ordered]@{}
        if ((($null -eq $Columns) -or ($Columns.Length -eq 0)) -and ($null -ne $ElementData.Columns) -and ($ElementData.Columns.Length -gt 0)) {
            $Columns = $ElementData.Columns
        }

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
            if (!$Force -and ($null -ne $ElementData)) {
                if (!$ElementData.Paging.Enabled) {
                    throw "You cannot paginate a table that does not have paging enabled: $($ElementData.ID)"
                }

                $pageSize = $ElementData.Paging.Size
            }

            if (![string]::IsNullOrWhiteSpace($WebEvent.Data['PageSize'])) {
                $pageSize = [int]$WebEvent.Data['PageSize']
            }
        }

        # - dynamic paging
        if (($PageIndex -gt 0) -and ($TotalItemCount -gt 0)) {
            $totalItems = $TotalItemCount

            $maxPages = [int][math]::Ceiling(($totalItems / $pageSize))
            if ($pageIndex -gt $maxPages) {
                $pageIndex = $maxPages
            }

            if ($items.Length -gt $pageSize) {
                $items = $items[0 .. ($pageSize - 1)]
            }
        }

        # - auto-paging
        elseif ($Paginate) {
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

        # table output
        return @{
            Operation = 'Update'
            ObjectType = 'Table'
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
        ObjectType = 'Table'
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
        ObjectType = 'Table'
        ID = $Id
        Name = $Name
    }
}

function Update-PodeWebTableRow
{
    [CmdletBinding(DefaultParameterSetName='Name_and_DataValue')]
    param(
        [Parameter(ValueFromPipeline=$true)]
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
        $Index,

        [Parameter()]
        [string]
        $BackgroundColour,

        [Parameter()]
        [string]
        $Colour
    )

    return @{
        Operation = 'Update'
        ObjectType = 'TableRow'
        ID = $Id
        Name = $Name
        Row = @{
            Type = $PSCmdlet.ParameterSetName.ToLowerInvariant()
            DataValue = $DataValue
            Index = $Index
        }
        Data = $Data
        BackgroundColour = $BackgroundColour
        Colour = $Colour
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
            ObjectType = 'Chart'
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
            ObjectType = 'Chart'
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
        ObjectType = 'Chart'
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
        ObjectType = 'Chart'
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
            ObjectType = 'Textbox'
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
            ObjectType = 'Textbox'
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
        ObjectType = 'Textbox'
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
        ObjectType = 'Toast'
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
        ObjectType = 'Validation'
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
        ObjectType = 'Form'
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
        ObjectType = 'Text'
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
        ObjectType = 'Select'
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
        $Options,

        [Parameter()]
        [string[]]
        $DisplayOptions,

        [Parameter()]
        [string]
        $SelectedValue
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
            ObjectType = 'Select'
            Name = $Name
            ID = $Id
            Options = $items
            DisplayOptions = @(Protect-PodeWebValues -Value $DisplayOptions -Default $items -EqualCount)
            SelectedValue = [System.Net.WebUtility]::HtmlEncode($SelectedValue)
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
        ObjectType = 'Select'
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
        ObjectType = 'Select'
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
        ObjectType = 'Badge'
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
        [ValidateSet('Unchanged', 'Disabled', 'Enabled')]
        [string]
        $State = 'Unchanged',

        [Parameter()]
        [switch]
        $Checked
    )

    return @{
        Operation = 'Update'
        ObjectType = 'Checkbox'
        ID = $Id
        Name = $Name
        OptionId = $OptionId
        State = $State.ToLowerInvariant()
        Checked = $Checked.IsPresent
    }
}

function Enable-PodeWebCheckbox
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
        $OptionId = 0
    )

    return @{
        Operation = 'Enable'
        ObjectType = 'Checkbox'
        ID = $Id
        Name = $Name
        OptionId = $OptionId
    }
}

function Disable-PodeWebCheckbox
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
        $OptionId = 0
    )

    return @{
        Operation = 'Disable'
        ObjectType = 'Checkbox'
        ID = $Id
        Name = $Name
        OptionId = $OptionId
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
        ObjectType = 'Modal'
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
        ObjectType = 'Modal'
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
        ObjectType = 'Error'
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
        ObjectType = 'Notification'
        Title = $Title
        Body = $Body
        Icon = (Add-PodeWebAppPath -Url $Icon)
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
        ObjectType = 'Href'
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
        ObjectType = 'Href'
        Url = (Add-PodeWebAppPath -Url $Url)
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
        ObjectType = 'Tab'
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
        ObjectType = 'Accordion'
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
        ObjectType = 'Page'
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
        ObjectType = 'Breadcrumb'
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
        ObjectType = 'Progress'
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
        ObjectType = 'Tile'
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
        ObjectType = 'Tile'
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
        ObjectType = 'Theme'
        Name = $Name.ToLowerInvariant()
    }
}

function Reset-PodeWebTheme
{
    [CmdletBinding()]
    param()

    return @{
        Operation = 'Reset'
        ObjectType = 'Theme'
    }
}

function Show-PodeWebComponent
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Type,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name
    )

    return @{
        Operation = 'Show'
        ObjectType = 'Component'
        ID = $Id
        Type = $Type
        Name = $Name
    }
}

function Hide-PodeWebComponent
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Type,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name
    )

    return @{
        Operation = 'Hide'
        ObjectType = 'Component'
        ID = $Id
        Type = $Type
        Name = $Name
    }
}

function Set-PodeWebComponentStyle
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Type,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $Property,

        [Parameter()]
        [string]
        $Value
    )

    return @{
        Operation = 'Set'
        ObjectType = 'Component-Style'
        ID = $Id
        Type = $Type
        Name = $Name
        Property = $Property
        Value = $Value
    }
}

function Remove-PodeWebComponentStyle
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Type,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $Property
    )

    return @{
        Operation = 'Remove'
        ObjectType = 'Component-Style'
        ID = $Id
        Type = $Type
        Name = $Name
        Property = $Property
    }
}

function Add-PodeWebComponentClass
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Type,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $Class
    )

    return @{
        Operation = 'Add'
        ObjectType = 'Component-Class'
        ID = $Id
        Type = $Type
        Name = $Name
        Class = $Class
    }
}

function Remove-PodeWebComponentClass
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Type,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $Class
    )

    return @{
        Operation = 'Remove'
        ObjectType = 'Component-Class'
        ID = $Id
        Type = $Type
        Name = $Name
        Class = $Class
    }
}

function Start-PodeWebFileStream
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
        Operation = 'Start'
        ObjectType = 'FileStream'
        ID = $Id
        Name = $Name
    }
}

function Stop-PodeWebFileStream
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
        Operation = 'Stop'
        ObjectType = 'FileStream'
        ID = $Id
        Name = $Name
    }
}

function Restart-PodeWebFileStream
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
        Operation = 'Restart'
        ObjectType = 'FileStream'
        ID = $Id
        Name = $Name
    }
}

function Clear-PodeWebFileStream
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
        ObjectType = 'FileStream'
        ID = $Id
        Name = $Name
    }
}

function Update-PodeWebFileStream
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
        $Url
    )

    return @{
        Operation = 'Update'
        ObjectType = 'FileStream'
        ID = $Id
        Name = $Name
        Url = (Add-PodeWebAppPath -Url $Url)
    }
}

function Start-PodeWebAudio
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
        Operation = 'Start'
        ObjectType = 'Audio'
        ID = $Id
        Name = $Name
    }
}

function Stop-PodeWebAudio
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
        Operation = 'Stop'
        ObjectType = 'Audio'
        ID = $Id
        Name = $Name
    }
}

function Reset-PodeWebAudio
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
        Operation = 'Reset'
        ObjectType = 'Audio'
        ID = $Id
        Name = $Name
    }
}

function Update-PodeWebAudio
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
        [hashtable[]]
        $Source,

        [Parameter()]
        [hashtable[]]
        $Track
    )

    if (!(Test-PodeWebContent -Content $Source -ComponentType Element -ObjectType AudioSource)) {
        throw 'Audio sources can only contain AudioSource elements'
    }

    if (!(Test-PodeWebContent -Content $Track -ComponentType Element -ObjectType MediaTrack)) {
        throw 'Audio tracks can only contain MediaTrack elements'
    }

    return @{
        Operation = 'Update'
        ObjectType = 'Audio'
        ID = $Id
        Name = $Name
        Sources = $Source
        Tracks = $Track
    }
}

function Start-PodeWebVideo
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
        Operation = 'Start'
        ObjectType = 'Video'
        ID = $Id
        Name = $Name
    }
}

function Stop-PodeWebVideo
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
        Operation = 'Stop'
        ObjectType = 'Video'
        ID = $Id
        Name = $Name
    }
}

function Reset-PodeWebVideo
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
        Operation = 'Reset'
        ObjectType = 'Video'
        ID = $Id
        Name = $Name
    }
}

function Update-PodeWebVideo
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
        [hashtable[]]
        $Source,

        [Parameter()]
        [hashtable[]]
        $Track,

        [Parameter()]
        [string]
        $Thumbnail
    )

    if (!(Test-PodeWebContent -Content $Source -ComponentType Element -ObjectType VideoSource)) {
        throw 'Video sources can only contain VideoSource elements'
    }

    if (!(Test-PodeWebContent -Content $Track -ComponentType Element -ObjectType MediaTrack)) {
        throw 'Video tracks can only contain MediaTrack elements'
    }

    return @{
        Operation = 'Update'
        ObjectType = 'Video'
        ID = $Id
        Name = $Name
        Sources = $Source
        Tracks = $Track
        Thumbnail = $Thumbnail
    }
}

function Update-PodeWebCodeEditor
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
        $Value,

        [Parameter()]
        [string]
        $Language
    )

    return @{
        Operation = 'Update'
        ObjectType = 'Code-Editor'
        ID = $Id
        Name = $Name
        Value = $Value
        Language = $Language
    }
}

function Clear-PodeWebCodeEditor
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
        ObjectType = 'Code-Editor'
        ID = $Id
        Name = $Name
    }
}
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

function Hide-PodeWebTableColumn
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $Key
    )

    return @{
        Operation = 'Hide'
        ObjectType = 'Table'
        SubObjectType = 'Column'
        ID = $Id
        Name = $Name
        Key = $Key
    }
}

function Show-PodeWebTableColumn
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $Key
    )

    return @{
        Operation = 'Show'
        ObjectType = 'Table'
        SubObjectType = 'Column'
        ID = $Id
        Name = $Name
        Key = $Key
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
        ObjectType = 'Table'
        SubObjectType = 'Row'
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
        $JsonInline,

        [Parameter()]
        [ValidateSet('Unchanged', 'Disabled', 'Enabled')]
        [string]
        $ReadOnlyState = 'Unchanged',

        [Parameter()]
        [ValidateSet('Unchanged', 'Disabled', 'Enabled')]
        [string]
        $DisabledState = 'Unchanged'
    )

    begin {
        $items = @()
    }

    process {
        $items += $Value
    }

    end {
        if (!$AsJson -and ($items.Length -gt 0)) {
            $items = ($items | Out-String).Trim()
        }
        
        return @{
            Operation = 'Update'
            ObjectType = 'Textbox'
            Value = $items
            ID = $Id
            Name = $Name
            AsJson = $AsJson.IsPresent
            JsonInline = $JsonInline.IsPresent
            ReadOnlyState = $ReadOnlyState
            DisabledState = $DisabledState
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
        [object]
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
        Icon = (Protect-PodeWebIconType -Icon $Icon -Element 'Toast')
    }
}

function Show-PodeWebValidation
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
        Operation = 'Show'
        ObjectType = 'Element'
        SubObjectType = 'Validation'
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

function Submit-PodeWebForm
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
        Operation = 'Submit'
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
        [string[]]
        $SelectedValue,
        
        [Parameter()]
        [ValidateSet('Unchanged', 'Disabled', 'Enabled')]
        [string]
        $DisabledState = 'Unchanged'
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
            SelectedValue = @(Protect-PodeWebValues -Value $SelectedValue -Encode)
            DisabledState = $DisabledState
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
        ColourType = $ColourType
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
        $IconUrl
    )

    return @{
        Operation = 'Show'
        ObjectType = 'Notification'
        Title = $Title
        Body = $Body
        IconUrl = (Add-PodeWebAppPath -Url $IconUrl)
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

function Move-PodeWebTabs
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
        [ValidateSet('Next', 'Previous')]
        [string]
        $Direction = 'Next'
    )

    return @{
        Operation = 'Move'
        ObjectType = 'Tabs'
        ID = $Id
        Name = $Name
        Direction = $Direction.ToLowerInvariant()
    }
}

function Open-PodeWebTab
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
        Operation = 'Open'
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
        $Id,

        [Parameter()]
        [ValidateSet('Next', 'Previous')]
        [string]
        $Direction = 'Next'
    )

    return @{
        Operation = 'Move'
        ObjectType = 'Accordion'
        ID = $Id
        Name = $Name
        Direction = $Direction.ToLowerInvariant()
    }
}

function Close-PodeWebAccordion
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
        Operation = 'Close'
        ObjectType = 'Accordion'
        ID = $Id
        Name = $Name
    }
}

function Open-PodeWebBellow
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
        Operation = 'Open'
        ObjectType = 'Bellow'
        ID = $Id
        Name = $Name
    }
}

function Close-PodeWebBellow
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
        Operation = 'Close'
        ObjectType = 'Bellow'
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
        ColourType = $ColourType
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
        $Colour = '',

        [Parameter()]
        [object]
        $Icon
    )

    $colourType = Convert-PodeWebColourToClass -Colour $Colour

    return @{
        Operation = 'Update'
        ObjectType = 'Tile'
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        ID = $Id
        Name = $Name
        Colour = $Colour
        ColourType = $ColourType
        Icon = (Protect-PodeWebIconType -Icon $Icon -Element 'Tile')
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

function Show-PodeWebElement
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Element', ValueFromPipeline=$true)]
        [hashtable]
        $Element,

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

    # update element
    if ($null -ne $Element) {
        $Element.Visible = $false
        return $Element
    }

    # send frontend action
    else {
        return @{
            Operation = 'Show'
            ObjectType = 'Element'
            ID = $Id
            Type = $Type
            Name = $Name
        }
    }
}

function Hide-PodeWebElement
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Element', ValueFromPipeline=$true)]
        [hashtable]
        $Element,

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

    # update element
    if ($null -ne $Element) {
        $Element.Visible = $false
        return $Element
    }

    # send frontend action
    else {
        return @{
            Operation = 'Hide'
            ObjectType = 'Element'
            ID = $Id
            Type = $Type
            Name = $Name
        }
    }
}

function Add-PodeWebStyle
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Element', ValueFromPipeline=$true)]
        [hashtable]
        $Element,

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
        $Key,

        [Parameter()]
        [string]
        $Value
    )

    # update element
    if ($null -ne $Element) {
        if ($null -eq $Element.Css) {
            $Element.Css = @{}
        }

        if ($null -eq $Element.Css.Styles) {
            $Element.Css.Styles = @{}
        }

        $Element.Css.Styles[$key] = $Value
        return $Element
    }

    # send frontend action
    else {
        return @{
            Operation = 'Set'
            ObjectType = 'Element'
            SubObjectType = 'Style'
            ID = $Id
            Type = $Type
            Name = $Name
            Key = $Key
            Value = $Value
        }
    }
}

function Remove-PodeWebStyle
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Element', ValueFromPipeline=$true)]
        [hashtable]
        $Element,

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
        $Key
    )

    # update element
    if ($null -ne $Element) {
        if (($null -ne $Element.Css) -and ($null -ne $Element.Css.Styles)) {
            $null = $Element.Css.Styles.Remove($Key)
        }

        return $Element
    }

    # send frontend action
    else {
        return @{
            Operation = 'Remove'
            ObjectType = 'Element'
            SubObjectType = 'Style'
            ID = $Id
            Type = $Type
            Name = $Name
            Key = $Key
        }
    }
}

function Add-PodeWebClass
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Element', ValueFromPipeline=$true)]
        [hashtable]
        $Element,

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
        [string[]]
        $Value
    )

    # update element
    if ($null -ne $Element) {
        if ($null -eq $Element.Css) {
            $Element.Css = @{}
        }

        if ($null -eq $Element.Css.Classes) {
            $Element.Css.Classes = @()
        }

        $Element.Css.Classes = ($Element.Css.Classes + $Value) | Sort-Object -Unique
        return $Element
    }

    # send frontend action
    else {
        return @{
            Operation = 'Add'
            ObjectType = 'Element'
            SubObjectType = 'Class'
            ID = $Id
            Type = $Type
            Name = $Name
            Value = $Value
        }
    }
}

function Remove-PodeWebClass
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Element', ValueFromPipeline=$true)]
        [hashtable]
        $Element,

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
        [string[]]
        $Value
    )

    # update element
    if ($null -ne $Element) {
        if ($null -ne $Element.Css.Classes) {
            $Element.Css.Classes = $Element.Css.Classes | Where-Object { $_ -inotin $Value }
        }

        return $Element
    }

    # send frontend action
    else {
        return @{
            Operation = 'Remove'
            ObjectType = 'Element'
            SubObjectType = 'Class'
            ID = $Id
            Type = $Type
            Name = $Name
            Value = $Value
        }
    }
}

function Rename-PodeWebClass
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Element', ValueFromPipeline=$true)]
        [hashtable]
        $Element,

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
        $From,

        [Parameter(Mandatory=$true)]
        [string]
        $To
    )

    # update element
    if ($null -ne $Element) {
        return ($Element |
            Remove-PodeWebClass -Value $From |
            Add-PodeWebClass -Value $To)
    }

    # send frontend action
    else {
        return @{
            Operation = 'Rename'
            ObjectType = 'Element'
            SubObjectType = 'Class'
            ID = $Id
            Type = $Type
            Name = $Name
            From = $From
            To = $To
        }
    }
}

function Switch-PodeWebClass
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Element', ValueFromPipeline=$true)]
        [hashtable]
        $Element,

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
        $Value,

        [Parameter()]
        [ValidateSet('Toggle', 'Add', 'Remove')]
        [string]
        $State = 'Toggle'
    )

    # update element
    if ($null -ne $Element) {
        switch ($State.ToLowerInvariant()) {
            'add' {
                $Element = $Element | Add-PodeWebClass -Value $Value
            }

            'remove' {
                $Element = $Element | Remove-PodeWebClass -Value $Value
            }

            'toggle' {
                if ($Element.Css.Classes -icontains $Value) {
                    $Element = $Element | Remove-PodeWebClass -Value $Value
                }
                else {
                    $Element = $Element | Add-PodeWebClass -Value $Value
                }
            }
        }

        return $Element
    }

    # send frontend action
    else {
        return @{
            Operation = 'Switch'
            ObjectType = 'Element'
            SubObjectType = 'Class'
            ID = $Id
            Type = $Type
            Name = $Name
            Value = $Value
            State = $State
        }
    }
}

function Add-PodeWebAttribute
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Element', ValueFromPipeline=$true)]
        [hashtable]
        $Element,

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
        $Key,

        [Parameter(Mandatory=$true)]
        [string]
        $Value
    )

    # update element
    if ($null -ne $Element) {
        if ($null -eq $Element.Attributes) {
            $Element.Attributes = @{}
        }

        $Element.Attributes[$Key] = $Value
        return $Element
    }

    # send frontend action
    else {
        return @{
            Operation = 'Add'
            ObjectType = 'Element'
            SubObjectType = 'Attribute'
            ID = $Id
            Type = $Type
            Name = $Name
            Key = $Key
            Value = $Value
        }
    }
}

function Remove-PodeWebAttribute
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Element', ValueFromPipeline=$true)]
        [hashtable]
        $Element,

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
        $Key
    )

    # update element
    if ($null -ne $Element) {
        if ($null -ne $Element.Attributes) {
            $null = $Element.Attributes.Remove($Key)
        }

        return $Element
    }

    # send frontend action
    else {
        return @{
            Operation = 'Remove'
            ObjectType = 'Element'
            SubObjectType = 'Attribute'
            ID = $Id
            Type = $Type
            Name = $Name
            Key = $Key
        }
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
        ObjectType = 'File-Stream'
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
        ObjectType = 'File-Stream'
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
        ObjectType = 'File-Stream'
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
        ObjectType = 'File-Stream'
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
        ObjectType = 'File-Stream'
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

function Update-PodeWebIFrame
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
        $Url,

        [Parameter()]
        [string]
        $Title
    )

    return @{
        Operation = 'Update'
        ObjectType = 'IFrame'
        ID = $Id
        Name = $Name
        Url = $Url
        Title = $Title
    }
}

function Enable-PodeWebButton
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
        Operation = 'Enable'
        ObjectType = 'Button'
        ID = $Id
        Name = $Name
    }
}

function Disable-PodeWebButton
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
        Operation = 'Disable'
        ObjectType = 'Button'
        ID = $Id
        Name = $Name
    }
}

function Update-PodeWebButton
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
        $DisplayName,

        [Parameter()]
        [object]
        $Icon,

        [Parameter()]
        [ValidateSet('', 'Blue', 'Grey', 'Green', 'Red', 'Yellow', 'Cyan', 'Light', 'Dark')]
        [string]
        $Colour = '',

        [Parameter()]
        [ValidateSet('Unchanged', 'Outline', 'Solid')]
        [string]
        $ColourState = 'Unchanged',

        [Parameter()]
        [ValidateSet('', 'Normal', 'Small', 'Large')]
        [string]
        $Size = '',

        [Parameter()]
        [ValidateSet('Unchanged', 'Normal', 'Full')]
        [string]
        $SizeState = 'Unchanged'
    )

    $colourType = Convert-PodeWebColourToClass -Colour $Colour
    $sizeType = Convert-PodeWebButtonSizeToClass -Size $Size

    return @{
        Operation = 'Update'
        ObjectType = 'Button'
        ID = $Id
        Name = $Name
        Colour = $Colour
        ColourType = $ColourType
        ColourState = $ColourState.ToLowerInvariant()
        Size = $Size
        SizeType = $sizeType
        SizeState = $SizeState.ToLowerInvariant()
        DisplayName = [System.Net.WebUtility]::HtmlEncode($DisplayName)
        Icon = (Protect-PodeWebIconType -Icon $Icon -Element 'Button')
    }
}

function Invoke-PodeWebButton
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
        Operation = 'Invoke'
        ObjectType = 'Button'
        ID = $Id
        Name = $Name
    }
}

function Out-PodeWebElement
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $Element,

        [Parameter()]
        [ValidateSet('Append', 'After', 'Before')]
        [string]
        $AppendType = 'After'
    )

    $Element.Output = @{
        AppendType = $AppendType
    }

    return $Element
}

function Update-PodeWebRaw
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
        ObjectType = 'Raw'
        ID = $Id
        Value = $Value
    }
}

function Update-PodeWebHeader
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Id,

        [Parameter(ValueFromPipeline=$true)]
        [string]
        $Value,

        [Parameter()]
        [object]
        $Icon,

        [Parameter()]
        [ValidateSet(0, 1, 2, 3, 4, 5, 6)]
        [int]
        $Size = 0
    )

    return @{
        Operation = 'Update'
        ObjectType = 'Header'
        ID = $Id
        Value = $Value
        Icon = (Protect-PodeWebIconType -Icon $Icon -Element 'Header')
        Size = $Size
    }
}

function Update-PodeWebImage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Id,

        [Parameter()]
        [string]
        $Source,

        [Parameter()]
        [string]
        $Title,

        [Parameter()]
        [string]
        $Height,

        [Parameter()]
        [string]
        $Width
    )

    return @{
        Operation = 'Update'
        ObjectType = 'Image'
        ID = $Id
        Source = (Add-PodeWebAppPath -Url $Source)
        Title = $Title
        Height = (ConvertTo-PodeWebSize -Value $Height -Default 'auto' -Type 'px' -AllowNull)
        Width = (ConvertTo-PodeWebSize -Value $Width -Default 'auto' -Type 'px' -AllowNull)
    }
}

function Update-PodeWebIcon
{
    [CmdletBinding(DefaultParameterSetName='Rotate')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Id,

        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Colour = $null,

        [Parameter()]
        [string]
        $Title = $null,

        [Parameter(ParameterSetName='Flip')]
        [ValidateSet('', 'Horizontal', 'Vertical')]
        [string]
        $Flip = '',

        [Parameter(ParameterSetName='Rotate')]
        [ValidateSet(-1, 0, 45, 90, 135, 180, 225, 270, 315)]
        [int]
        $Rotate = -1,

        [Parameter()]
        [ValidateSet(-1, 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50)]
        [int]
        $Size = -1,

        [Parameter()]
        [hashtable]
        $ToggleIcon = $null,

        [Parameter()]
        [hashtable]
        $HoverIcon = $null,

        [switch]
        $Spin
    )

    return @{
        Operation = 'Update'
        ObjectType = 'Icon'
        ID = $Id
        Name = $Name
        Colour = $Colour
        Title = $Title
        Flip = $Flip
        Rotate = $Rotate
        Size = $Size
        Spin = (Test-PodeWebParameter -Parameters $PSBoundParameters -Name 'Spin' -Value $Spin.IsPresent)
        Icons = @{
            Toggle = $ToggleIcon
            Hover = $HoverIcon
        }
    }
}

function Switch-PodeWebIcon
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Id,

        [Parameter()]
        [ValidateSet('Default', 'Base', 'Toggle', 'Hover')]
        [string]
        $State = 'Default'
    )

    return @{
        Operation = 'Switch'
        ObjectType = 'Icon'
        ID = $Id
        State = $State
    }
}
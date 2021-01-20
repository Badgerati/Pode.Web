function Out-PodeWebTable
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Data,

        [Parameter(ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter()]
        [hashtable[]]
        $Columns,

        [Parameter(ParameterSetName='New')]
        [switch]
        $Sort,

        [Parameter(ParameterSetName='Id')]
        [switch]
        $Paginate
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
        $totalItems = $items.Length

        if ($Paginate) {
            $pageNumber = 1
            $pageAmount = 20

            if ($null -ne $ElementData) {
                if (!$ElementData.Paging.Enabled) {
                    throw "You cannot paginate a table that does not have paging enabled: $($ElementData.ID)"
                }

                $pageAmount = $ElementData.Paging.Amount
            }

            if ($null -ne $WebEvent) {
                $_number = [int]$WebEvent.Data['PageNumber']
                $_amount = [int]$WebEvent.Data['PageAmount']

                if ($_number -gt 0) {
                    $pageNumber = $_number
                }

                if ($_amount -gt 0) {
                    $pageAmount = $_amount
                }
            }

            $maxPages = [int][math]::Ceiling(($totalItems / $pageAmount))
            if ($pageNumber -gt $maxPages) {
                $pageNumber = $maxPages
            }

            $items = $items[(($pageNumber - 1) * $pageAmount) .. (($pageNumber * $pageAmount) - 1)]
        }

        # table output
        return @{
            Operation = 'Output'
            ElementType = 'Table'
            Data = $items
            ID = $Id
            Sort = $Sort.IsPresent
            Columns = $_columns
            Paging = @{
                Number = $pageNumber
                Amount = $pageAmount
                Total = $totalItems
                Max = $maxPages
            }
        }
    }
}

function Sync-PodeWebTable
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Id
    )

    return @{
        Operation = 'Sync'
        ElementType = 'Table'
        ID = $Id
    }
}

function Update-PodeWebTableRow
{
    [CmdletBinding(DefaultParameterSetName='DataValue')]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Data,

        [Parameter(Mandatory=$true)]
        [string]
        $TableId,

        [Parameter(Mandatory=$true, ParameterSetName='DataValue')]
        [string]
        $DataValue,

        [Parameter(Mandatory=$true, ParameterSetName='Index')]
        [int]
        $Index
    )

    return @{
        Operation = 'Update'
        ElementType = 'TableRow'
        TableId = $TableId
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
    [CmdletBinding(DefaultParameterSetName='New')]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Data,

        [Parameter(ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(ParameterSetName='New')]
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
            ID = $Id
            ChartType = $Type
        }
    }
}

function ConvertTo-PodeWebChartDataset
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Data,

        [Parameter(Mandatory=$true)]
        [string]
        $Label,

        [Parameter(Mandatory=$true)]
        [string[]]
        $Dataset
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
                Key = $item.$Label
                Values = @(foreach ($prop in $Dataset) {
                    @{
                        Key = $prop
                        Value = $item.$prop
                    }
                })
            }
        }
    }
}

function Out-PodeWebTextbox
{
    [CmdletBinding(DefaultParameterSetName='New')]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Data,

        [Parameter(ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(ParameterSetName='New')]
        [int]
        $Height = 10,

        [Parameter(ParameterSetName='New')]
        [switch]
        $AsJson,

        [Parameter(ParameterSetName='New')]
        [switch]
        $Multiline,

        [Parameter(ParameterSetName='New')]
        [switch]
        $Preformat,

        [Parameter(ParameterSetName='New')]
        [switch]
        $ReadOnly
    )

    begin {
        $items = @()
    }

    process {
        $items += $Data
    }

    end {
        if (!$AsJson) {
            $items = ($items | Out-String)
        }

        if ($Height -le 0) {
            $Height = 10
        }

        return @{
            Operation = 'Output'
            ElementType = 'Textbox'
            Data = $items
            ID = $Id
            AsJson = $AsJson.IsPresent
            Multiline = $Multiline
            Height = $Height
            Preformat = $Preformat.IsPresent
            ReadOnly = $ReadOnly.IsPresent
        }
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
        $Icon = 'info'
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Id
    )

    return @{
        Operation = 'Reset'
        ElementType = 'Form'
        ID = $Id
    }
}

function Out-PodeWebText
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
        Operation = 'Output'
        ElementType = 'Text'
        ID = $Id
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
    }
}

function Out-PodeWebBadge
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
        Operation = 'Output'
        ElementType = 'Badge'
        ID = $Id
        Colour = $Colour
        ColourType = $ColourType.ToLowerInvariant()
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
    }
}

function Out-PodeWebCheckbox
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Id,

        [Parameter()]
        [switch]
        $Checked
    )

    return @{
        Operation = 'Output'
        ElementType = 'Checkbox'
        ID = $Id
        Checked = $Checked.IsPresent
    }
}

function Show-PodeWebModal
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Id,

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
        DataValue = $DataValue
        Actions = $Actions
    }
}

function Hide-PodeWebModal
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id
    )

    return @{
        Operation = 'Hide'
        ElementType = 'Modal'
        ID = $Id
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
        $DataValue
    )

    $page = "/pages/$($Name -replace '\s+', '+')"

    if (![string]::IsNullOrWhiteSpace($DataValue)) {
        $page += "?Value=$($DataValue)"
    }

    return @{
        Operation = 'Move'
        ElementType = 'Href'
        Url = $page
    }
}

function Move-PodeWebUrl
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Url
    )

    return @{
        Operation = 'Move'
        ElementType = 'Href'
        Url = $Url
    }
}

function Move-PodeWebTab
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
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
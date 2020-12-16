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

        [Parameter()]
        [int]
        $PageNumber = 0,

        [Parameter()]
        [int]
        $PageAmount = 0,

        [Parameter(ParameterSetName='New')]
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

        # paging
        $maxPages = 0
        $totalItems = $items.Length

        if (($PageNumber -gt 0) -and ($PageAmount -gt 0)) {
            $maxPages = [int][math]::Ceiling(($totalItems / $PageAmount))
            if ($PageNumber -gt $maxPages) {
                $PageNumber = $maxPages
            }

            $items = $items[(($PageNumber - 1) * $PageAmount) .. (($PageNumber * $PageAmount) - 1)]
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
                Number = $PageNumber
                Amount = $PageAmount
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
        Message = $Message
        Title = $Title
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
        Message = $Message
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
        Value = $Value
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
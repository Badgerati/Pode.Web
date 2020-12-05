function Out-PodeWebTable
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Data,

        [Parameter(ParameterSetName='Id')]
        [string]
        $Id,

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
        return @{
            OutputType = 'Table'
            Data = $items
            ID = $Id
            Sort = $Sort.IsPresent
        }
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
            OutputType = 'Chart'
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
        $Preformat
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
            OutputType = 'Textbox'
            Data = $items
            ID = $Id
            AsJson = $AsJson.IsPresent
            Multiline = $Multiline
            Height = $Height
            Preformat = $Preformat.IsPresent
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
        OutputType = 'Toast'
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
        OutputType = 'Validation'
        Name = $Name
        ID = $Id
        Message = $Message
    }
}
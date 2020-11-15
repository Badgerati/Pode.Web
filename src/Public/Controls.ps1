function New-PodeWebTextbox
{
    [CmdletBinding(DefaultParameterSetName='Single')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id,

        [Parameter(ParameterSetName='Single')]
        [ValidateSet('Text', 'Email', 'Password', 'Number', 'Date', 'Time', 'File')]
        [string]
        $Type ='Text',

        [Parameter()]
        [string]
        $Placeholder,

        [Parameter(ParameterSetName='Multi')]
        [int]
        $Height = 4,

        [Parameter(ParameterSetName='Multi')]
        [switch]
        $Multiline,

        [switch]
        $Preformat
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "txt_$($Name)_$(Get-PodeWebRandomName)"
    }

    if ($Height -le 0) {
        $Height = 4
    }

    return @{
        ControlType = 'Textbox'
        Name = $Name
        ID = $Id
        Type = $Type
        Multiline = $Multiline.IsPresent
        Placeholder = $Placeholder
        Height = $Height
        Preformat = $Preformat.IsPresent
    }
}

function New-PodeWebParagraph
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Value
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "para_$(Get-PodeWebRandomName)"
    }

    return @{
        ControlType = 'Paragraph'
        ID = $Id
        Value = $Value
    }
}
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

        [Parameter()]
        [string]
        $HelpText,

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
        HelpText = $HelpText
    }
}

function New-PodeWebFileUpload
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "file_$($Name)_$(Get-PodeWebRandomName)"
    }

    return @{
        ControlType = 'FileUpload'
        Name = $Name
        ID = $Id
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

function New-PodeWebCodeBlock
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Value,

        [switch]
        $Scrollable
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "codeblock_$(Get-PodeWebRandomName)"
    }

    return @{
        ControlType = 'CodeBlock'
        ID = $Id
        Value = $Value
        Scrollable = $Scrollable
    }
}

function New-PodeWebCheckbox
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
        [string[]]
        $Options,

        [switch]
        $Inline
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "chkbox_$($Name)_$(Get-PodeWebRandomName)"
    }

    return @{
        ControlType = 'Checkbox'
        Name = $Name
        ID = $Id
        Options = @($Options)
        Inline = $Inline.IsPresent
    }
}

function New-PodeWebRadio
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
        [string[]]
        $Options,

        [switch]
        $Inline
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "radio_$($Name)_$(Get-PodeWebRandomName)"
    }

    return @{
        ControlType = 'Radio'
        Name = $Name
        ID = $Id
        Options = @($Options)
        Inline = $Inline.IsPresent
    }
}

function New-PodeWebSelect
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
        [string[]]
        $Options,

        [switch]
        $Multiple
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "select_$($Name)_$(Get-PodeWebRandomName)"
    }

    return @{
        ControlType = 'Select'
        Name = $Name
        ID = $Id
        Options = @($Options)
        Multiple = $Multiple.IsPresent
    }
}
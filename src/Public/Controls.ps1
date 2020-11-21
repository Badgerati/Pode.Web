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

        [Parameter(ParameterSetName='Single')]
        [string]
        $PrependText,

        [Parameter(ParameterSetName='Single')]
        [string]
        $PrependIcon,

        [Parameter(ParameterSetName='Multi')]
        [switch]
        $Multiline,

        [switch]
        $Preformat,

        [switch]
        $ReadOnly
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
        ReadOnly = $ReadOnly.IsPresent
        Prepend = @{
            Enabled = (![string]::IsNullOrWhiteSpace($PrependText) -or ![string]::IsNullOrWhiteSpace($PrependIcon))
            Text = $PrependText
            Icon = $PrependIcon
        }
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
        Scrollable = $Scrollable.IsPresent
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
        $Inline,

        [switch]
        $AsSwitch,

        [switch]
        $Disabled
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
        AsSwitch = $AsSwitch.IsPresent
        Disabled = $Disabled.IsPresent
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
        $Inline,

        [switch]
        $Disabled
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
        Disabled = $Disabled.IsPresent
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

function New-PodeWebRange
{
    [CmdletBinding(DefaultParameterSetName="Percentage")]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [int]
        $Value = 0,

        [Parameter()]
        [int]
        $Min = 0,

        [Parameter()]
        [int]
        $Max = 100,

        [switch]
        $Disabled,

        [switch]
        $ShowValue
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "range_$($Name)_$(Get-PodeWebRandomName)"
    }

    if ($Value -lt $Min) {
        $Value = $Min
    }

    if ($Value -gt $Max) {
        $Value = $Max
    }

    return @{
        ControlType = 'Range'
        Name = $Name
        ID = $Id
        Value = $Value
        Min = $Min
        Max = $Max
        Disabled = $Disabled.IsPresent
        ShowValue = $ShowValue.IsPresent
    }
}

function New-PodeWebImage
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Source,

        [Parameter()]
        [string]
        $Alt,

        [Parameter()]
        [ValidateSet('Left', 'Right', 'Center')]
        [string]
        $Location = 'Left',

        [Parameter()]
        [int]
        $Height = 0,

        [Parameter()]
        [int]
        $Width = 0
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "img_$(Get-PodeWebRandomName)"
    }

    if ($Height -lt 0) {
        $Height = 0
    }

    if ($Width -lt 0) {
        $Width = 0
    }

    return @{
        ControlType = 'Image'
        ID = $Id
        Source = $Source
        Alt = $Alt
        Location = $Location
        Height = $Height
        Width = $Width
    }
}
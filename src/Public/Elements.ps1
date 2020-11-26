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
        $Id = "txt_$($Name)_$(Get-PodeWebRandomName)" -replace '\s+', '_'
    }

    if ($Height -le 0) {
        $Height = 4
    }

    return @{
        ElementType = 'Textbox'
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
        $Id = "file_$($Name)_$(Get-PodeWebRandomName)" -replace '\s+', '_'
    }

    return @{
        ElementType = 'FileUpload'
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

        [Parameter(Mandatory=$true, ParameterSetName='Value')]
        [string]
        $Value,

        [Parameter(Mandatory=$true, ParameterSetName='Elements')]
        [hashtable[]]
        $Elements
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "para_$(Get-PodeWebRandomName)"
    }

    return @{
        ElementType = 'Paragraph'
        ID = $Id
        Value = $Value
        Elements = $Elements
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
        ElementType = 'CodeBlock'
        ID = $Id
        Value = $Value
        Scrollable = $Scrollable.IsPresent
    }
}

function New-PodeWebCode
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
        $Id = "code_$(Get-PodeWebRandomName)"
    }

    return @{
        ElementType = 'Code'
        ID = $Id
        Value = $Value
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
        $Checked,

        [switch]
        $Disabled
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "chkbox_$($Name)_$(Get-PodeWebRandomName)" -replace '\s+', '_'
    }

    return @{
        ElementType = 'Checkbox'
        Name = $Name
        ID = $Id
        Options = @($Options)
        Inline = $Inline.IsPresent
        AsSwitch = $AsSwitch.IsPresent
        Checked = $Checked.IsPresent
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
        $Id = "radio_$($Name)_$(Get-PodeWebRandomName)" -replace '\s+', '_'
    }

    return @{
        ElementType = 'Radio'
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

        [Parameter()]
        [string]
        $SelectedValue,

        [switch]
        $Multiple
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "select_$($Name)_$(Get-PodeWebRandomName)" -replace '\s+', '_'
    }

    return @{
        ElementType = 'Select'
        Name = $Name
        ID = $Id
        Options = @($Options)
        SelectedValue = $SelectedValue
        Multiple = $Multiple.IsPresent
    }
}

function New-PodeWebRange
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
        $Id = "range_$($Name)_$(Get-PodeWebRandomName)" -replace '\s+', '_'
    }

    if ($Value -lt $Min) {
        $Value = $Min
    }

    if ($Value -gt $Max) {
        $Value = $Max
    }

    return @{
        ElementType = 'Range'
        Name = $Name
        ID = $Id
        Value = $Value
        Min = $Min
        Max = $Max
        Disabled = $Disabled.IsPresent
        ShowValue = $ShowValue.IsPresent
    }
}

function New-PodeWebProgress
{
    [CmdletBinding()]
    param(
        [Parameter()]
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
        $ShowValue,

        [switch]
        $Striped,

        [switch]
        $Animated
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "progress_$(Get-PodeWebRandomName)" -replace '\s+', '_'
    }

    if ($Value -lt $Min) {
        $Value = $Min
    }

    if ($Value -gt $Max) {
        $Value = $Max
    }

    $percentage = 0
    if ($Value -gt 0) {
        $percentage = ($Value / $Max) * 100.0
    }

    return @{
        ElementType = 'Progress'
        Name = $Name
        ID = $Id
        Value = $Value
        Min = $Min
        Max = $Max
        Percentage = $percentage
        ShowValue = $ShowValue.IsPresent
        Striped = ($Striped.IsPresent -or $Animated.IsPresent)
        Animated = $Animated.IsPresent
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
        ElementType = 'Image'
        ID = $Id
        Source = $Source
        Alt = $Alt
        Location = $Location
        Height = $Height
        Width = $Width
    }
}

function New-PodeWebHeader
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [ValidateSet(1, 2, 3, 4, 5, 6)]
        [int]
        $Size,

        [Parameter(Mandatory=$true)]
        [string]
        $Value,

        [Parameter()]
        [string]
        $Secondary
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "header_$(Get-PodeWebRandomName)"
    }

    return @{
        ElementType = 'Header'
        ID = $Id
        Size = $Size
        Value = $Value
        Secondary = $Secondary
    }
}

function New-PodeWebQuote
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [ValidateSet('Left', 'Right', 'Center')]
        [string]
        $Location,

        [Parameter(Mandatory=$true)]
        [string]
        $Value,

        [Parameter()]
        [string]
        $Source
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "quote_$(Get-PodeWebRandomName)"
    }

    return @{
        ElementType = 'Quote'
        ID = $Id
        Location = $Location
        Value = $Value
        Source = $Source
    }
}

function New-PodeWebList
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string[]]
        $Items,

        [switch]
        $Numbered
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "list_$(Get-PodeWebRandomName)"
    }

    return @{
        ElementType = 'List'
        ID = $Id
        Items  = $Items
        Numbered = $Numbered.IsPresent
    }
}

function New-PodeWebLink
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Source,

        [Parameter(Mandatory=$true)]
        [string]
        $Value,

        [switch]
        $NewTab
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = "a_$(Get-PodeWebRandomName)"
    }

    return @{
        ElementType = 'Link'
        ID = $Id
        Source = $Source
        Value = $Value
        Newtab = $NewTab.IsPresent
    }
}

function New-PodeWebText
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Value,

        [Parameter()]
        [ValidateSet('Normal', 'Underlined', 'StrikeThrough', 'Deleted', 'Inserted', 'Italics', 'Bold', 'Small')]
        [string]
        $Style = 'Normal'
    )

    return @{
        ElementType = 'Text'
        Value = $Value
        Style = $Style
    }
}
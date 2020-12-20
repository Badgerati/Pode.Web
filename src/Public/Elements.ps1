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

        [Parameter()]
        [string]
        $Value,

        [Parameter(ParameterSetName='Single')]
        [scriptblock]
        $AutoComplete,

        [Parameter(ParameterSetName='Multi')]
        [switch]
        $Multiline,

        [switch]
        $Preformat,

        [switch]
        $ReadOnly,

        [Parameter(ParameterSetName='Single')]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    $Id = Get-PodeWebElementId -Tag Textbox -Id $Id -Name $Name

    if ($Height -le 0) {
        $Height = 4
    }

    $element = @{
        ElementType = 'Textbox'
        Component = $ComponentData
        Name = $Name
        ID = $Id
        Type = $Type
        Multiline = $Multiline.IsPresent
        Placeholder = $Placeholder
        Height = $Height
        Preformat = $Preformat.IsPresent
        HelpText = $HelpText
        ReadOnly = $ReadOnly.IsPresent
        IsAutoComplete = ($null -ne $AutoComplete)
        Value = $Value
        Prepend = @{
            Enabled = (![string]::IsNullOrWhiteSpace($PrependText) -or ![string]::IsNullOrWhiteSpace($PrependIcon))
            Text = $PrependText
            Icon = $PrependIcon
        }
    }

    $routePath = "/elements/autocomplete/$($Id)"
    if (($null -ne $AutoComplete) -and !(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ScriptBlock {
            $global:ElementData = $using:element

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:AutoComplete -Return
            if ($null -eq $result) {
                $result = @()
            }

            Write-PodeJsonResponse -Value @{ Values = $result }
            $global:ElementData = $null
        }
    }

    return $element
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

    $Id = Get-PodeWebElementId -Tag File -Id $Id -Name $Name

    return @{
        ElementType = 'FileUpload'
        Component = $ComponentData
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

    # ensure elements are correct
    foreach ($element in $Elements) {
        if ([string]::IsNullOrWhiteSpace($element.ElementType)) {
            throw "Invalid element supplied: $($element)"
        }
    }

    $Id = Get-PodeWebElementId -Tag Para -Id $Id -RandomToken

    return @{
        ElementType = 'Paragraph'
        Component = $ComponentData
        ID = $Id
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
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

        [Parameter()]
        [string]
        $Value,

        [Parameter()]
        [string]
        $Language = [string]::Empty,

        [switch]
        $Scrollable,

        [switch]
        $NoHighlight
    )

    # id
    $Id = Get-PodeWebElementId -Tag Codeblock -Id $Id -RandomToken

    # language
    if ($NoHighlight) {
        $Language = 'plaintext'
    }

    return @{
        ElementType = 'CodeBlock'
        Component = $ComponentData
        ID = $Id
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Language = $Language.ToLowerInvariant()
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

    $Id = Get-PodeWebElementId -Tag Code -Id $Id -RandomToken

    return @{
        ElementType = 'Code'
        Component = $ComponentData
        ID = $Id
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
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

        [Parameter(ParameterSetName='Multiple')]
        [string[]]
        $Options,

        [Parameter(ParameterSetName='Multiple')]
        [switch]
        $Inline,

        [switch]
        $AsSwitch,

        [switch]
        $Checked,

        [switch]
        $Disabled
    )

    $Id = Get-PodeWebElementId -Tag Checkbox -Id $Id -Name $Name

    if (($null -eq $Options) -or ($Options.Length -eq 0)) {
        $Options = @('true')
    }

    return @{
        ElementType = 'Checkbox'
        Component = $ComponentData
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

    $Id = Get-PodeWebElementId -Tag Radio -Id $Id -Name $Name

    return @{
        ElementType = 'Radio'
        Component = $ComponentData
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

        [Parameter()]
        [string[]]
        $Options,

        [Parameter()]
        [string]
        $SelectedValue,

        [switch]
        $Multiple
    )

    if (Test-PodeIsEmpty $Options) {
        throw "Select options are required"
    }

    $Id = Get-PodeWebElementId -Tag Select -Id $Id -Name $Name

    return @{
        ElementType = 'Select'
        Component = $ComponentData
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

    $Id = Get-PodeWebElementId -Tag Range -Id $Id -Name $Name

    if ($Value -lt $Min) {
        $Value = $Min
    }

    if ($Value -gt $Max) {
        $Value = $Max
    }

    return @{
        ElementType = 'Range'
        Component = $ComponentData
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

        [Parameter()]
        [ValidateSet('Blue', 'Grey', 'Green', 'Red', 'Yellow', 'Cyan', 'Light', 'Dark')]
        [string]
        $Colour = 'Blue',

        [switch]
        $ShowValue,

        [switch]
        $Striped,

        [switch]
        $Animated
    )

    $Id = Get-PodeWebElementId -Tag Progress -Id $Id -Name $Name
    $colourType = Convert-PodeWebColourToClass -Colour $Colour

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
        Component = $ComponentData
        Name = $Name
        ID = $Id
        Value = $Value
        Min = $Min
        Max = $Max
        Percentage = $percentage
        ShowValue = $ShowValue.IsPresent
        Striped = ($Striped.IsPresent -or $Animated.IsPresent)
        Animated = $Animated.IsPresent
        Colour = $Colour
        ColourType = $ColourType
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

    $Id = Get-PodeWebElementId -Tag Img -Id $Id -RandomToken

    if ($Height -lt 0) {
        $Height = 0
    }

    if ($Width -lt 0) {
        $Width = 0
    }

    return @{
        ElementType = 'Image'
        Component = $ComponentData
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

    $Id = Get-PodeWebElementId -Tag Header -Id $Id -RandomToken

    return @{
        ElementType = 'Header'
        Component = $ComponentData
        ID = $Id
        Size = $Size
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Secondary = [System.Net.WebUtility]::HtmlEncode($Secondary)
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

    $Id = Get-PodeWebElementId -Tag Quote -Id $Id -RandomToken

    return @{
        ElementType = 'Quote'
        Component = $ComponentData
        ID = $Id
        Location = $Location
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Source = [System.Net.WebUtility]::HtmlEncode($Source)
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

    $Id = Get-PodeWebElementId -Tag List -Id $Id -RandomToken

    return @{
        ElementType = 'List'
        Component = $ComponentData
        ID = $Id
        Items  = @(foreach ($item in $Items) {
            [System.Net.WebUtility]::HtmlEncode($item)
        })
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

    $Id = Get-PodeWebElementId -Tag A -Id $Id -RandomToken

    return @{
        ElementType = 'Link'
        Component = $ComponentData
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
        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [string]
        $Value,

        [Parameter()]
        [ValidateSet('Normal', 'Underlined', 'StrikeThrough', 'Deleted', 'Inserted', 'Italics', 'Bold', 'Small')]
        [string]
        $Style = 'Normal',

        [switch]
        $InParagraph
    )

    $Id = Get-PodeWebElementId -Tag Txt -Id $Id -RandomToken

    return @{
        ElementType = 'Text'
        Component = $ComponentData
        ID = $Id
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Style = $Style
        InParagraph = $InParagraph.IsPresent
    }
}

function New-PodeWebLine
{
    [CmdletBinding()]
    param()

    return @{
        ElementType = 'Line'
        Component = $ComponentData
    }
}

function New-PodeWebHidden
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
        [string]
        $Value
    )

    $Id = Get-PodeWebElementId -Tag Hidden -Id $Id -Name $Name

    return @{
        ElementType = 'Hidden'
        Component = $ComponentData
        Name = $Name
        ID = $Id
        Value = $Value
    }
}

function New-PodeWebCredential
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
        [string]
        $HelpText,

        [switch]
        $ReadOnly
    )

    $Id = Get-PodeWebElementId -Tag Cred -Id $Id -Name $Name

    return @{
        ElementType = 'Credential'
        Component = $ComponentData
        Name = $Name
        ID = $Id
        HelpText = $HelpText
        ReadOnly = $ReadOnly.IsPresent
    }
}

function New-PodeWebRaw
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Value
    )

    return @{
        ElementType = 'Raw'
        Component = $ComponentData
        Value = $Value
    }
}

function New-PodeWebButton
{
    [CmdletBinding(DefaultParameterSetName='ScriptBlock')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id,

        [Parameter(ParameterSetName='ScriptBlock')]
        [string]
        $DataValue,

        [Parameter()]
        [string]
        $Icon,

        [Parameter(Mandatory=$true, ParameterSetName='ScriptBlock')]
        [scriptblock]
        $ScriptBlock,

        [Parameter(ParameterSetName='ScriptBlock')]
        [object[]]
        $ArgumentList,

        [Parameter(Mandatory=$true, ParameterSetName='Url')]
        [string]
        $Url,

        [Parameter()]
        [ValidateSet('Blue', 'Grey', 'Green', 'Red', 'Yellow', 'Cyan', 'Light', 'Dark')]
        [string]
        $Colour = 'Blue',

        [Parameter(ParameterSetName='ScriptBlock')]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [switch]
        $IconOnly
    )

    $Id = Get-PodeWebElementId -Tag Btn -Id $Id -Name $Name
    $colourType = Convert-PodeWebColourToClass -Colour $Colour

    $element = @{
        ElementType = 'Button'
        Component = $ComponentData
        Name = $Name
        ID = $Id
        DataValue = $DataValue
        Icon = $Icon
        Url = $Url
        IsDynamic = ($null -ne $ScriptBlock)
        IconOnly = $IconOnly.IsPresent
        Colour = $Colour
        ColourType = $ColourType
    }

    $routePath = "/elements/button/$($Id)"
    if (($null -ne $ScriptBlock) -and !(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -ScriptBlock {
            param($Data)
            $global:ElementData = $using:element

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            Write-PodeJsonResponse -Value $result
            $global:ElementData = $null
        }
    }

    return $element
}

function New-PodeWebAlert
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [ValidateSet('Note', 'Tip', 'Important', 'Info', 'Warning', 'Error')]
        [string]
        $Type = 'Note',

        [Parameter(Mandatory=$true, ParameterSetName='Value')]
        [string]
        $Value,

        [Parameter(Mandatory=$true, ParameterSetName='Elements')]
        [hashtable[]]
        $Elements
    )

    # ensure elements are correct
    foreach ($element in $Elements) {
        if ([string]::IsNullOrWhiteSpace($element.ElementType)) {
            throw "Invalid element supplied: $($element)"
        }
    }

    $Id = Get-PodeWebElementId -Tag Alert -Id $Id -RandomToken
    $classType = Convert-PodeWebAlertTypeToClass -Type $Type
    $iconType = Convert-PodeWebAlertTypeToIcon -Type $Type

    return @{
        ElementType = 'Alert'
        Component = $ComponentData
        ID = $Id
        Type = $Type
        ClassType = $classType
        IconType = $iconType
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Elements = $Elements
    }
}

function New-PodeWebIcon
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    return @{
        ElementType = 'Icon'
        Component = $ComponentData
        Name = $Name
    }
}

function New-PodeWebSpinner
{
    [CmdletBinding()]
    param()

    return @{
        ElementType = 'Spinner'
        Component = $ComponentData
    }
}

function New-PodeWebBadge
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [ValidateSet('Blue', 'Grey', 'Green', 'Red', 'Yellow', 'Cyan', 'Light', 'Dark')]
        [string]
        $Colour = 'Blue',

        [Parameter(Mandatory=$true)]
        [string]
        $Value
    )

    $Id = Get-PodeWebElementId -Tag Alert -Id $Id -RandomToken
    $colourType = Convert-PodeWebColourToClass -Colour $Colour

    return @{
        ElementType = 'Badge'
        Component = $ComponentData
        ID = $Id
        Colour = $Colour
        ColourType = $ColourType.ToLowerInvariant()
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
    }
}

function New-PodeWebComment
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Icon,

        [Parameter(Mandatory=$true)]
        [string]
        $Username,

        [Parameter(Mandatory=$true)]
        [string]
        $Message,

        [Parameter()]
        [DateTime]
        $TimeStamp
    )

    return @{
        ElementType = 'Comment'
        Component = $ComponentData
        Icon = $Icon
        Username = $Username
        Message = $Message
        TimeStamp = $TimeStamp
    }
}
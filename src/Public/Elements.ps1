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
        [ValidateSet('Text', 'Email', 'Password', 'Number', 'Date', 'Time', 'File', 'DateTime')]
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

        [Parameter()]
        [string[]]
        $CssClass,

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
        ComponentType = 'Element'
        ElementType = 'Textbox'
        Parent = $ElementData
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
        CssClasses = ($CssClass -join ' ')
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
        $Id,

        [Parameter()]
        [string[]]
        $CssClass
    )

    $Id = Get-PodeWebElementId -Tag File -Id $Id -Name $Name

    return @{
        ComponentType = 'Element'
        ElementType = 'FileUpload'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        CssClasses = ($CssClass -join ' ')
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
        $Elements,

        [Parameter()]
        [ValidateSet('Left', 'Right', 'Center')]
        [string]
        $Alignment = 'Left',

        [Parameter()]
        [string[]]
        $CssClass
    )

    # ensure elements are correct
    if (!(Test-PodeWebContent -Content $Elements -ComponentType Element)) {
        throw 'A Paragraph can only contain elements'
    }

    $Id = Get-PodeWebElementId -Tag Para -Id $Id -RandomToken

    return @{
        ComponentType = 'Element'
        ElementType = 'Paragraph'
        Parent = $ElementData
        ID = $Id
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Elements = $Elements
        Alignment = $Alignment.ToLowerInvariant()
        CssClasses = ($CssClass -join ' ')
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

        [Parameter()]
        [string[]]
        $CssClass,

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
        ComponentType = 'Element'
        ElementType = 'CodeBlock'
        Parent = $ElementData
        ID = $Id
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Language = $Language.ToLowerInvariant()
        Scrollable = $Scrollable.IsPresent
        CssClasses = ($CssClass -join ' ')
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
        $Value,

        [Parameter()]
        [string[]]
        $CssClass
    )

    $Id = Get-PodeWebElementId -Tag Code -Id $Id -RandomToken

    return @{
        ComponentType = 'Element'
        ElementType = 'Code'
        Parent = $ElementData
        ID = $Id
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        CssClasses = ($CssClass -join ' ')
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

        [Parameter()]
        [string[]]
        $CssClass,

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
        ComponentType = 'Element'
        ElementType = 'Checkbox'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        Options = @($Options)
        Inline = $Inline.IsPresent
        AsSwitch = $AsSwitch.IsPresent
        Checked = $Checked.IsPresent
        Disabled = $Disabled.IsPresent
        CssClasses = ($CssClass -join ' ')
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

        [Parameter()]
        [string[]]
        $CssClass,

        [switch]
        $Inline,

        [switch]
        $Disabled
    )

    $Id = Get-PodeWebElementId -Tag Radio -Id $Id -Name $Name

    return @{
        ComponentType = 'Element'
        ElementType = 'Radio'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        Options = @($Options)
        Inline = $Inline.IsPresent
        Disabled = $Disabled.IsPresent
        CssClasses = ($CssClass -join ' ')
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

        [Parameter()]
        [string[]]
        $CssClass,

        [switch]
        $Multiple
    )

    if (Test-PodeIsEmpty $Options) {
        throw "Select options are required"
    }

    $Id = Get-PodeWebElementId -Tag Select -Id $Id -Name $Name

    return @{
        ComponentType = 'Element'
        ElementType = 'Select'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        Options = @($Options)
        SelectedValue = $SelectedValue
        Multiple = $Multiple.IsPresent
        CssClasses = ($CssClass -join ' ')
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

        [Parameter()]
        [string[]]
        $CssClass,

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
        ComponentType = 'Element'
        ElementType = 'Range'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        Value = $Value
        Min = $Min
        Max = $Max
        Disabled = $Disabled.IsPresent
        ShowValue = $ShowValue.IsPresent
        CssClasses = ($CssClass -join ' ')
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

        [Parameter()]
        [string[]]
        $CssClass,

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
        ComponentType = 'Element'
        ElementType = 'Progress'
        Parent = $ElementData
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
        CssClasses = ($CssClass -join ' ')
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
        $Alignment = 'Left',

        [Parameter()]
        [int]
        $Height = 0,

        [Parameter()]
        [int]
        $Width = 0,

        [Parameter()]
        [string[]]
        $CssClass
    )

    $Id = Get-PodeWebElementId -Tag Img -Id $Id -RandomToken

    if ($Height -lt 0) {
        $Height = 0
    }

    if ($Width -lt 0) {
        $Width = 0
    }

    return @{
        ComponentType = 'Element'
        ElementType = 'Image'
        Parent = $ElementData
        ID = $Id
        Source = $Source
        Alt = $Alt
        Alignment = $Alignment.ToLowerInvariant()
        Height = $Height
        Width = $Width
        CssClasses = ($CssClass -join ' ')
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
        $Secondary,

        [Parameter()]
        [string[]]
        $CssClass
    )

    $Id = Get-PodeWebElementId -Tag Header -Id $Id -RandomToken

    return @{
        ComponentType = 'Element'
        ElementType = 'Header'
        Parent = $ElementData
        ID = $Id
        Size = $Size
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Secondary = [System.Net.WebUtility]::HtmlEncode($Secondary)
        CssClasses = ($CssClass -join ' ')
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
        $Alignment,

        [Parameter(Mandatory=$true)]
        [string]
        $Value,

        [Parameter()]
        [string]
        $Source,

        [Parameter()]
        [string[]]
        $CssClass
    )

    $Id = Get-PodeWebElementId -Tag Quote -Id $Id -RandomToken

    return @{
        ComponentType = 'Element'
        ElementType = 'Quote'
        Parent = $ElementData
        ID = $Id
        Alignment = $Alignment.ToLowerInvariant()
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Source = [System.Net.WebUtility]::HtmlEncode($Source)
        CssClasses = ($CssClass -join ' ')
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

        [Parameter()]
        [string[]]
        $CssClass,

        [switch]
        $Numbered
    )

    $Id = Get-PodeWebElementId -Tag List -Id $Id -RandomToken

    return @{
        ComponentType = 'Element'
        ElementType = 'List'
        Parent = $ElementData
        ID = $Id
        Items  = @(foreach ($item in $Items) {
            [System.Net.WebUtility]::HtmlEncode($item)
        })
        Numbered = $Numbered.IsPresent
        CssClasses = ($CssClass -join ' ')
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

        [Parameter()]
        [string[]]
        $CssClass,

        [switch]
        $NewTab
    )

    $Id = Get-PodeWebElementId -Tag A -Id $Id -RandomToken

    return @{
        ComponentType = 'Element'
        ElementType = 'Link'
        Parent = $ElementData
        ID = $Id
        Source = $Source
        Value = $Value
        Newtab = $NewTab.IsPresent
        CssClasses = ($CssClass -join ' ')
    }
}

function New-PodeWebText
{
    [CmdletBinding(DefaultParameterSetName='Default')]
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

        [Parameter(ParameterSetName='Paragraph')]
        [ValidateSet('Left', 'Right', 'Center')]
        [string]
        $Alignment = 'Left',

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter(ParameterSetName='Paragraph')]
        [switch]
        $InParagraph
    )

    $Id = Get-PodeWebElementId -Tag Txt -Id $Id -RandomToken

    return @{
        ComponentType = 'Element'
        ElementType = 'Text'
        Parent = $ElementData
        ID = $Id
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Style = $Style
        InParagraph = $InParagraph.IsPresent
        Alignment = $Alignment.ToLowerInvariant()
        CssClasses = ($CssClass -join ' ')
    }
}

function New-PodeWebLine
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]
        $CssClass
    )

    return @{
        ComponentType = 'Element'
        ElementType = 'Line'
        Parent = $ElementData
        CssClasses = ($CssClass -join ' ')
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
        $Value,

        [Parameter()]
        [string[]]
        $CssClass
    )

    $Id = Get-PodeWebElementId -Tag Hidden -Id $Id -Name $Name

    return @{
        ComponentType = 'Element'
        ElementType = 'Hidden'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        Value = $Value
        CssClasses = ($CssClass -join ' ')
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

        [Parameter()]
        [string[]]
        $CssClass,

        [switch]
        $ReadOnly,

        [switch]
        $NoLabels
    )

    $Id = Get-PodeWebElementId -Tag Cred -Id $Id -Name $Name

    return @{
        ComponentType = 'Element'
        ElementType = 'Credential'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        HelpText = $HelpText
        ReadOnly = $ReadOnly.IsPresent
        NoLabels = $NoLabels.IsPresent
        CssClasses = ($CssClass -join ' ')
    }
}

function New-PodeWebDateTime
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

        [Parameter()]
        [string[]]
        $CssClass,

        [switch]
        $ReadOnly,

        [switch]
        $NoLabels
    )

    $Id = Get-PodeWebElementId -Tag DateTime -Id $Id -Name $Name

    return @{
        ComponentType = 'Element'
        ElementType = 'DateTime'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        HelpText = $HelpText
        ReadOnly = $ReadOnly.IsPresent
        NoLabels = $NoLabels.IsPresent
        CssClasses = ($CssClass -join ' ')
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
        ComponentType = 'Element'
        ElementType = 'Raw'
        Parent = $ElementData
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

        [Parameter()]
        [ValidateSet('Left', 'Right', 'Center')]
        [string]
        $Alignment = 'Left',

        [Parameter()]
        [string[]]
        $CssClass,

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
        ComponentType = 'Element'
        ElementType = 'Button'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        DataValue = $DataValue
        Icon = $Icon
        Url = $Url
        IsDynamic = ($null -ne $ScriptBlock)
        IconOnly = $IconOnly.IsPresent
        Colour = $Colour
        ColourType = $ColourType
        Alignment = $Alignment.ToLowerInvariant()
        CssClasses = ($CssClass -join ' ')
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

            if ($WebEvent.Response.ContentLength64 -eq 0) {
                Write-PodeJsonResponse -Value $result
            }

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
        [ValidateSet('Note', 'Tip', 'Important', 'Info', 'Warning', 'Error', 'Success')]
        [string]
        $Type = 'Note',

        [Parameter(Mandatory=$true, ParameterSetName='Value')]
        [string]
        $Value,

        [Parameter(Mandatory=$true, ParameterSetName='Content')]
        [hashtable[]]
        $Content,

        [Parameter()]
        [string[]]
        $CssClass
    )

    # ensure content are correct
    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'An Alert can only contain layouts and/or elements'
    }

    $Id = Get-PodeWebElementId -Tag Alert -Id $Id -RandomToken
    $classType = Convert-PodeWebAlertTypeToClass -Type $Type
    $iconType = Convert-PodeWebAlertTypeToIcon -Type $Type

    return @{
        ComponentType = 'Element'
        ElementType = 'Alert'
        Parent = $ElementData
        ID = $Id
        Type = $Type
        ClassType = $classType
        IconType = $iconType
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Content = $Content
        CssClasses = ($CssClass -join ' ')
    }
}

function New-PodeWebIcon
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Colour,

        [Parameter()]
        [string[]]
        $CssClass
    )

    if (![string]::IsNullOrWhiteSpace($Colour)) {
        $Colour = $Colour.ToLowerInvariant()
    }

    return @{
        ComponentType = 'Element'
        ElementType = 'Icon'
        Parent = $ElementData
        Name = $Name
        Colour = $Colour
        CssClasses = ($CssClass -join ' ')
    }
}

function New-PodeWebSpinner
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Colour,

        [Parameter()]
        [string[]]
        $CssClass
    )

    if (![string]::IsNullOrWhiteSpace($Colour)) {
        $Colour = $Colour.ToLowerInvariant()
    }

    return @{
        ComponentType = 'Element'
        ElementType = 'Spinner'
        Parent = $ElementData
        Colour = $Colour
        CssClasses = ($CssClass -join ' ')
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
        $Value,

        [Parameter()]
        [string[]]
        $CssClass
    )

    $Id = Get-PodeWebElementId -Tag Alert -Id $Id -RandomToken
    $colourType = Convert-PodeWebColourToClass -Colour $Colour

    return @{
        ComponentType = 'Element'
        ElementType = 'Badge'
        Parent = $ElementData
        ID = $Id
        Colour = $Colour
        ColourType = $ColourType.ToLowerInvariant()
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        CssClasses = ($CssClass -join ' ')
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
        $TimeStamp,

        [Parameter()]
        [string[]]
        $CssClass
    )

    return @{
        ComponentType = 'Element'
        ElementType = 'Comment'
        Parent = $ElementData
        Icon = $Icon
        Username = $Username
        Message = $Message
        TimeStamp = $TimeStamp
        CssClasses = ($CssClass -join ' ')
    }
}

function New-PodeWebChart
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
        $Message,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [ValidateSet('line', 'pie', 'doughnut', 'bar')]
        [string]
        $Type = 'line',

        [Parameter()]
        [int]
        $MaxItems = 0,

        [Parameter()]
        [int]
        $Height = 0,

        [Parameter()]
        [object[]]
        $ArgumentList,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [Parameter()]
        [string[]]
        $CssClass,

        [switch]
        $Append,

        [switch]
        $TimeLabels,

        [switch]
        $AutoRefresh,

        [switch]
        $NoRefresh,

        [switch]
        $AsCard
    )

    $Id = Get-PodeWebElementId -Tag Chart -Id $Id -Name $Name

    if ($MaxItems -lt 0) {
        $MaxItems = 0
    }

    $routePath = "/elements/chart/$($Id)"
    if (!(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -ScriptBlock {
            param($Data)

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            if (($result.Length -gt 0) -and [string]::IsNullOrWhiteSpace($result[0].OutputType)) {
                $result = ($result | Out-PodeWebChart -Id $using:Id)
            }

            Write-PodeJsonResponse -Value $result
        }
    }

    $element = @{
        ComponentType = 'Element'
        ElementType = 'Chart'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        Message = $Message
        ChartType = $Type
        IsDynamic = ($null -ne $ScriptBlock)
        Append = $Append.IsPresent
        MaxItems = $MaxItems
        Height = $Height
        TimeLabels = $TimeLabels.IsPresent
        AutoRefresh = $AutoRefresh.IsPresent
        NoRefresh = $NoRefresh.IsPresent
        CssClasses = ($CssClass -join ' ')
    }

    if ($AsCard) {
        $element = New-PodeWebCard -Name $Name -Content $element
    }

    return $element
}

function New-PodeWebCounterChart
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Counter,

        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [switch]
        $AsCard
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        $Name = Split-Path -Path $Counter -Leaf
    }

    New-PodeWebChart `
        -Name $Name `
        -Type Line `
        -MaxItems 30 `
        -ArgumentList $Counter `
        -Append `
        -TimeLabels `
        -AutoRefresh `
        -CssClass $CssClass `
        -NoAuthentication:$NoAuthentication `
        -AsCard:$AsCard `
        -ScriptBlock {
            param($counter)
            @{
                Values = ((Get-Counter -Counter $counter -SampleInterval 1 -MaxSamples 2).CounterSamples.CookedValue | Measure-Object -Average).Average
            }
        }
}

function New-PodeWebTable
{
    [CmdletBinding(DefaultParameterSetName='Default')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [string]
        $Message,

        [Parameter()]
        [string]
        $DataColumn,

        [Parameter()]
        [hashtable[]]
        $Columns,

        [Parameter(ParameterSetName='Dynamic')]
        [scriptblock]
        $ScriptBlock,

        [Parameter(ParameterSetName='Dynamic')]
        [object[]]
        $ArgumentList,

        [Parameter(ParameterSetName='Csv')]
        [string]
        $CsvFilePath,

        [Parameter(ParameterSetName='Dynamic')]
        [Parameter(ParameterSetName='Csv')]
        [int]
        $PageAmount = 20,

        [Parameter()]
        [string[]]
        $CssClass,

        [switch]
        $Filter,

        [switch]
        $Sort,

        [switch]
        $Click,

        [Parameter(ParameterSetName='Default')]
        [Parameter(ParameterSetName='Dynamic')]
        [Parameter(ParameterSetName='Csv')]
        [switch]
        $Paginate,

        [switch]
        $NoExport,

        [switch]
        $NoRefresh,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [Parameter(ParameterSetName='Dynamic')]
        [Parameter(ParameterSetName='Csv')]
        [switch]
        $AutoRefresh,

        [switch]
        $AsCard
    )

    $Id = Get-PodeWebElementId -Tag Table -Id $Id -Name $Name

    if (![string]::IsNullOrWhiteSpace($CsvFilePath) -and $CsvFilePath.StartsWith('.')) {
        $CsvFilePath = Join-Path (Get-PodeServerPath) $CsvFilePath
    }

    $element = @{
        ComponentType = 'Element'
        ElementType = 'Table'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        DataColumn = $DataColumn
        Columns = $Columns
        Buttons = @()
        Message = $Message
        Filter = $Filter.IsPresent
        Sort = $Sort.IsPresent
        Click = $Click.IsPresent
        IsDynamic = ($PSCmdlet.ParameterSetName -iin @('dynamic', 'csv'))
        NoExport = $NoExport.IsPresent
        AutoRefresh = $AutoRefresh.IsPresent
        NoRefresh = $NoRefresh.IsPresent
        NoAuth = $NoAuthentication.IsPresent
        CssClasses = ($CssClass -join ' ')
        Paging = @{
            Enabled = $Paginate.IsPresent
            Amount = $PageAmount
        }
    }

    $routePath = "/elements/table/$($Id)"
    $buildRoute = (($null -ne $ScriptBlock) -or ![string]::IsNullOrWhiteSpace($CsvFilePath))

    if ($buildRoute -and !(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -ScriptBlock {
            param($Data)
            $global:ElementData = $using:element

            $csvFilePath = $using:CsvFilePath
            if ([string]::IsNullOrWhiteSpace($csvFilePath)) {
                $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            }
            else {
                $result = Import-Csv -Path $csvFilePath
            }

            if ($null -eq $result) {
                $result = @()
            }

            if (($result.Length -gt 0) -and [string]::IsNullOrWhiteSpace($result[0].OutputType)) {
                $paginate = $ElementData.Paging.Enabled
                $result = ($result | Out-PodeWebTable -Id $using:Id -Columns $ElementData.Columns -Paginate:$paginate)
            }

            Write-PodeJsonResponse -Value $result
            $global:ElementData = $null
        }
    }

    if ($AsCard) {
        $element = New-PodeWebCard -Name $Name -Content $element
    }

    return $element
}

function Initialize-PodeWebTableColumn
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Key,

        [Parameter()]
        [int]
        $Width = 0
    )

    return @{
        Key = $Key
        Width = $Width
    }
}

function Add-PodeWebTableButton
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $Table,

        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Icon,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [object[]]
        $ArgumentList,

        [switch]
        $WithText
    )

    if ($Table.ComponentType -ieq 'layout') {
        $Table = @($Table.Content | Where-Object { $_.ElementType -ieq 'table' })[0]
    }

    $routePath = "/elements/table/$($Table.ID)/button/$($Name)"
    if (!(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$Table.NoAuth) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -ScriptBlock {
            param($Data)

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            if ($WebEvent.Response.ContentLength64 -eq 0) {
                Write-PodeJsonResponse -Value $result
            }
        }
    }

    $Table.Buttons += @{
        Name = $Name
        Icon = $Icon
        IsDynamic = ($null -ne $ScriptBlock)
        WithText = $WithText.IsPresent
    }
}

function New-PodeWebCodeEditor
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
        [ValidateNotNullOrEmpty()]
        [string]
        $Language = 'plaintext',

        [Parameter()]
        [ValidateSet('', 'vs', 'vs-dark', 'hc-black')]
        [string]
        $Theme,

        [Parameter()]
        [string[]]
        $CssClass,

        [switch]
        $AsCard
    )

    $Id = Get-PodeWebElementId -Tag CodeEditor -Id $Id -Name $Name -NameAsToken

    $element = @{
        ComponentType = 'Element'
        ElementType = 'Code-Editor'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        Language = $Language.ToLowerInvariant()
        Theme = $Theme
        CssClasses = ($CssClass -join ' ')
    }

    if ($AsCard) {
        $element = New-PodeWebCard -Name $Name -Content $element
    }

    return $element
}

function New-PodeWebForm
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
        $Message,

        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Content,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [object[]]
        $ArgumentList,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [switch]
        $AsCard
    )

    # ensure content are correct
    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Form can only contain layouts and/or elements'
    }

    # generate ID
    $Id = Get-PodeWebElementId -Tag Form -Id $Id -Name $Name

    $routePath = "/elements/form/$($Id)"
    if (!(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -ScriptBlock {
            param($Data)

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            Write-PodeJsonResponse -Value $result
        }
    }

    $element = @{
        ComponentType = 'Element'
        ElementType = 'Form'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        Message = $Message
        Content = $Content
        NoHeader = $NoHeader.IsPresent
        CssClasses = ($CssClass -join ' ')
    }

    if ($AsCard) {
        $element = New-PodeWebCard -Name $Name -Content $element
    }

    return $element
}

function New-PodeWebTimer
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
        $Interval = 60,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [object[]]
        $ArgumentList,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    $Id = Get-PodeWebElementId -Tag Timer -Id $Id -Name $Name

    if ($Interval -lt 10) {
        $Interval = 10
    }

    $routePath = "/elements/timer/$($Id)"
    if (!(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -ScriptBlock {
            param($Data)

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            Write-PodeJsonResponse -Value $result
        }
    }

    return @{
        ComponentType = 'Element'
        ElementType = 'Timer'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        Interval = ($Interval * 1000)
        CssClasses = ($CssClass -join ' ')
    }
}
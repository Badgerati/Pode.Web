function New-PodeWebTextbox
{
    [CmdletBinding(DefaultParameterSetName='Single')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $DisplayName,

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
        [Alias('Height')]
        [int]
        $Size = 4,

        [Parameter()]
        [int]
        $Width = 100,

        [Parameter()]
        [string]
        $HelpText,

        [Parameter(ParameterSetName='Single')]
        [string]
        $PrependText,

        [Parameter(ParameterSetName='Single')]
        [string]
        $PrependIcon,

        [Parameter(ParameterSetName='Single')]
        [string]
        $AppendText,

        [Parameter(ParameterSetName='Single')]
        [string]
        $AppendIcon,

        [Parameter()]
        [string]
        $Value,

        [Parameter(ParameterSetName='Single')]
        [scriptblock]
        $AutoComplete,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter()]
        [string[]]
        $EndpointName,

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
        $NoAuthentication,

        [switch]
        $NoForm,

        [switch]
        $Required
    )

    $Id = Get-PodeWebElementId -Tag Textbox -Id $Id -Name $Name

    # constrain number of lines shown
    if ($Size -le 0) {
        $Size = 4
    }

    # constrain width
    if ($Width -lt 0) {
        $Width = 0
    }
    if ($Width -gt 100) {
        $Width = 100
    }

    # build element
    $element = @{
        ComponentType = 'Element'
        ObjectType = 'Textbox'
        Parent = $ElementData
        Name = $Name
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name)
        ID = $Id
        Type = $Type
        Multiline = $Multiline.IsPresent
        Placeholder = $Placeholder
        Size = $Size
        Width = $Width
        Preformat = $Preformat.IsPresent
        HelpText = $HelpText
        ReadOnly = $ReadOnly.IsPresent
        IsAutoComplete = ($null -ne $AutoComplete)
        Value = $Value
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        Prepend = @{
            Enabled = (![string]::IsNullOrWhiteSpace($PrependText) -or ![string]::IsNullOrWhiteSpace($PrependIcon))
            Text = $PrependText
            Icon = $PrependIcon
        }
        Append = @{
            Enabled = (![string]::IsNullOrWhiteSpace($AppendText) -or ![string]::IsNullOrWhiteSpace($AppendIcon))
            Text = $AppendText
            Icon = $AppendIcon
        }
        NoAuthentication = $NoAuthentication.IsPresent
        NoForm = $NoForm.IsPresent
        Required = $Required.IsPresent
    }

    # create autocomplete route
    $routePath = "/components/textbox/$($Id)/autocomplete"
    if (($null -ne $AutoComplete) -and !(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication -and !$PageData.NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        if (Test-PodeIsEmpty $EndpointName) {
            $EndpointName = Get-PodeWebState -Name 'endpoint-name'
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -EndpointName $EndpointName -ScriptBlock {
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
        $DisplayName,

        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [switch]
        $NoForm,

        [switch]
        $Required
    )

    $Id = Get-PodeWebElementId -Tag File -Id $Id -Name $Name

    return @{
        ComponentType = 'Element'
        ObjectType = 'FileUpload'
        Parent = $ElementData
        Name = $Name
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name)
        ID = $Id
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoEvents = $true
        NoForm = $NoForm.IsPresent
        Required = $Required.IsPresent
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
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle
    )

    # ensure elements are correct
    if (!(Test-PodeWebContent -Content $Elements -ComponentType Element)) {
        throw 'A Paragraph can only contain elements'
    }

    $Id = Get-PodeWebElementId -Tag Para -Id $Id -RandomToken

    return @{
        ComponentType = 'Element'
        ObjectType = 'Paragraph'
        Parent = $ElementData
        ID = $Id
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Elements = $Elements
        Alignment = $Alignment.ToLowerInvariant()
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoEvents = $true
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

        [Parameter()]
        [hashtable]
        $CssStyle,

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
        ObjectType = 'CodeBlock'
        Parent = $ElementData
        ID = $Id
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Language = $Language.ToLowerInvariant()
        Scrollable = $Scrollable.IsPresent
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoEvents = $true
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
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle
    )

    $Id = Get-PodeWebElementId -Tag Code -Id $Id -RandomToken

    return @{
        ComponentType = 'Element'
        ObjectType = 'Code'
        Parent = $ElementData
        ID = $Id
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoEvents = $true
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
        $DisplayName,

        [Parameter()]
        [string]
        $Id,

        [Parameter(ParameterSetName='Multiple')]
        [string[]]
        $Options,

        [Parameter(ParameterSetName='Multiple')]
        [string[]]
        $DisplayOptions,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter(ParameterSetName='Multiple')]
        [switch]
        $Inline,

        [switch]
        $AsSwitch,

        [switch]
        $Checked,

        [switch]
        $Disabled,

        [switch]
        $NoForm,

        [switch]
        $Required
    )

    $Id = Get-PodeWebElementId -Tag Checkbox -Id $Id -Name $Name

    if (($null -eq $Options) -or ($Options.Length -eq 0)) {
        $Options = @('true')
    }

    return @{
        ComponentType = 'Element'
        ObjectType = 'Checkbox'
        Parent = $ElementData
        Name = $Name
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name)
        ID = $Id
        Options = @($Options)
        DisplayOptions = @(Protect-PodeWebValues -Value $DisplayOptions -Default $Options -EqualCount)
        Inline = $Inline.IsPresent
        AsSwitch = $AsSwitch.IsPresent
        Checked = $Checked.IsPresent
        Disabled = $Disabled.IsPresent
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoForm = $NoForm.IsPresent
        Required = $Required.IsPresent
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
        $DisplayName,

        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string[]]
        $Options,

        [Parameter()]
        [string[]]
        $DisplayOptions,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [switch]
        $Inline,

        [switch]
        $Disabled,

        [switch]
        $NoForm,

        [switch]
        $Required
    )

    $Id = Get-PodeWebElementId -Tag Radio -Id $Id -Name $Name

    return @{
        ComponentType = 'Element'
        ObjectType = 'Radio'
        Parent = $ElementData
        Name = $Name
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name)
        ID = $Id
        Options = @($Options)
        DisplayOptions = @(Protect-PodeWebValues -Value $DisplayOptions -Default $Options -EqualCount)
        Inline = $Inline.IsPresent
        Disabled = $Disabled.IsPresent
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoForm = $NoForm.IsPresent
        Required = $Required.IsPresent
    }
}

function New-PodeWebSelect
{
    [CmdletBinding(DefaultParameterSetName='Options')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $DisplayName,

        [Parameter()]
        [string]
        $Id,

        [Parameter(ParameterSetName='Options')]
        [string[]]
        $Options,

        [Parameter(ParameterSetName='Options')]
        [string[]]
        $DisplayOptions,

        [Parameter(ParameterSetName='ScriptBlock')]
        [scriptblock]
        $ScriptBlock,

        [Parameter(ParameterSetName='ScriptBlock')]
        [object[]]
        $ArgumentList,

        [Parameter()]
        [string]
        $SelectedValue,

        [int]
        $Size = 4,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [switch]
        $Multiple,

        [switch]
        $NoForm,

        [switch]
        $Required
    )

    $Id = Get-PodeWebElementId -Tag Select -Id $Id -Name $Name

    if ($Size -le 0) {
        $Size = 4
    }

    $element = @{
        ComponentType = 'Element'
        ObjectType = 'Select'
        Parent = $ElementData
        Name = $Name
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name)
        ID = $Id
        Options = @($Options)
        DisplayOptions = @(Protect-PodeWebValues -Value $DisplayOptions -Default $Options -EqualCount)
        ScriptBlock = $ScriptBlock
        IsDynamic = ($null -ne $ScriptBlock)
        SelectedValue = $SelectedValue
        Multiple = $Multiple.IsPresent
        Size = $Size
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoAuthentication = $NoAuthentication.IsPresent
        NoForm = $NoForm.IsPresent
        Required = $Required.IsPresent
    }

    $routePath = "/components/select/$($Id)"
    if (($null -ne $ScriptBlock) -and !(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication -and !$PageData.NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        if (Test-PodeIsEmpty $EndpointName) {
            $EndpointName = Get-PodeWebState -Name 'endpoint-name'
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $global:ElementData = $using:element

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            if (!(Test-PodeWebOutputWrapped -Output $result)) {
                $result = ($result | Update-PodeWebSelect -Id $using:Id)
            }

            Write-PodeJsonResponse -Value $result
            $global:ElementData = $null
        }
    }

    return $element
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
        $DisplayName,

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

        [Parameter()]
        [hashtable]
        $CssStyle,

        [switch]
        $Disabled,

        [switch]
        $ShowValue,

        [switch]
        $NoForm,

        [switch]
        $Required
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
        ObjectType = 'Range'
        Parent = $ElementData
        Name = $Name
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name)
        ID = $Id
        Value = $Value
        Min = $Min
        Max = $Max
        Disabled = $Disabled.IsPresent
        ShowValue = $ShowValue.IsPresent
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoForm = $NoForm.IsPresent
        Required = $Required.IsPresent
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

        [Parameter()]
        [hashtable]
        $CssStyle,

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
        ObjectType = 'Progress'
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
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
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
        [Alias('Alt')]
        [string]
        $Title,

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
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle
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
        ObjectType = 'Image'
        Parent = $ElementData
        ID = $Id
        Source = $Source
        Title = $Title
        Alignment = $Alignment.ToLowerInvariant()
        Height = $Height
        Width = $Width
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
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
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle
    )

    $Id = Get-PodeWebElementId -Tag Header -Id $Id -RandomToken

    return @{
        ComponentType = 'Element'
        ObjectType = 'Header'
        Parent = $ElementData
        ID = $Id
        Size = $Size
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Secondary = [System.Net.WebUtility]::HtmlEncode($Secondary)
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoEvents = $true
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
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle
    )

    $Id = Get-PodeWebElementId -Tag Quote -Id $Id -RandomToken

    return @{
        ComponentType = 'Element'
        ObjectType = 'Quote'
        Parent = $ElementData
        ID = $Id
        Alignment = $Alignment.ToLowerInvariant()
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Source = [System.Net.WebUtility]::HtmlEncode($Source)
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoEvents = $true
    }
}

function New-PodeWebList
{
    [CmdletBinding(DefaultParameterSetName='Values')]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Items')]
        [hashtable[]]
        $Items,

        [Parameter(Mandatory=$true, ParameterSetName='Values')]
        [string[]]
        $Values,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [switch]
        $Numbered
    )

    if (!(Test-PodeWebContent -Content $Items -ComponentType Element -ObjectType ListItem)) {
        throw 'Lists can only contain ListItem elements, or raw Values'
    }

    $Id = Get-PodeWebElementId -Tag List -Id $Id -RandomToken

    return @{
        ComponentType = 'Element'
        ObjectType = 'List'
        Parent = $ElementData
        ID = $Id
        Values  = @(foreach ($value in $Values) {
            [System.Net.WebUtility]::HtmlEncode($value)
        })
        Items = $Items
        Numbered = $Numbered.IsPresent
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoEvents = $true
    }
}

function New-PodeWebListItem
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Content,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle
    )

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A ListItem can only contain layouts and/or elements'
    }

    return @{
        ComponentType = 'Element'
        ObjectType = 'ListItem'
        ID = (Get-PodeWebElementId -Tag ListItem -RandomToken)
        Content = $Content
        NoEvents = $true
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
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

        [Parameter()]
        [hashtable]
        $CssStyle,

        [switch]
        $NewTab
    )

    $Id = Get-PodeWebElementId -Tag A -Id $Id -RandomToken

    return @{
        ComponentType = 'Element'
        ObjectType = 'Link'
        Parent = $ElementData
        ID = $Id
        Source = $Source
        Value = $Value
        NewTab = $NewTab.IsPresent
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
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

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter()]
        [string]
        $Pronunciation,

        [Parameter(ParameterSetName='Paragraph')]
        [switch]
        $InParagraph
    )

    return @{
        ComponentType = 'Element'
        ObjectType = 'Text'
        Parent = $ElementData
        ID = (Get-PodeWebElementId -Tag Txt -Id $Id -RandomToken)
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Pronunciation = [System.Net.WebUtility]::HtmlEncode($Pronunciation)
        Style = $Style
        InParagraph = $InParagraph.IsPresent
        Alignment = $Alignment.ToLowerInvariant()
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoEvents = $true
    }
}

function New-PodeWebLine
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle
    )

    return @{
        ComponentType = 'Element'
        ObjectType = 'Line'
        Parent = $ElementData
        ID = (Get-PodeWebElementId -Tag Line -Id $Id -RandomToken)
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoEvents = $true
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
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle
    )

    $Id = Get-PodeWebElementId -Tag Hidden -Id $Id -Name $Name

    return @{
        ComponentType = 'Element'
        ObjectType = 'Hidden'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        Value = $Value
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoEvents = $true
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
        $DisplayName,

        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [string]
        $HelpText,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter()]
        [string]
        $PlaceholderUsername,

        [Parameter()]
        [string]
        $PlaceholderPassword,

        [switch]
        $ReadOnly,

        [switch]
        $NoLabels,

        [switch]
        $Required
    )

    $Id = Get-PodeWebElementId -Tag Cred -Id $Id -Name $Name

    return @{
        ComponentType = 'Element'
        ObjectType = 'Credential'
        Parent = $ElementData
        Name = $Name
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name)
        ID = $Id
        HelpText = $HelpText
        ReadOnly = $ReadOnly.IsPresent
        NoLabels = $NoLabels.IsPresent
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        Placeholders = @{
            Username = (Protect-PodeWebValue -Value $PlaceholderUsername -Default 'Username')
            Password = (Protect-PodeWebValue -Value $PlaceholderPassword -Default 'Password')
        }
        Required = $Required.IsPresent
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
        $DisplayName,

        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [string]
        $HelpText,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [switch]
        $ReadOnly,

        [switch]
        $NoLabels,

        [switch]
        $Required
    )

    $Id = Get-PodeWebElementId -Tag DateTime -Id $Id -Name $Name

    return @{
        ComponentType = 'Element'
        ObjectType = 'DateTime'
        Parent = $ElementData
        Name = $Name
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name)
        ID = $Id
        HelpText = $HelpText
        ReadOnly = $ReadOnly.IsPresent
        NoLabels = $NoLabels.IsPresent
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        Required = $Required.IsPresent
    }
}

function New-PodeWebMinMax
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $DisplayName,

        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [string]
        $HelpText,

        [Parameter()]
        [double]
        $MinValue = 0,

        [Parameter()]
        [double]
        $MaxValue = 0,

        [Parameter(ParameterSetName='Single')]
        [string]
        $PrependText,

        [Parameter(ParameterSetName='Single')]
        [string]
        $PrependIcon,

        [Parameter(ParameterSetName='Single')]
        [string]
        $AppendText,

        [Parameter(ParameterSetName='Single')]
        [string]
        $AppendIcon,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [switch]
        $ReadOnly,

        [switch]
        $NoLabels,

        [switch]
        $Required
    )

    $Id = Get-PodeWebElementId -Tag MinMax -Id $Id -Name $Name

    return @{
        ComponentType = 'Element'
        ObjectType = 'MinMax'
        Parent = $ElementData
        Name = $Name
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name)
        ID = $Id
        Values = @{
            Min = $MinValue
            Max = $MaxValue
        }
        HelpText = $HelpText
        ReadOnly = $ReadOnly.IsPresent
        NoLabels = $NoLabels.IsPresent
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        Prepend = @{
            Enabled = (![string]::IsNullOrWhiteSpace($PrependText) -or ![string]::IsNullOrWhiteSpace($PrependIcon))
            Text = $PrependText
            Icon = $PrependIcon
        }
        Append = @{
            Enabled = (![string]::IsNullOrWhiteSpace($AppendText) -or ![string]::IsNullOrWhiteSpace($AppendIcon))
            Text = $AppendText
            Icon = $AppendIcon
        }
        Required = $Required.IsPresent
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
        ObjectType = 'Raw'
        Parent = $ElementData
        Value = $Value
        NoEvents = $true
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
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter()]
        [string[]]
        $EndpointName,

        [Parameter(ParameterSetName='ScriptBlock')]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [switch]
        $IconOnly,

        [switch]
        $NewLine,

        [Parameter(ParameterSetName='Url')]
        [switch]
        $NewTab
    )

    $Id = Get-PodeWebElementId -Tag Btn -Id $Id -Name $Name
    $colourType = Convert-PodeWebColourToClass -Colour $Colour

    $element = @{
        ComponentType = 'Element'
        ObjectType = 'Button'
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
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NewLine = $NewLine.IsPresent
        NewTab = $NewTab.IsPresent
        NoEvents = $true
        NoAuthentication = $NoAuthentication.IsPresent
    }

    $routePath = "/components/button/$($Id)"
    if (($null -ne $ScriptBlock) -and !(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication -and !$PageData.NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        if (Test-PodeIsEmpty $EndpointName) {
            $EndpointName = Get-PodeWebState -Name 'endpoint-name'
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $global:ElementData = $using:element

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            if (!$WebEvent.Response.Headers.ContainsKey('Content-Disposition')) {
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
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle
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
        ObjectType = 'Alert'
        Parent = $ElementData
        ID = $Id
        Type = $Type
        ClassType = $classType
        IconType = $iconType
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        Content = $Content
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
    }
}

function New-PodeWebIcon
{
    [CmdletBinding(DefaultParameterSetName='Rotate')]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Colour,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter()]
        [string]
        $Title,

        [Parameter(ParameterSetName='Flip')]
        [ValidateSet('Horizontal', 'Vertical')]
        [string]
        $Flip,

        [Parameter(ParameterSetName='Rotate')]
        [ValidateSet(0, 45, 90, 135, 180, 225, 270, 315)]
        [int]
        $Rotate = 0,

        [switch]
        $Spin
    )

    $Id = Get-PodeWebElementId -Tag Icon -Id $Id -RandomToken

    if (![string]::IsNullOrWhiteSpace($Colour)) {
        $Colour = $Colour.ToLowerInvariant()
    }

    return @{
        ComponentType = 'Element'
        ObjectType = 'Icon'
        Parent = $ElementData
        ID = $Id
        Name = $Name
        Colour = $Colour
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        Title = $Title
        Flip = $Flip
        Rotate = $Rotate
        Spin = $Spin.IsPresent
    }
}

function New-PodeWebSpinner
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [string]
        $Colour,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter()]
        [string]
        $Title
    )

    if (![string]::IsNullOrWhiteSpace($Colour)) {
        $Colour = $Colour.ToLowerInvariant()
    }

    return @{
        ComponentType = 'Element'
        ObjectType = 'Spinner'
        Parent = $ElementData
        ID = (Get-PodeWebElementId -Tag Spinner -Id $Id -RandomToken)
        Colour = $Colour
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        Title = $Title
        NoEvents = $true
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
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle
    )

    $Id = Get-PodeWebElementId -Tag Alert -Id $Id -RandomToken
    $colourType = Convert-PodeWebColourToClass -Colour $Colour

    return @{
        ComponentType = 'Element'
        ObjectType = 'Badge'
        Parent = $ElementData
        ID = $Id
        Colour = $Colour
        ColourType = $ColourType.ToLowerInvariant()
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
    }
}

function New-PodeWebComment
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

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
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle
    )

    $Id = Get-PodeWebElementId -Tag Comment -Id $Id -RandomToken

    return @{
        ComponentType = 'Element'
        ObjectType = 'Comment'
        Parent = $ElementData
        ID = $Id
        Icon = $Icon
        Username = $Username
        Message = $Message
        TimeStamp = $TimeStamp
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoEvents = $true
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

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter()]
        [string[]]
        $EndpointName,

        [Parameter()]
        [int]
        $MinX = [int]::MinValue,

        [Parameter()]
        [int]
        $MaxX = [int]::MaxValue,

        [Parameter()]
        [int]
        $MinY = [int]::MinValue,

        [Parameter()]
        [int]
        $MaxY = [int]::MaxValue,

        [Parameter()]
        [int]
        $RefreshInterval = 60,

        [Parameter()]
        [string[]]
        $Colours,

        [switch]
        $Append,

        [switch]
        $TimeLabels,

        [switch]
        $AutoRefresh,

        [switch]
        $NoRefresh,

        [switch]
        $NoLegend,

        [switch]
        $AsCard
    )

    $Id = Get-PodeWebElementId -Tag Chart -Id $Id -Name $Name

    if ($MaxItems -lt 0) {
        $MaxItems = 0
    }

    if ($RefreshInterval -le 0) {
        $RefreshInterval = 60
    }

    if (($null -ne $Colours) -and ($Colours.Length -gt 0)) {
        foreach ($clr in $Colours) {
            if ($clr -inotmatch '^\s*#(([a-f\d])([a-f\d])([a-f\d])){1,2}\s*$') {
                throw "Invalid colour supplied, should be hex format: $($clr)"
            }
        }
    }

    $element = @{
        ComponentType = 'Element'
        ObjectType = 'Chart'
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
        RefreshInterval = ($RefreshInterval * 1000)
        NoRefresh = $NoRefresh.IsPresent
        NoLegend = $NoLegend.IsPresent
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        Min = @{
            X = $MinX
            Y = $MinY
        }
        Max = @{
            X = $MaxX
            Y = $MaxY
        }
        NoEvents = $true
        NoAuthentication = $NoAuthentication.IsPresent
        Colours = ($Colours -join ',')
    }

    $routePath = "/components/chart/$($Id)"
    if (!(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication -and !$PageData.NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        if (Test-PodeIsEmpty $EndpointName) {
            $EndpointName = Get-PodeWebState -Name 'endpoint-name'
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $global:ElementData = $using:element

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            if (!(Test-PodeWebOutputWrapped -Output $result)) {
                $result = ($result | Update-PodeWebChart -Id $using:Id)
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
        [hashtable]
        $CssStyle,

        [Parameter()]
        [int]
        $MaxItems = 30,

        [Parameter()]
        [int]
        $MinX = [int]::MinValue,

        [Parameter()]
        [int]
        $MaxX = [int]::MaxValue,

        [Parameter()]
        [int]
        $MinY = [int]::MinValue,

        [Parameter()]
        [int]
        $MaxY = [int]::MaxValue,

        [Parameter()]
        [string[]]
        $Colours,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [switch]
        $NoLegend,

        [switch]
        $AsCard
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        $Name = Split-Path -Path $Counter -Leaf
    }

    if ($MaxItems -le 0) {
        $MaxItems = 30
    }

    New-PodeWebChart `
        -Name $Name `
        -Type Line `
        -MaxItems $MaxItems `
        -ArgumentList $Counter `
        -Append `
        -TimeLabels `
        -AutoRefresh `
        -CssClass $CssClass `
        -CssStyle $CssStyle `
        -MinX $MinX `
        -MinY $MinY `
        -MaxX $MaxX `
        -MaxY $MaxY `
        -Colours $Colours `
        -NoAuthentication:$NoAuthentication `
        -AsCard:$AsCard `
        -NoLegend:$NoLegend `
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
        [Alias('PageAmount')]
        [int]
        $PageSize = 20,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter()]
        [string[]]
        $EndpointName,

        [Parameter()]
        [scriptblock]
        $ClickScriptBlock,

        [Parameter()]
        [int]
        $RefreshInterval = 60,

        [switch]
        $Filter,

        [switch]
        $SimpleFilter,

        [switch]
        $Sort,

        [switch]
        $SimpleSort,

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
        $CsvFilePath = Join-PodeWebPath (Get-PodeServerPath) $CsvFilePath
    }

    if ($RefreshInterval -le 0) {
        $RefreshInterval = 60
    }

    $element = @{
        ComponentType = 'Element'
        ObjectType = 'Table'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        DataColumn = $DataColumn
        Columns = $Columns
        Buttons = @()
        Message = $Message
        Filter = @{
            Enabled = ($Filter.IsPresent -or $SimpleFilter.IsPresent)
            Simple = $SimpleFilter.IsPresent
        }
        Sort = @{
            Enabled = ($Sort.IsPresent -or $SimpleSort.IsPresent)
            Simple = $SimpleSort.IsPresent
        }
        Click = ($Click.IsPresent -or ($null -ne $ClickScriptBlock))
        ClickIsDynamic = ($null -ne $ClickScriptBlock)
        IsDynamic = ($PSCmdlet.ParameterSetName -iin @('dynamic', 'csv'))
        NoExport = $NoExport.IsPresent
        AutoRefresh = $AutoRefresh.IsPresent
        RefreshInterval = ($RefreshInterval * 1000)
        NoRefresh = $NoRefresh.IsPresent
        NoAuthentication = $NoAuthentication.IsPresent
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        Paging = @{
            Enabled = $Paginate.IsPresent
            Size = $PageSize
        }
        NoEvents = $true
    }

    # auth an endpoint
    $auth = $null
    if (!$NoAuthentication -and !$PageData.NoAuthentication) {
        $auth = (Get-PodeWebState -Name 'auth')
    }

    if (Test-PodeIsEmpty $EndpointName) {
        $EndpointName = Get-PodeWebState -Name 'endpoint-name'
    }

    # main table data script
    $routePath = "/components/table/$($Id)"
    $buildRoute = (($null -ne $ScriptBlock) -or ![string]::IsNullOrWhiteSpace($CsvFilePath))

    if ($buildRoute -and !(Test-PodeWebRoute -Path $routePath)) {
        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $global:ElementData = $using:element

            $csvFilePath = $using:CsvFilePath
            if ([string]::IsNullOrWhiteSpace($csvFilePath)) {
                $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            }
            else {
                $result = Import-Csv -Path $csvFilePath

                $filter = $WebEvent.Data['Filter']
                if (![string]::IsNullOrWhiteSpace($filter)) {
                    $filter = "*$($filter)*"
                    $result = @($result | Where-Object { ($_.psobject.properties.value -ilike $filter).length -gt 0 })
                }
            }

            if ($null -eq $result) {
                $result = @()
            }

            if (!(Test-PodeWebOutputWrapped -Output $result)) {
                $paginate = $ElementData.Paging.Enabled
                $result = ($result | Update-PodeWebTable -Id $using:Id -Columns $ElementData.Columns -Paginate:$paginate)
            }

            Write-PodeJsonResponse -Value $result
            $global:ElementData = $null
        }
    }

    # table row click
    $clickPath = "$($routePath)/click"
    if (($null -ne $ClickScriptBlock) -and !(Test-PodeWebRoute -Path $clickPath)) {
        Add-PodeRoute -Method Post -Path $clickPath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $global:ElementData = $using:element

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ClickScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            if (!$WebEvent.Response.Headers.ContainsKey('Content-Disposition')) {
                Write-PodeJsonResponse -Value $result
            }

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
        $Width = 0,

        [Parameter()]
        [ValidateSet('Left', 'Right', 'Center')]
        [string]
        $Alignment = 'Left',

        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Icon
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        $Name = $Key
    }

    return @{
        Key = $Key
        Width = $Width
        Alignment = $Alignment.ToLowerInvariant()
        Name = $Name
        Icon = $Icon
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

        [Parameter()]
        [string[]]
        $EndpointName,

        [switch]
        $WithText
    )

    if ($Table.ComponentType -ieq 'layout') {
        $Table = @($Table.Content | Where-Object { $_.ObjectType -ieq 'table' })[0]
    }

    $routePath = "/components/table/$($Table.ID)/button/$($Name)"
    if (!(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$Table.NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        if (Test-PodeIsEmpty $EndpointName) {
            $EndpointName = Get-PodeWebState -Name 'endpoint-name'
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $global:ElementData = $using:Table

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            if (!$WebEvent.Response.Headers.ContainsKey('Content-Disposition')) {
                Write-PodeJsonResponse -Value $result
            }

            $global:ElementData = $null
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
        [Parameter(Mandatory=$true)]
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
        [string]
        $Value,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter()]
        [scriptblock]
        $Upload,

        [Parameter()]
        [object[]]
        $ArgumentList,

        [Parameter()]
        [string[]]
        $EndpointName,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [switch]
        $ReadOnly,

        [switch]
        $AsCard
    )

    $Id = Get-PodeWebElementId -Tag CodeEditor -Id $Id -Name $Name
    $uploadable = ($null -ne $Upload)

    $element = @{
        ComponentType = 'Element'
        ObjectType = 'Code-Editor'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        Language = $Language.ToLowerInvariant()
        Theme = $Theme
        Value = [System.Net.WebUtility]::HtmlEncode($Value)
        ReadOnly = $ReadOnly.IsPresent
        Uploadable = $uploadable
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoAuthentication = $NoAuthentication.IsPresent
    }

    # upload route
    $routePath = "/components/code-editor/$($Id)/upload"
    if ($uploadable -and !(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication -and !$PageData.NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        if (Test-PodeIsEmpty $EndpointName) {
            $EndpointName = Get-PodeWebState -Name 'endpoint-name'
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $global:ElementData = $using:element

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:Upload -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
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
        [hashtable]
        $CssStyle,

        [Parameter()]
        [string[]]
        $EndpointName,

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

    $element = @{
        ComponentType = 'Element'
        ObjectType = 'Form'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        Message = $Message
        Content = $Content
        NoHeader = $NoHeader.IsPresent
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoEvents = $true
        NoAuthentication = $NoAuthentication.IsPresent
    }

    $routePath = "/components/form/$($Id)"
    if (!(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication -and !$PageData.NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        if (Test-PodeIsEmpty $EndpointName) {
            $EndpointName = Get-PodeWebState -Name 'endpoint-name'
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $EndpointName -ScriptBlock {
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

    if ($AsCard) {
        $element = New-PodeWebCard -Name $Name -Content $element
    }

    return $element
}

function New-PodeWebTimer
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
        [hashtable]
        $CssStyle,

        [Parameter()]
        [string[]]
        $EndpointName,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    $Id = Get-PodeWebElementId -Tag Timer -Id $Id -Name $Name -NameAsToken

    if ($Interval -lt 10) {
        $Interval = 10
    }

    $element = @{
        ComponentType = 'Element'
        ObjectType = 'Timer'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        Interval = ($Interval * 1000)
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoEvents = $true
        NoAuthentication = $NoAuthentication.IsPresent
    }

    $routePath = "/components/timer/$($Id)"
    if (!(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication -and !$PageData.NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        if (Test-PodeIsEmpty $EndpointName) {
            $EndpointName = Get-PodeWebState -Name 'endpoint-name'
        }

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $EndpointName -ScriptBlock {
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

    $element = New-PodeWebContainer -Content $element -Hide
    return $element
}

function New-PodeWebTile
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
        $Icon,

        [Parameter(Mandatory=$true, ParameterSetName='ScriptBlock')]
        [scriptblock]
        $ScriptBlock,

        [Parameter(Mandatory=$true, ParameterSetName='Content')]
        [hashtable[]]
        $Content,

        [Parameter()]
        [object[]]
        $ArgumentList,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter()]
        [string[]]
        $EndpointName,

        [Parameter()]
        [scriptblock]
        $ClickScriptBlock,

        [Parameter()]
        [ValidateSet('Blue', 'Grey', 'Green', 'Red', 'Yellow', 'Cyan', 'Light', 'Dark')]
        [string]
        $Colour = 'Blue',

        [Parameter()]
        [int]
        $RefreshInterval = 60,

        [switch]
        $NoRefresh,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [Parameter()]
        [switch]
        $AutoRefresh,

        [switch]
        $NewLine
    )

    # ensure content are correct
    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Tile can only contain layouts and/or elements'
    }

    $Id = Get-PodeWebElementId -Tag Tile -Id $Id -Name $Name
    $colourType = Convert-PodeWebColourToClass -Colour $Colour

    if ($RefreshInterval -le 0) {
        $RefreshInterval = 60
    }

    $element = @{
        ComponentType = 'Element'
        ObjectType = 'Tile'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        Click = ($null -ne $ClickScriptBlock)
        IsDynamic = ($null -ne $ScriptBlock)
        Content = $Content
        Icon = $Icon
        Colour = $Colour
        ColourType = $ColourType
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        AutoRefresh = $AutoRefresh.IsPresent
        RefreshInterval = ($RefreshInterval * 1000)
        NoRefresh = $NoRefresh.IsPresent
        NewLine = $NewLine.IsPresent
        NoEvents = $true
        NoAuthentication = $NoAuthentication.IsPresent
    }

    # auth an endpoint
    $auth = $null
    if (!$NoAuthentication -and !$PageData.NoAuthentication) {
        $auth = (Get-PodeWebState -Name 'auth')
    }

    if (Test-PodeIsEmpty $EndpointName) {
        $EndpointName = Get-PodeWebState -Name 'endpoint-name'
    }

    # main route to load tile value
    $routePath = "/components/tile/$($Id)"
    if (($null -ne $ScriptBlock) -and !(Test-PodeWebRoute -Path $routePath)) {
        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $global:ElementData = $using:element

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            if (!(Test-PodeWebOutputWrapped -Output $result)) {
                $result = ($result | Update-PodeWebTile -Id $using:Id)
            }

            Write-PodeJsonResponse -Value $result
            $global:ElementData = $null
        }
    }

    # tile click route
    $clickPath = "$($routePath)/click"
    if (($null -ne $ClickScriptBlock) -and !(Test-PodeWebRoute -Path $clickPath)) {
        Add-PodeRoute -Method Post -Path $clickPath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $global:ElementData = $using:element

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ClickScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            if (!$WebEvent.Response.Headers.ContainsKey('Content-Disposition')) {
                Write-PodeJsonResponse -Value $result
            }

            $global:ElementData = $null
        }
    }

    return $element
}

function New-PodeWebFileStream
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Url,

        [Parameter()]
        [int]
        $Height = 20,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter()]
        [int]
        $Interval = 10,

        [Parameter()]
        [string]
        $Icon,

        [switch]
        $NoHeader
    )

    $Id = Get-PodeWebElementId -Tag FileStream -Id $Id -Name $Name

    if ($Height -le 0) {
        $Height = 20
    }

    if ($Interval -le 0) {
        $Interval = 10
    }

    $element = @{
        ComponentType = 'Element'
        ObjectType = 'FileStream'
        Parent = $ElementData
        Name = $Name
        ID = $Id
        Height = $Height
        Url = $Url
        Interval = ($Interval * 1000)
        Icon = $Icon
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoHeader = $NoHeader.IsPresent
    }

    return $element
}

function New-PodeWebIFrame
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Url,

        [Parameter()]
        [string]
        $Title,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle
    )

    if ([string]::IsNullOrWhiteSpace($Title)) {
        $Title = $Name
    }

    return @{
        ComponentType = 'Element'
        ObjectType = 'iFrame'
        Parent = $ElementData
        Name = $Name
        ID = (Get-PodeWebElementId -Tag iFrame -Id $Id -Name $Name)
        Url = $Url
        Title = $Title
        NoEvents = $true
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
    }
}

function New-PodeWebAudio
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [hashtable[]]
        $Source,

        [Parameter()]
        [hashtable[]]
        $Track,

        [Parameter()]
        [string]
        $NotSupportedText,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter()]
        [string]
        $Width = 20,

        [switch]
        $Muted,

        [switch]
        $AutoPlay,

        [switch]
        $AutoBuffer,

        [switch]
        $Loop,

        [switch]
        $NoControls
    )

    if (!(Test-PodeWebContent -Content $Source -ComponentType Element -ObjectType AudioSource)) {
        throw 'Audio sources can only contain AudioSource elements'
    }

    if (!(Test-PodeWebContent -Content $Track -ComponentType Element -ObjectType MediaTrack)) {
        throw 'Audio tracks can only contain MediaTrack elements'
    }

    return @{
        ComponentType = 'Element'
        ObjectType = 'Audio'
        Parent = $ElementData
        Name = $Name
        ID = (Get-PodeWebElementId -Tag Audio -Id $Id -Name $Name -NameAsToken)
        Width = (ConvertTo-PodeWebSize -Value $Width -Default 20 -Type '%')
        Sources = $Source
        Tracks = $Track
        NotSupportedText = (Protect-PodeWebValue -Value $NotSupportedText -Default 'Your browser does not support the audio element')
        Muted = $Muted.IsPresent
        AutoPlay = $AutoPlay.IsPresent
        AutoBuffer = $AutoBuffer.IsPresent
        Loop = $Loop.IsPresent
        NoControls = $NoControls.IsPresent
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
    }
}

function New-PodeWebAudioSource
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Url
    )

    $type = [string]::Empty

    switch (($Url -split '\.')[-1].ToLowerInvariant()) {
        'mp3' { $type = 'audio/mpeg' }
        'ogg' { $type = 'audio/ogg' }
        'wav' { $type = 'audio/wav' }
    }

    return @{
        ComponentType = 'Element'
        ObjectType = 'AudioSource'
        Url = $Url
        Type = $type
        NoEvents = $true
    }
}

function New-PodeWebMediaTrack
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Url,

        [Parameter()]
        [string]
        $Language,

        [Parameter()]
        [string]
        $Title,

        [Parameter()]
        [ValidateSet('captions', 'chapters', 'descriptions', 'metadata', 'subtitles')]
        [string]
        $Type = 'subtitles',

        [switch]
        $Default
    )

    if (($Url -split '\.')[-1] -ieq 'vtt') {
        throw "Invalid media track file format supplied, expected a .vtt file"
    }

    if (($Type -ieq 'subtitles') -and [string]::IsNullOrWhiteSpace($Language)) {
        throw "A language is required for subtitle tracks"
    }

    return @{
        ComponentType = 'Element'
        ObjectType = 'MediaTrack'
        Url = $Url
        Language = $Language
        Title = $Title
        Type = $Type.ToLowerInvariant()
        Default = $Default.IsPresent
        NoEvents = $true
    }
}
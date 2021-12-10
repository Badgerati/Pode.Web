function New-PodeWebGrid
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Cells,

        [Parameter()]
        [int]
        $Width = 0,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [switch]
        $Vertical
    )

    if (!(Test-PodeWebContent -Content $Cells -ComponentType Layout -ObjectType Cell)) {
        throw 'A Grid can only contain Cell layouts'
    }

    if ($Vertical) {
        $Width = 1
    }

    return @{
        ComponentType = 'Layout'
        ObjectType = 'Grid'
        Cells = $Cells
        Width = $Width
        ID = (Get-PodeWebElementId -Tag Grid -Id $Id -RandomToken)
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
    }
}

function New-PodeWebCell
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Content,

        [Parameter()]
        [ValidateRange(1, 12)]
        [int]
        $Width,

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

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Grid Cell can only contain layouts and/or elements'
    }

    return @{
        ComponentType = 'Layout'
        ObjectType = 'Cell'
        Content = $Content
        Width = $Width
        ID = (Get-PodeWebElementId -Tag Cell -Id $Id -RandomToken)
        Alignment = $Alignment.ToLowerInvariant()
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
    }
}

function New-PodeWebTabs
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Tabs,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter()]
        [int]
        $CycleInterval = 15,

        [switch]
        $Cycle
    )

    if (!(Test-PodeWebContent -Content $Tabs -ComponentType Layout -ObjectType Tab)) {
        throw 'Tabs can only contain Tab layouts'
    }

    if ($CycleInterval -lt 10) {
        $CycleInterval = 10
    }

    return @{
        ComponentType = 'Layout'
        ObjectType = 'Tabs'
        ID = (Get-PodeWebElementId -Tag Tabs -Id $Id -RandomToken)
        Tabs = $Tabs
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        Cycle = @{
            Enabled = $Cycle.IsPresent
            Interval = ($CycleInterval * 1000)
        }
    }
}

function New-PodeWebTab
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $DisplayName,

        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Layouts,

        [Parameter()]
        [string]
        $Icon,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle
    )

    if (!(Test-PodeWebContent -Content $Tabs -ComponentType Layout)) {
        throw 'A Tab can only contain layouts'
    }

    return @{
        ComponentType = 'Layout'
        ObjectType = 'Tab'
        Name = $Name
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name -Encode)
        ID = (Get-PodeWebElementId -Tag Tab -Id $Id -Name $Name)
        Layouts = $Layouts
        Icon = $Icon
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
    }
}

function New-PodeWebCard
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $DisplayName,

        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Content,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter()]
        [string]
        $Icon,

        [switch]
        $NoTitle,

        [switch]
        $NoHide
    )

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Card can only contain layouts and/or elements'
    }

    return @{
        ComponentType = 'Layout'
        ObjectType = 'Card'
        Name = $Name
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name -Encode)
        ID = (Get-PodeWebElementId -Tag Card -Id $Id -Name $Name -NameAsToken)
        Content = $Content
        NoTitle = $NoTitle.IsPresent
        NoHide  = $NoHide.IsPresent
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        Icon = $Icon
    }
}

function New-PodeWebContainer
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Content,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [switch]
        $NoBackground,

        [switch]
        $Hide
    )

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Container can only contain layouts and/or elements'
    }

    return @{
        ComponentType = 'Layout'
        ObjectType = 'Container'
        ID = (Get-PodeWebElementId -Tag Container -Id $Id -NameAsToken)
        Content = $Content
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        NoBackground = $NoBackground.IsPresent
        Hide = $Hide.IsPresent
    }
}

function New-PodeWebModal
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
        [hashtable[]]
        $Content,

        [Parameter()]
        [string]
        $Icon,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $SubmitText = 'Submit',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $CloseText = 'Close',

        [Parameter()]
        [ValidateSet('Small', 'Medium', 'Large')]
        [string]
        $Size = 'Small',

        [Parameter()]
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
        [ValidateSet('Get', 'Post')]
        [string]
        $Method = 'Post',

        [Parameter()]
        [string]
        $Action,

        [switch]
        $AsForm,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Modal can only contain layouts and/or elements'
    }

    # generate ID
    $Id = Get-PodeWebElementId -Tag Modal -Id $Id -Name $Name

    $routePath = "/components/modal/$($Id)"
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

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            Write-PodeJsonResponse -Value $result
        }
    }

    return @{
        ComponentType = 'Layout'
        ObjectType = 'Modal'
        Name = $Name
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name -Encode)
        ID = $Id
        Icon = $Icon
        Content = $Content
        CloseText = [System.Net.WebUtility]::HtmlEncode($CloseText)
        SubmitText = [System.Net.WebUtility]::HtmlEncode($SubmitText)
        Size = $Size
        AsForm = $AsForm.IsPresent
        ShowSubmit = ($null -ne $ScriptBlock)
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        Method = $Method
        Action = (Protect-PodeWebValue -Value $Action -Default $routePath)
    }
}

function New-PodeWebHero
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Title,

        [Parameter(Mandatory=$true)]
        [string]
        $Message,

        [Parameter()]
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
        throw 'A Hero can only contain layouts and/or elements'
    }

    return @{
        ComponentType = 'Layout'
        ObjectType = 'Hero'
        ID = (Get-PodeWebElementId -Tag Hero -Id $Id -RandomToken)
        Title = [System.Net.WebUtility]::HtmlEncode($Title)
        Message = [System.Net.WebUtility]::HtmlEncode($Message)
        Content = $Content
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
    }
}

function New-PodeWebCarousel
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Slides,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle
    )

    if (!(Test-PodeWebContent -Content $Slides -ComponentType Layout -ObjectType Slide)) {
        throw 'A Carousel can only contain Slide layouts'
    }

    return @{
        ComponentType = 'Layout'
        ObjectType = 'Carousel'
        ID = (Get-PodeWebElementId -Tag Carousel -Id $Id -NameAsToken)
        Slides = $Slides
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
    }
}

function New-PodeWebSlide
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Content,

        [Parameter()]
        [string]
        $Title,

        [Parameter()]
        [string]
        $Message,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle
    )

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Slide can only contain layouts and/or elements'
    }

    return @{
        ComponentType = 'Layout'
        ObjectType = 'Slide'
        Content = $Content
        ID = (Get-PodeWebElementId -Tag Slide -RandomToken)
        Title = [System.Net.WebUtility]::HtmlEncode($Title)
        Message = [System.Net.WebUtility]::HtmlEncode($Message)
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
    }
}

function New-PodeWebSteps
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
        [hashtable[]]
        $Steps,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [object[]]
        $ArgumentList,

        [Parameter()]
        [string[]]
        $EndpointName,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    if (!(Test-PodeWebContent -Content $Steps -ComponentType Layout -ObjectType Step)) {
        throw 'Steps can only contain Step layouts'
    }

    # generate ID
    $Id = Get-PodeWebElementId -Tag Steps -Id $Id -Name $Name

    # add route
    $routePath = "/components/steps/$($Id)"
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

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            Write-PodeJsonResponse -Value $result
        }
    }

    return @{
        ComponentType = 'Layout'
        ObjectType = 'Steps'
        ID = $Id
        Steps = $Steps
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
    }
}

function New-PodeWebStep
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
        [hashtable[]]
        $Content,

        [Parameter()]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [object[]]
        $ArgumentList,

        [Parameter()]
        [string]
        $Icon,

        [Parameter()]
        [string[]]
        $EndpointName,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Step can only contain layouts and/or elements'
    }

    # generate ID
    $Id = Get-PodeWebElementId -Tag Step -Name $Name

    # add route
    $routePath = "/components/step/$($Id)"
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

            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            if ($null -eq $result) {
                $result = @()
            }

            Write-PodeJsonResponse -Value $result
        }
    }

    return @{
        ComponentType = 'Layout'
        ObjectType = 'Step'
        Name = $Name
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name -Encode)
        ID = $Id
        Content = $Content
        Icon = $Icon
        IsDynamic = ($null -ne $ScriptBlock)
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
    }
}

function Set-PodeWebBreadcrumb
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable[]]
        $Items = @()
    )

    if (($null -eq $Items)) {
        $Items = @()
    }

    if (!(Test-PodeWebContent -Content $Items -ComponentType Layout -ObjectType BreadcrumbItem)) {
        throw 'A Breadcrumb can only contain breadcrumb item layouts'
    }

    $foundActive = $false
    foreach ($item in $Items) {
        if ($foundActive -and $item.Active) {
            throw "Cannot have two active breadcrumb items"
        }

        $foundActive = $item.Active
    }

    return @{
        ComponentType = 'Layout'
        ObjectType = 'Breadcrumb'
        Items = $Items
        NoEvents = $true
    }
}

function New-PodeWebBreadcrumbItem
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $DisplayName,

        [Parameter(Mandatory=$true)]
        [string]
        $Url,

        [switch]
        $Active
    )

    return @{
        ComponentType = 'Layout'
        ObjectType = 'BreadcrumbItem'
        Name = $Name
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name -Encode)
        Url = (Add-PodeWebAppPath -Url $Url)
        Active = $Active.IsPresent
        NoEvents = $true
    }
}

function New-PodeWebAccordion
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Bellows,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle,

        [Parameter()]
        [int]
        $CycleInterval = 15,

        [Parameter()]
        [ValidateSet('Normal', 'Collapsed', 'Expanded')]
        [string]
        $Mode = 'Normal',

        [switch]
        $Cycle
    )

    if (!(Test-PodeWebContent -Content $Bellows -ComponentType Layout -ObjectType Bellow)) {
        throw 'Accordions can only contain Bellow layouts'
    }

    if ($CycleInterval -lt 10) {
        $CycleInterval = 10
    }

    return @{
        ComponentType = 'Layout'
        ObjectType = 'Accordion'
        ID = (Get-PodeWebElementId -Tag Accordion -Id $Id -NameAsToken)
        Bellows = $Bellows
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
        Mode = $Mode
        Cycle = @{
            Enabled = $Cycle.IsPresent
            Interval = ($CycleInterval * 1000)
        }
    }
}

function New-PodeWebBellow
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
        [hashtable[]]
        $Content,

        [Parameter()]
        [string]
        $Icon,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [hashtable]
        $CssStyle
    )

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Bellow can only contain layouts and/or elements'
    }

    return @{
        ComponentType = 'Layout'
        ObjectType = 'Bellow'
        Name = $Name
        DisplayName = (Protect-PodeWebValue -Value $DisplayName -Default $Name -Encode)
        ID = (Get-PodeWebElementId -Tag Bellow -Name $Name)
        Content = $Content
        Icon = $Icon
        CssClasses = ($CssClass -join ' ')
        CssStyles = (ConvertTo-PodeWebStyles -Style $CssStyle)
    }
}
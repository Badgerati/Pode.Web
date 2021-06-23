function New-PodeWebGrid
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Cells,

        [Parameter()]
        [int]
        $Width = 0,

        [Parameter()]
        [string[]]
        $CssClass,

        [switch]
        $Vertical
    )

    if (!(Test-PodeWebContent -Content $Cells -ComponentType Layout -LayoutType Cell)) {
        throw 'A Grid can only contain Cell layouts'
    }

    if ($Vertical) {
        $Width = 1
    }

    return @{
        ComponentType = 'Layout'
        LayoutType = 'Grid'
        Cells = $Cells
        Width = $Width
        CssClasses = ($CssClass -join ' ')
    }
}

function New-PodeWebCell
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Content,

        [Parameter()]
        [ValidateRange(1, 12)]
        [int]
        $Width
    )

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Grid Cell can only contain layouts and/or elements'
    }

    return @{
        ComponentType = 'Layout'
        LayoutType = 'Cell'
        Content = $Content
        Width = $Width
    }
}

function New-PodeWebTabs
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Tabs,

        [Parameter()]
        [string[]]
        $CssClass,

        [Parameter()]
        [int]
        $CycleInterval = 15,

        [switch]
        $Cycle
    )

    if (!(Test-PodeWebContent -Content $Tabs -ComponentType Layout -LayoutType Tab)) {
        throw 'Tabs can only contain Tab layouts'
    }

    if ($CycleInterval -lt 10) {
        $CycleInterval = 10
    }

    return @{
        ComponentType = 'Layout'
        LayoutType = 'Tabs'
        Tabs = $Tabs
        CssClasses = ($CssClass -join ' ')
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
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Layouts
    )

    if (!(Test-PodeWebContent -Content $Tabs -ComponentType Layout)) {
        throw 'A Tab can only contain layouts'
    }

    return @{
        ComponentType = 'Layout'
        LayoutType = 'Tab'
        Name = $Name
        ID = (Get-PodeWebElementId -Tag Tab -Name $Name)
        Layouts = $Layouts
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
        $Id,

        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Content,

        [Parameter()]
        [string[]]
        $CssClass,

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
        LayoutType = 'Card'
        Name = $Name
        ID = (Get-PodeWebElementId -Tag Card -Id $Id -Name $Name -NameAsToken)
        Content = $Content
        NoTitle = $NoTitle.IsPresent
        NoHide  = $NoHide.IsPresent
        CssClasses = ($CssClass -join ' ')
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
        LayoutType = 'Container'
        ID = (Get-PodeWebElementId -Tag Container -Id $Id -NameAsToken)
        Content = $Content
        CssClasses = ($CssClass -join ' ')
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
        [string[]]
        $EndpointName,

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

    $routePath = "/layouts/modal/$($Id)"
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
        LayoutType = 'Modal'
        Name = $Name
        ID = $Id
        Icon = $Icon
        Content = $Content
        CloseText = [System.Net.WebUtility]::HtmlEncode($CloseText)
        SubmitText = [System.Net.WebUtility]::HtmlEncode($SubmitText)
        Size = $Size
        AsForm = $AsForm.IsPresent
        ShowSubmit = ($null -ne $ScriptBlock)
        CssClasses = ($CssClass -join ' ')
    }
}

function New-PodeWebHero
{
    [CmdletBinding()]
    param(
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
        $CssClass
    )

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Hero can only contain layouts and/or elements'
    }

    return @{
        ComponentType = 'Layout'
        LayoutType = 'Hero'
        Title = [System.Net.WebUtility]::HtmlEncode($Title)
        Message = [System.Net.WebUtility]::HtmlEncode($Message)
        Content = $Content
        CssClasses = ($CssClass -join ' ')
    }
}

function New-PodeWebCarousel
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable[]]
        $Slides,

        [Parameter()]
        [string[]]
        $CssClass
    )

    if (!(Test-PodeWebContent -Content $Slides -ComponentType Layout -LayoutType Slide)) {
        throw 'A Carousel can only contain Slide layouts'
    }

    return @{
        ComponentType = 'Layout'
        LayoutType = 'Carousel'
        ID = (Get-PodeWebElementId -Tag Carousel -Id $Id -NameAsToken)
        Slides = $Slides
        CssClasses = ($CssClass -join ' ')
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
        $Message
    )

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Slide can only contain layouts and/or elements'
    }

    return @{
        ComponentType = 'Layout'
        LayoutType = 'Slide'
        Content = $Content
        Title = [System.Net.WebUtility]::HtmlEncode($Title)
        Message = [System.Net.WebUtility]::HtmlEncode($Message)
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

    if (!(Test-PodeWebContent -Content $Steps -ComponentType Layout -LayoutType Step)) {
        throw 'Steps can only contain Step layouts'
    }

    # generate ID
    $Id = Get-PodeWebElementId -Tag Steps -Id $Id -Name $Name

    # add route
    $routePath = "/layouts/steps/$($Id)"
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
        LayoutType = 'Steps'
        ID = $Id
        Steps = $Steps
        CssClasses = ($CssClass -join ' ')
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
    $routePath = "/layouts/step/$($Id)"
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
        LayoutType = 'Step'
        Name = $Name
        ID = $Id
        Content = $Content
        Icon = $Icon
        IsDynamic = ($null -ne $ScriptBlock)
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

    if (!(Test-PodeWebContent -Content $Items -ComponentType Layout -LayoutType BreadcrumbItem)) {
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
        LayoutType = 'Breadcrumb'
        Items = $Items
    }
}

function New-PodeWebBreadcrumbItem
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $Url,

        [switch]
        $Active
    )

    return @{
        ComponentType = 'Layout'
        LayoutType = 'BreadcrumbItem'
        Name = $Name
        Url = $Url
        Active = $Active.IsPresent
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
        [int]
        $CycleInterval = 15,

        [switch]
        $Cycle
    )

    if (!(Test-PodeWebContent -Content $Bellows -ComponentType Layout -LayoutType Bellow)) {
        throw 'Accordions can only contain Bellow layouts'
    }

    if ($CycleInterval -lt 10) {
        $CycleInterval = 10
    }

    return @{
        ComponentType = 'Layout'
        LayoutType = 'Accordion'
        ID = (Get-PodeWebElementId -Tag Accordion -Id $Id -NameAsToken)
        Bellows = $Bellows
        CssClasses = ($CssClass -join ' ')
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
        [hashtable[]]
        $Content,

        [Parameter()]
        [string]
        $Icon
    )

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Bellow can only contain layouts and/or elements'
    }

    return @{
        ComponentType = 'Layout'
        LayoutType = 'Bellow'
        Name = $Name
        ID = (Get-PodeWebElementId -Tag Bellow -Name $Name)
        Content = $Content
        Icon = $Icon
    }
}
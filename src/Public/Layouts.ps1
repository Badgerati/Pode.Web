function New-PodeWebGrid {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory = $true)]
        [hashtable[]]
        $Cells,

        [Parameter()]
        [int]
        $Width = 0,

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
        ObjectType    = 'Grid'
        Cells         = $Cells
        Width         = $Width
        ID            = (Get-PodeWebElementId -Tag Grid -Id $Id)
    }
}

function New-PodeWebCell {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory = $true)]
        [hashtable[]]
        $Content,

        [Parameter()]
        [string]
        $Width,

        [Parameter()]
        [ValidateSet('Left', 'Right', 'Center')]
        [string]
        $Alignment = 'Left'
    )

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Cell can only contain layouts and/or elements'
    }

    return @{
        ComponentType = 'Layout'
        ObjectType    = 'Cell'
        Content       = $Content
        Width         = (Protect-PodeWebRange -Value $Width -Min 1 -Max 12)
        ID            = (Get-PodeWebElementId -Tag Cell -Id $Id)
        Alignment     = $Alignment.ToLowerInvariant()
    }
}

function New-PodeWebTabs {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory = $true)]
        [hashtable[]]
        $Tabs,

        [Parameter()]
        [int]
        $CycleInterval = 15,

        [switch]
        $Cycle,

        [string]
        $activeTab
    )

    if (!(Test-PodeWebContent -Content $Tabs -ComponentType Layout -ObjectType Tab)) {
        throw 'Tabs can only contain Tab layouts'
    }

    if ($CycleInterval -lt 10) {
        $CycleInterval = 10
    }

    return @{
        ComponentType = 'Layout'
        ObjectType    = 'Tabs'
        ID            = (Get-PodeWebElementId -Tag Tabs -Id $Id)
        Tabs          = $Tabs
        Cycle         = @{
            Enabled  = $Cycle.IsPresent
            Interval = ($CycleInterval * 1000)
        }
        ActiveElement = $activeTab
    }
}

function New-PodeWebTab {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $DisplayName,

        [Parameter(Mandatory = $true)]
        [hashtable[]]
        $Content,

        [Parameter()]
        [object]
        $Icon
    )

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Tab can only contain layouts and/or elements'
    }

    return @{
        ComponentType = 'Layout'
        ObjectType    = 'Tab'
        Name          = $Name
        DisplayName   = (Protect-PodeWebValue -Value $DisplayName -Default $Name -Encode)
        ID            = (Get-PodeWebElementId -Tag Tab -Id $Id -Name $Name)
        Content       = $Content
        Icon          = (Protect-PodeWebIconType -Icon $Icon -Element 'Tab')
    }
}

function New-PodeWebCard {
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

        [Parameter(Mandatory = $true)]
        [hashtable[]]
        $Content,

        [Parameter()]
        [hashtable[]]
        $Buttons,

        [Parameter()]
        [object]
        $Icon,

        [switch]
        $NoTitle,

        [switch]
        $NoHide
    )

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Card can only contain layouts and/or elements'
    }

    if (!(Test-PodeWebContent -Content $Buttons -ComponentType Element -ObjectType Button, 'Button-Group')) {
        throw 'Card Buttons can only contain Buttons'
    }

    return @{
        ComponentType = 'Layout'
        ObjectType    = 'Card'
        Name          = $Name
        DisplayName   = (Protect-PodeWebValue -Value $DisplayName -Default $Name -Encode)
        ID            = (Get-PodeWebElementId -Tag Card -Id $Id -Name $Name)
        Content       = $Content
        Buttons       = $Buttons
        NoTitle       = $NoTitle.IsPresent
        NoHide        = $NoHide.IsPresent
        Icon          = (Protect-PodeWebIconType -Icon $Icon -Element 'Card')
    }
}

function New-PodeWebContainer {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory = $true)]
        [hashtable[]]
        $Content,

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
        ObjectType    = 'Container'
        ID            = (Get-PodeWebElementId -Tag Container -Id $Id)
        Content       = $Content
        NoBackground  = $NoBackground.IsPresent
        Hide          = $Hide.IsPresent
    }
}

function New-PodeWebModal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $DisplayName,

        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory = $true)]
        [hashtable[]]
        $Content,

        [Parameter()]
        [object]
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

    $routePath = "/elements/modal/$($Id)"
    if (($null -ne $ScriptBlock) -and !(Test-PodeWebRoute -Path $routePath)) {
        # check for scoped vars
        $ScriptBlock, $usingVars = Convert-PodeScopedVariables -ScriptBlock $ScriptBlock -PSSession $PSCmdlet.SessionState
        $elementLogic = @{
            ScriptBlock    = $ScriptBlock
            UsingVariables = $usingVars
        }

        $auth = $null
        if (!$NoAuthentication -and !$PageData.NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        if (Test-PodeIsEmpty $EndpointName) {
            $EndpointName = Get-PodeWebState -Name 'endpoint-name'
        }

        $argList = @(
            @{ Data = $ArgumentList },
            $elementLogic
        )

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList $argList -EndpointName $EndpointName -ScriptBlock {
            param($Data, $Logic)
            $result = Invoke-PodeWebScriptBlock -Logic $Logic -Arguments $Data.Data
            Write-PodeJsonResponse -Value $result
        }
    }

    return @{
        ComponentType = 'Layout'
        ObjectType    = 'Modal'
        Name          = $Name
        DisplayName   = (Protect-PodeWebValue -Value $DisplayName -Default $Name -Encode)
        ID            = $Id
        Icon          = (Protect-PodeWebIconType -Icon $Icon -Element 'Modal')
        Content       = $Content
        CloseText     = [System.Net.WebUtility]::HtmlEncode($CloseText)
        SubmitText    = [System.Net.WebUtility]::HtmlEncode($SubmitText)
        Size          = $Size
        AsForm        = $AsForm.IsPresent
        ShowSubmit    = ($null -ne $ScriptBlock)
        Method        = $Method
        Action        = (Protect-PodeWebValue -Value $Action -Default $routePath)
    }
}

function New-PodeWebHero {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory = $true)]
        [string]
        $Title,

        [Parameter(Mandatory = $true)]
        [string]
        $Message,

        [Parameter()]
        [hashtable[]]
        $Content
    )

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Hero can only contain layouts and/or elements'
    }

    return @{
        ComponentType = 'Layout'
        ObjectType    = 'Hero'
        ID            = (Get-PodeWebElementId -Tag Hero -Id $Id)
        Title         = [System.Net.WebUtility]::HtmlEncode($Title)
        Message       = [System.Net.WebUtility]::HtmlEncode($Message)
        Content       = $Content
    }
}

function New-PodeWebCarousel {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory = $true)]
        [hashtable[]]
        $Slides
    )

    if (!(Test-PodeWebContent -Content $Slides -ComponentType Layout -ObjectType Slide)) {
        throw 'A Carousel can only contain Slide layouts'
    }

    return @{
        ComponentType = 'Layout'
        ObjectType    = 'Carousel'
        ID            = (Get-PodeWebElementId -Tag Carousel -Id $Id)
        Slides        = $Slides
    }
}

function New-PodeWebSlide {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
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
        ObjectType    = 'Slide'
        Content       = $Content
        ID            = (Get-PodeWebElementId -Tag Slide)
        Title         = [System.Net.WebUtility]::HtmlEncode($Title)
        Message       = [System.Net.WebUtility]::HtmlEncode($Message)
    }
}

function New-PodeWebSteps {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory = $true)]
        [hashtable[]]
        $Steps,

        [Parameter(Mandatory = $true)]
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
    $routePath = "/elements/steps/$($Id)"
    if (($null -ne $ScriptBlock) -and !(Test-PodeWebRoute -Path $routePath)) {
        # check for scoped vars
        $ScriptBlock, $usingVars = Convert-PodeScopedVariables -ScriptBlock $ScriptBlock -PSSession $PSCmdlet.SessionState
        $elementLogic = @{
            ScriptBlock    = $ScriptBlock
            UsingVariables = $usingVars
        }

        $auth = $null
        if (!$NoAuthentication -and !$PageData.NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        if (Test-PodeIsEmpty $EndpointName) {
            $EndpointName = Get-PodeWebState -Name 'endpoint-name'
        }

        $argList = @(
            @{ Data = $ArgumentList },
            $elementLogic
        )

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList $argList -EndpointName $EndpointName -ScriptBlock {
            param($Data, $Logic)
            $result = Invoke-PodeWebScriptBlock -Logic $Logic -Arguments $Data.Data
            Write-PodeJsonResponse -Value $result
        }
    }

    return @{
        ComponentType = 'Layout'
        ObjectType    = 'Steps'
        ID            = $Id
        Steps         = $Steps
    }
}

function New-PodeWebStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
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
        [object]
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
    $routePath = "/elements/step/$($Id)"
    if (($null -ne $ScriptBlock) -and !(Test-PodeWebRoute -Path $routePath)) {
        # check for scoped vars
        $ScriptBlock, $usingVars = Convert-PodeScopedVariables -ScriptBlock $ScriptBlock -PSSession $PSCmdlet.SessionState
        $elementLogic = @{
            ScriptBlock    = $ScriptBlock
            UsingVariables = $usingVars
        }

        $auth = $null
        if (!$NoAuthentication -and !$PageData.NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        if (Test-PodeIsEmpty $EndpointName) {
            $EndpointName = Get-PodeWebState -Name 'endpoint-name'
        }

        $argList = @(
            @{ Data = $ArgumentList },
            $elementLogic
        )

        Add-PodeRoute -Method Post -Path $routePath -Authentication $auth -ArgumentList $argList -EndpointName $EndpointName -ScriptBlock {
            param($Data, $Logic)
            $result = Invoke-PodeWebScriptBlock -Logic $Logic -Arguments $Data.Data
            Write-PodeJsonResponse -Value $result
        }
    }

    return @{
        ComponentType = 'Layout'
        ObjectType    = 'Step'
        Name          = $Name
        DisplayName   = (Protect-PodeWebValue -Value $DisplayName -Default $Name -Encode)
        ID            = $Id
        Content       = $Content
        Icon          = (Protect-PodeWebIconType -Icon $Icon -Element 'Step')
        IsDynamic     = ($null -ne $ScriptBlock)
    }
}

function Set-PodeWebBreadcrumb {
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
            throw 'Cannot have two active breadcrumb items'
        }

        $foundActive = $item.Active
    }

    return @{
        ComponentType = 'Layout'
        ObjectType    = 'Breadcrumb'
        Items         = $Items
        NoEvents      = $true
    }
}

function New-PodeWebBreadcrumbItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $DisplayName,

        [Parameter(Mandatory = $true)]
        [string]
        $Url,

        [switch]
        $Active
    )

    return @{
        ComponentType = 'Layout'
        ObjectType    = 'Breadcrumb-Item'
        Name          = $Name
        DisplayName   = (Protect-PodeWebValue -Value $DisplayName -Default $Name -Encode)
        Url           = (Add-PodeWebAppPath -Url $Url)
        Active        = $Active.IsPresent
        NoEvents      = $true
    }
}

function New-PodeWebAccordion {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [string]
        $Name,

        [Parameter(Mandatory = $true)]
        [hashtable[]]
        $Bellows,

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
        throw 'An Accordion can only contain Bellow layouts'
    }

    if ($CycleInterval -lt 10) {
        $CycleInterval = 10
    }

    return @{
        ComponentType = 'Layout'
        ObjectType    = 'Accordion'
        ID            = (Get-PodeWebElementId -Tag Accordion -Id $Id -Name $Name)
        Name          = $Name
        Bellows       = $Bellows
        Mode          = $Mode
        Cycle         = @{
            Enabled  = $Cycle.IsPresent
            Interval = ($CycleInterval * 1000)
        }
    }
}

function New-PodeWebBellow {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $DisplayName,

        [Parameter()]
        [hashtable[]]
        $Content,

        [Parameter()]
        [object]
        $Icon
    )

    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Bellow can only contain layouts and/or elements'
    }

    return @{
        ComponentType = 'Layout'
        ObjectType    = 'Bellow'
        Name          = $Name
        DisplayName   = (Protect-PodeWebValue -Value $DisplayName -Default $Name -Encode)
        ID            = (Get-PodeWebElementId -Tag Bellow -Id $Id -Name $Name)
        Content       = $Content
        Icon          = (Protect-PodeWebIconType -Icon $Icon -Element 'Bellow')
    }
}
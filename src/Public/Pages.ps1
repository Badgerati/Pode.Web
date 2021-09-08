function Set-PodeWebLoginPage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Authentication,

        [Parameter()]
        [Alias('Icon')]
        [string]
        $Logo,

        [Parameter()]
        [Alias('IconUrl')]
        [string]
        $LogoUrl,

        [Parameter()]
        [string]
        $Copyright,

        [Parameter()]
        [string]
        $UsernameProperty,

        [Parameter()]
        [string]
        $GroupProperty,

        [Parameter()]
        [string]
        $AvatarProperty,

        [Parameter()]
        [string]
        $ThemeProperty,

        [Parameter()]
        [string]
        $BackgroundImage
    )

    Set-PodeWebState -Name 'auth' -Value $Authentication
    Set-PodeWebState -Name 'auth-props' -Value @{
        Username = $UsernameProperty
        Group = $GroupProperty
        Avatar = $AvatarProperty
        Theme = $ThemeProperty
    }

    # set a default logo/url
    if ([string]::IsNullOrWhiteSpace($Logo)) {
        $Logo = '/pode.web/images/icon.png'
    }

    if ([string]::IsNullOrWhiteSpace($LogoUrl)) {
        $LogoUrl = '/'
    }

    # set default failure/success urls
    $auth = Get-PodeAuth -Name $Authentication
    $auth.Failure.Url = '/login'
    $auth.Success.Url = '/'

    # is this auto-redirect oauth2?
    $isOAuth2 = ($auth.Scheme.Scheme -ieq 'oauth2')

    $grantType = 'authorization_code'
    if ($isOAuth2 -and !(Test-PodeIsEmpty $auth.Scheme.InnerScheme)) {
        $grantType = 'password'
    }

    # get the endpoints to bind
    $endpointNames = Get-PodeWebState -Name 'endpoint-name'

    # add the login route
    Add-PodeRoute -Method Get -Path '/login' -Authentication $Authentication -EndpointName $endpointNames -Login -ScriptBlock {
        Write-PodeWebViewResponse -Path 'login' -Data @{
            Theme = Get-PodeWebTheme
            Logo = $using:Logo
            LogoUrl = $using:LogoUrl
            Background = @{
                Image = $using:BackgroundImage
            }
            Copyright = $using:Copyright
            Auth = @{
                Name = $using:Authentication
                IsOAuth2 = $using:isOAuth2
                GrantType = $using:grantType
            }
        }
    }

    Add-PodeRoute -Method Post -Path '/login' -Authentication $Authentication -EndpointName $endpointNames -Login

    # add the logout route
    Add-PodeRoute -Method Post -Path '/logout' -Authentication $Authentication -EndpointName $endpointNames -Logout

    # add an authenticated home route
    Remove-PodeWebRoute -Method Get -Path '/' -EndpointName $endpointNames

    Add-PodeRoute -Method Get -Path '/' -Authentication $Authentication -EndpointName $endpointNames -ScriptBlock {
        $page = Get-PodeWebFirstPublicPage
        if ($null -ne $page) {
            Move-PodeResponseUrl -Url (Get-PodeWebPagePath -Page $page)
        }

        $authData = Get-PodeWebAuthData
        $username = Get-PodeWebAuthUsername -AuthData $authData
        $groups = Get-PodeWebAuthGroups -AuthData $authData
        $avatar = Get-PodeWebAuthAvatarUrl -AuthData $authData
        $theme = Get-PodeWebTheme
        $navigation = Get-PodeWebNavDefault

        Write-PodeWebViewResponse -Path 'index' -Data @{
            Page = @{
                Name = 'Home'
            }
            Theme = $theme
            Navigation = $navigation
            Auth = @{
                Enabled = $true
                Authenticated = $authData.IsAuthenticated
                Username = $username
                Groups = $groups
                Avatar = $avatar
            }
        }
    }
}

function Set-PodeWebHomePage
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable[]]
        $Layouts,

        [Parameter()]
        [string]
        $Title,

        [Parameter()]
        [hashtable[]]
        $Navigation,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [switch]
        $NoTitle
    )

    # ensure layouts are correct
    if (!(Test-PodeWebContent -Content $Layouts -ComponentType Layout)) {
        throw 'The Home Page can only contain layouts'
    }

    # does the page need auth?
    $auth = $null
    if (!$NoAuthentication) {
        $auth = (Get-PodeWebState -Name 'auth')
    }

    # get the endpoints to bind
    $endpointNames = Get-PodeWebState -Name 'endpoint-name'

    # set page title
    if ([string]::IsNullOrWhiteSpace($Title)) {
        $Title = 'Home'
    }

    # setup page meta
    $pageMeta = @{
        Name = 'Home'
        Title = $Title
        NoTitle = $NoTitle.IsPresent
    }

    Remove-PodeWebRoute -Method Get -Path '/' -EndpointName $endpointNames

    Add-PodeRoute -Method Get -Path '/' -Authentication $auth -EndpointName $endpointNames -ScriptBlock {
        $global:PageData = $using:pageMeta

        # we either render the home page, or move to the first page if home page is blank
        $comps = $using:Layouts
        if (($null -eq $comps) -or ($comps.Length -eq 0)) {
            $page = Get-PodeWebFirstPublicPage
            if ($null -ne $page) {
                Move-PodeResponseUrl -Url (Get-PodeWebPagePath -Page $page)
            }
        }

        $authData = Get-PodeWebAuthData
        $username = Get-PodeWebAuthUsername -AuthData $authData
        $groups = Get-PodeWebAuthGroups -AuthData $authData
        $avatar = Get-PodeWebAuthAvatarUrl -AuthData $authData
        $theme = Get-PodeWebTheme
        $navigation = Get-PodeWebNavDefault -Items $using:Navigation

        Write-PodeWebViewResponse -Path 'index' -Data @{
            Page = $global:PageData
            Theme = $theme
            Navigation = $navigation
            Layouts = $comps
            Auth = @{
                Enabled = ![string]::IsNullOrWhiteSpace((Get-PodeWebState -Name 'auth'))
                Authenticated = $authData.IsAuthenticated
                Username = $username
                Groups = $groups
                Avatar = $avatar
            }
        }

        $global:PageData = $null
    }
}

function Add-PodeWebPage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Title,

        [Parameter()]
        [string]
        $Group,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Icon = 'file',

        [Parameter()]
        [hashtable[]]
        $Layouts,

        [Parameter()]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [object[]]
        $ArgumentList,

        [Parameter()]
        [string[]]
        $AccessGroups = @(),

        [Parameter()]
        [string[]]
        $AccessUsers = @(),

        [Parameter()]
        [string[]]
        $EndpointName,

        [Parameter()]
        [hashtable[]]
        $Navigation,

        [Parameter()]
        [scriptblock]
        $HelpScriptBlock,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [switch]
        $NoTitle,

        [switch]
        $NoBackArrow,

        [switch]
        $NoBreadcrumb,

        [switch]
        $NewTab
    )

    # ensure layouts are correct
    if (!(Test-PodeWebContent -Content $Layouts -ComponentType Layout)) {
        throw 'A Page can only contain layouts'
    }

    # test if page/page-link exists
    if (Test-PodeWebPage -Name $Name -Group $Group -NoGroup) {
        throw "Web page/link already exists: $($Name) [Group: $($Group)]"
    }

    # set page title
    if ([string]::IsNullOrWhiteSpace($Title)) {
        $Title = $Name
    }

    # setup page meta
    $pageMeta = @{
        PageType = 'Page'
        Name = $Name
        Title = $Title
        NoTitle = $NoTitle.IsPresent
        NoBackArrow = $NoBackArrow.IsPresent
        NoBreadcrumb = $NoBreadcrumb.IsPresent
        NewTab = $NewTab.IsPresent
        IsDynamic = $false
        ShowHelp = ($null -ne $HelpScriptBlock)
        Icon = $Icon
        Group = $Group
        Url = (Get-PodeWebPagePath -Name $Name -Group $Group)
        NoAuthentication = $NoAuthentication.IsPresent
        Access = @{
            Groups = @($AccessGroups)
            Users = @($AccessUsers)
        }
    }

    Set-PodeWebState -Name 'pages' -Value  (@(Get-PodeWebState -Name 'pages') + $pageMeta)

    # does the page need auth?
    $auth = $null
    if (!$NoAuthentication) {
        $auth = (Get-PodeWebState -Name 'auth')
    }

    # get the endpoints to bind
    if (Test-PodeIsEmpty $EndpointName) {
        $EndpointName = Get-PodeWebState -Name 'endpoint-name'
    }

    # add the page route
    $routePath = $pageMeta.Url
    Add-PodeRoute -Method Get -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $EndpointName -ScriptBlock {
        param($Data)
        $global:PageData = $using:pageMeta

        if (!$global:PageData.NoBackArrow) {
            $global:PageData.ShowBack = (($null -ne $WebEvent.Query) -and ($WebEvent.Query.Count -gt 0))
        }
        else {
            $global:PageData.ShowBack = $false
        }

        # get auth details of a user
        $authData = Get-PodeWebAuthData
        $username = Get-PodeWebAuthUsername -AuthData $authData
        $groups = Get-PodeWebAuthGroups -AuthData $authData
        $avatar = Get-PodeWebAuthAvatarUrl -AuthData $authData
        $theme = Get-PodeWebTheme
        $navigation = Get-PodeWebNavDefault -Items $using:Navigation

        $authMeta = @{
            Enabled = ![string]::IsNullOrWhiteSpace((Get-PodeWebState -Name 'auth'))
            Authenticated = $authData.IsAuthenticated
            Username = $username
            Groups = $groups
            Avatar = $avatar
        }

        # check access - 403 if denied
        if (!(Test-PodeWebPageAccess -PageAccess $global:PageData.Access -Auth $authMeta)) {
            Set-PodeResponseStatus -Code 403
        }

        else {
            # if we have a scriptblock, invoke that to get dynamic components
            $layouts =$null
            if ($null -ne $using:ScriptBlock) {
                $layouts = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $Data.Data -Splat -Return
            }

            if (($null -eq $layouts) -or ($layouts.Length -eq 0)) {
                $layouts = $using:Layouts
            }

            $breadcrumb = $null
            $filteredLayouts = @()

            foreach ($item in $layouts) {
                if ($item.ObjectType -ieq 'breadcrumb') {
                    if ($null -ne $breadcrumb) {
                        throw "Cannot set two brecrumb trails on one page"
                    }

                    $breadcrumb = $item
                }
                else {
                    $filteredLayouts += $item
                }
            }

            Write-PodeWebViewResponse -Path 'index' -Data @{
                Page = $global:PageData
                Title = $using:Title
                Theme = $theme
                Navigation = $navigation
                Breadcrumb = $breadcrumb
                Layouts = $filteredLayouts
                Auth = $authMeta
            }
        }

        $global:PageData = $null
    }

    # add the page help route
    $helpPath = "$($routePath)/help"
    if (($null -ne $HelpScriptBlock) -and !(Test-PodeWebRoute -Path $helpPath)) {
        Add-PodeRoute -Method Post -Path $helpPath -Authentication $auth -ArgumentList @{ Data = $ArgumentList } -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $global:PageData = $using:pageMeta

            # get auth details of a user
            $authData = Get-PodeWebAuthData
            $username = Get-PodeWebAuthUsername -AuthData $authData
            $groups = Get-PodeWebAuthGroups -AuthData $authData

            $authMeta = @{
                Enabled = ![string]::IsNullOrWhiteSpace((Get-PodeWebState -Name 'auth'))
                Authenticated = $authData.IsAuthenticated
                Username = $username
                Groups = $groups
            }

            # check access - 403 if denied
            if (!(Test-PodeWebPageAccess -PageAccess $global:PageData.Access -Auth $authMeta)) {
                Set-PodeResponseStatus -Code 403
            }
            else {
                $result = Invoke-PodeScriptBlock -ScriptBlock $using:HelpScriptBlock -Arguments $Data.Data -Splat -Return
                if ($null -eq $result) {
                    $result = @()
                }

                if (!$WebEvent.Response.Headers.ContainsKey('Content-Disposition')) {
                    Write-PodeJsonResponse -Value $result
                }
            }

            $global:PageData = $null
        }
    }
}

function Add-PodeWebPageLink
{
    [CmdletBinding(DefaultParameterSetName='ScriptBlock')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Group,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Icon = 'file',

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
        [string[]]
        $AccessGroups = @(),

        [Parameter()]
        [string[]]
        $AccessUsers = @(),

        [Parameter(ParameterSetName='ScriptBlock')]
        [string[]]
        $EndpointName,

        [Parameter(ParameterSetName='ScriptBlock')]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [Parameter(ParameterSetName='Url')]
        [switch]
        $NewTab
    )

    # test if page/page-link exists
    if (Test-PodeWebPage -Name $Name -Group $Group -NoGroup) {
        throw "Web page/link already exists: $($Name) [Group: $($Group)]"
    }

    # setup page meta
    $pageMeta = @{
        PageType = 'Link'
        Name = $Name
        NewTab = $NewTab.IsPresent
        Icon = $Icon
        Group = $Group
        Url = $Url
        IsDynamic = ($null -ne $ScriptBlock)
        Access = @{
            Groups = @($AccessGroups)
            Users = @($AccessUsers)
        }
    }

    Set-PodeWebState -Name 'pages' -Value  (@(Get-PodeWebState -Name 'pages') + $pageMeta)

    $routePath = (Get-PodeWebPagePath -Name $Name -Group $Group)
    if (($null -ne $ScriptBlock) -and !(Test-PodeWebRoute -Path $routePath)) {
        $auth = $null
        if (!$NoAuthentication) {
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

            if (!$WebEvent.Response.Headers.ContainsKey('Content-Disposition')) {
                Write-PodeJsonResponse -Value $result
            }
        }
    }
}

function ConvertTo-PodeWebPage
{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string[]]
        $Commands,

        [Parameter()]
        [string]
        $Module,

        [switch]
        $GroupVerbs,

        [Parameter()]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication
    )

    # if a module was supplied, import it - then validate the commands
    if (![string]::IsNullOrWhiteSpace($Module)) {
        Import-PodeModule -Name $Module
        Export-PodeModule -Name $Module

        Write-Verbose "Getting exported commands from module"
        $ModuleCommands = (Get-Module -Name $Module | Sort-Object -Descending | Select-Object -First 1).ExportedCommands.Keys

        # if commands were supplied validate them - otherwise use all exported ones
        if (Test-PodeIsEmpty $Commands) {
            Write-Verbose "Using all commands in $($Module) for converting to Pages"
            $Commands = $ModuleCommands
        }
        else {
            Write-Verbose "Validating supplied commands against module's exported commands"
            foreach ($cmd in $Commands) {
                if ($ModuleCommands -inotcontains $cmd) {
                    throw "Module $($Module) does not contain function $($cmd) to convert to a Page"
                }
            }
        }
    }

    # if there are no commands, fail
    if (Test-PodeIsEmpty $Commands) {
        throw 'No commands supplied to convert to Pages'
    }

    $sysParams = @(
        'Verbose',
        'Debug',
        'ErrorAction',
        'WarningAction',
        'InformationAction',
        'ErrorVariable',
        'WarningVariable',
        'InformationVariable',
        'OutVariable',
        'OutBuffer',
        'PipelineVariable'
    )
    
    # create the pages for each of the commands
    foreach ($cmd in $Commands) {
        Write-Verbose "Building page for $($cmd)"
        $cmdInfo = (Get-Command -Name $cmd -ErrorAction Stop)

        $sets = $cmdInfo.ParameterSets
        if (($null -eq $sets) -or ($sets.Length -eq 0)) {
            continue
        }

        # for cmdlets this will be null
        $ast = $cmdInfo.ScriptBlock.Ast
        $paramDefs = $null
        if ($null -ne $ast) {
            $paramDefs = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ParameterAst] }, $true) | Where-Object {
                $_.Parent.Parent.Parent.Name -ieq $cmd
            }
        }

        $tabs = New-PodeWebTabs -Tabs @(foreach ($set in $sets) {
            $elements = @(foreach ($param in $set.Parameters) {
                if ($sysParams -icontains $param.Name) {
                    continue
                }

                $type = $param.ParameterType.Name

                $default = $null
                if ($null -ne $paramDefs) {
                    $default = ($paramDefs | Where-Object { $_.DefaultValue -and $_.Name.Extent.Text -ieq "`$$($param.Name)" }).DefaultValue.Value
                }

                if ($type -iin @('boolean', 'switchparameter')) {
                    New-PodeWebCheckbox -Name $param.Name -AsSwitch
                }
                else {
                    switch ($type) {
                        'pscredential' {
                            New-PodeWebCredential -Name $param.Name
                        }

                        default {
                            $multiple = $param.ParameterType.Name.EndsWith('[]')

                            if ($param.Attributes.TypeId.Name -icontains 'ValidateSetAttribute') {
                                $values = ($param.Attributes | Where-Object { $_.TypeId.Name -ieq 'ValidateSetAttribute' }).ValidValues
                                New-PodeWebSelect -Name  $param.Name -Options $values -SelectedValue $default -Multiple:$multiple
                            }
                            elseif ($param.ParameterType.BaseType.Name -ieq 'enum') {
                                $values = [enum]::GetValues($param.ParameterType)
                                New-PodeWebSelect -Name  $param.Name -Options $values -SelectedValue $default -Multiple:$multiple
                            }
                            else {
                                New-PodeWebTextbox -Name $param.Name -Value $default
                            }
                        }
                    }
                }
            })

            $elements += (New-PodeWebHidden -Name '_Function_Name_' -Value $cmd)

            $name = $set.Name
            if ([string]::IsNullOrWhiteSpace($name) -or ($set.Name -iin @('__AllParameterSets'))) {
                $name = 'Default'
            }

            $formId = "form_param_$($cmd)_$($name)"

            $form = New-PodeWebForm -Name Parameters -Id $formId -Content $elements -AsCard -NoAuthentication:$NoAuthentication -ScriptBlock {
                $cmd = $WebEvent.Data['_Function_Name_']
                $WebEvent.Data.Remove('_Function_Name_')

                $_args = @{}
                foreach ($key in $WebEvent.Data.Keys) {
                    if ($key -imatch '(?<name>.+)_(Username|Password)$') {
                        $name = $Matches['name']
                        $uKey = "$($name)_Username"
                        $pKey = "$($name)_Password"

                        if (![string]::IsNullOrWhiteSpace($WebEvent.Data[$uKey]) -and ![string]::IsNullOrWhiteSpace($WebEvent.Data[$pKey])) {
                            $creds = (New-Object System.Management.Automation.PSCredential -ArgumentList $WebEvent.Data[$uKey], (ConvertTo-SecureString -AsPlainText $WebEvent.Data[$pKey] -Force))
                            $_args[$name] = $creds
                        }
                    }
                    else {
                        if ($WebEvent.Data[$key] -iin @('true', 'false')) {
                            $_args[$key] = ($WebEvent.Data[$key] -ieq 'true')
                        }
                        else {
                            if ($WebEvent.Data[$key].Contains(',')) {
                                $_args[$key] = ($WebEvent.Data[$key] -isplit ',' | ForEach-Object { $_.Trim() })
                            }
                            else {
                                $_args[$key] = $WebEvent.Data[$key]
                            }
                        }
                    }
                }

                try {
                    (. $cmd @_args) | Out-PodeWebTextbox -Multiline -Preformat
                }
                catch {
                    $_.Exception | Out-PodeWebTextbox -Multiline -Preformat
                }
            }

            New-PodeWebTab -Name $name -Layouts $form
        })

        $group = [string]::Empty
        if ($GroupVerbs) {
            $group = $cmdInfo.Verb
            if ([string]::IsNullOrWhiteSpace($group)) {
                $group = '_'
            }
        }

        Add-PodeWebPage -Name $cmd -Icon Settings -Layouts $tabs -Group $group -NoAuthentication:$NoAuthentication
    }
}

function Use-PodeWebPages
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Path
    )

    # use default ./pages, or custom path
    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Join-Path (Get-PodeServerPath) 'pages'
    }
    elseif ($Path.StartsWith('.')) {
        $Path = Join-Path (Get-PodeServerPath) $Path
    }

    # fail if path not found
    if (!(Test-Path -Path $Path)) {
        throw "Path to load pages not found: $($Path)"
    }

    # get .ps1 files and load them
    Get-ChildItem -Path $Path -Filter *.ps1 -Force -Recurse | ForEach-Object {
        Use-PodeScript -Path $_.FullName
    }
}

function Get-PodeWebPage
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Group,

        [Parameter()]
        [switch]
        $NoGroup
    )

    # get all pages
    $pages = Get-PodeWebState -Name 'pages'

    # filter by group
    if ($NoGroup -and [string]::IsNullOrWhiteSpace($Group)) {
        $pages = @(foreach ($page in $pages) {
            if ([string]::IsNullOrWhiteSpace($page.Group)) {
                $page
            }
        })
    }
    elseif (![string]::IsNullOrWhiteSpace($Group)) {
        $pages = @(foreach ($page in $pages) {
            if ($page.Group -ieq $Group) {
                $page
            }
        })
    }

    # filter by page name
    if (![string]::IsNullOrWhiteSpace($Name)) {
        $pages = @(foreach ($page in $pages) {
            if ($page.Name -ieq $Name) {
                $page
            }
        })
    }

    # return filtered pages
    return $pages
}

function Test-PodeWebPage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Group,

        [Parameter()]
        [switch]
        $NoGroup
    )

    # get pages
    $pages = Get-PodeWebPage -Name $Name -Group $Group -NoGroup:$NoGroup

    # are there any pages?
    if ($null -eq $pages) {
        return $false
    }

    return (@($pages) | Measure-Object).Count -gt 0
}
function Set-PodeWebLoginPage {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory = $true)]
        [string]
        $Authentication,

        [Parameter()]
        [hashtable[]]
        $Content,

        [Parameter()]
        [string]
        $Logo,

        [Parameter()]
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
        $BackgroundImage,

        [Parameter()]
        [string]
        $SignInMessage,

        [Parameter()]
        [string]
        $LoginPath,

        [Parameter()]
        [string]
        $LogoutPath,

        [switch]
        $PassThru
    )

    # check content
    if (!(Test-PodeWebContent -Content $Content -ComponentType Element)) {
        throw 'The Login page can only contain other elements'
    }

    # retrieve the auth from pode
    $auth = Get-PodeAuth -Name $Authentication

    # if no content, add default
    if (Test-PodeIsEmpty -Value $Content) {
        $Content = @(
            New-PodeWebTextbox -Type Text -Name 'username' -Id 'username' -Placeholder 'Username' -Required -AutoFocus -DynamicLabel
            New-PodeWebTextbox -Type Password -Name 'password' -Id 'password' -Placeholder 'Password' -Required -DynamicLabel
        )
    }

    # set auth to be used on other pages
    Set-PodeWebState -Name 'auth' -Value $Authentication
    Set-PodeWebState -Name 'auth-props' -Value @{
        Username = $UsernameProperty
        Group    = $GroupProperty
        Avatar   = $AvatarProperty
        Theme    = $ThemeProperty
        Logout   = $true
    }

    # get home url
    $sysUrls = Get-PodeWebState -Name 'system-urls'

    # set a default logo/url
    if ([string]::IsNullOrWhiteSpace($Logo)) {
        $Logo = '/pode.web-static/images/icon.png'
    }
    $Logo = (Add-PodeWebAppPath -Url $Logo)

    if (![string]::IsNullOrWhiteSpace($LogoUrl)) {
        $LogoUrl = (Add-PodeWebAppPath -Url $LogoUrl)
    }

    # background image
    $BackgroundImage = (Add-PodeWebAppPath -Url $BackgroundImage)

    # is this auto-redirect oauth2?
    $isOAuth2 = ($auth.Scheme.Scheme -ieq 'oauth2')

    $grantType = 'authorization_code'
    if ($isOAuth2 -and !(Test-PodeIsEmpty $auth.Scheme.InnerScheme)) {
        $grantType = 'password'
    }

    # generate page ID
    $Id = Get-PodeWebPageId -Id $Id -Name 'login' -System

    # login / logout paths
    if ([string]::IsNullOrEmpty($LoginPath)) {
        $LoginPath = '/login'
    }

    if ([string]::IsNullOrEmpty($LogoutPath)) {
        $LogoutPath = '/logout'
    }

    # setup page meta
    $pageMeta = @{
        Operation       = 'New'
        ComponentType   = 'Page'
        ObjectType      = 'Page'
        ID              = $Id
        Route           = @{
            Login  = @{
                Path = (Get-PodeWebPagePath -Name 'login' -Path $LoginPath -NoAppPath)
                Url  = (Get-PodeWebPagePath -Name 'login' -Path $LoginPath)
            }
            Logout = @{
                Path = (Get-PodeWebPagePath -Name 'logout' -Path $LogoutPath -NoAppPath)
                Url  = (Get-PodeWebPagePath -Name 'logout' -Path $LogoutPath)
            }
        }
        Name            = 'Login'
        Content         = $Content
        SignInMessage   = (Protect-PodeWebValue -Value $SignInMessage -Default 'Please sign in' -Encode)
        Logo            = @{
            IconUrl = $Logo
            Url     = $LogoUrl
        }
        BackgroundImage = $BackgroundImage
        CopyRight       = $Copyright
        Authentication  = $Authentication
        IsOAuth2        = $isOAuth2
        GrantType       = $grantType
        IsSystem        = $true
        ResponseType    = (Get-PodeWebResponseType)
    }

    # set auth system urls
    $sysUrls.Login = $pageMeta.Route.Login
    $sysUrls.Logout = $pageMeta.Route.Logout

    # set default failure/success urls
    if ([string]::IsNullOrWhiteSpace($auth.Failure.Url)) {
        $auth.Failure.Url = $pageMeta.Route.Login.Url
    }

    if ([string]::IsNullOrWhiteSpace($auth.Success.Url)) {
        $auth.Success.Url = $sysUrls.Home.Url
    }

    # add page meta to state
    $pages = Get-PodeWebState -Name 'pages'
    $pages[$Id] = $pageMeta

    # get the endpoints to bind
    $endpointNames = Get-PodeWebState -Name 'endpoint-name'

    # add the login route
    Add-PodeRoute -Method Get -Path $pageMeta.Route.Login.Path -Authentication $Authentication -ArgumentList @{ ID = $Id } -EndpointName $endpointNames -Login -ScriptBlock {
        param($Data)
        $global:PageData = (Get-PodeWebState -Name 'pages')[$Data.ID]

        Write-PodeWebViewResponse -Path 'login' -Data @{
            Page          = $global:PageData
            Theme         = Get-PodeWebTheme
            Sessions      = @{
                Enabled = (Test-PodeSessionsEnabled)
                Tabs    = !(Test-PodeSessionScopeIsBrowser)
            }
            Logo          = $PageData.Logo.IconUrl
            LogoUrl       = $PageData.Logo.Url
            Background    = @{
                Image = $PageData.BackgroundImage
            }
            SignInMessage = $PageData.SignInMessage
            Copyright     = $PageData.Copyright
            Auth          = @{
                Name      = $PageData.Authentication
                IsOAuth2  = $PageData.IsOAuth2
                GrantType = $PageData.GrantType
            }
        }

        $global:PageData = $null
    }

    Add-PodeRoute -Method Post -Path $pageMeta.Route.Login.Path -Authentication $Authentication -EndpointName $endpointNames -Login

    # add the logout route
    Add-PodeRoute -Method Post -Path $pageMeta.Route.Logout.Path -Authentication $Authentication -EndpointName $endpointNames -Logout

    # login content
    Add-PodeRoute -Method Post -Path "/pode.web-dynamic/pages/$($pageMeta.ID)/content" -ArgumentList @{ ID = $Id } -EndpointName $endpointNames -ScriptBlock {
        param($Data)
        $global:PageData = (Get-PodeWebState -Name 'pages')[$Data.ID]
        Write-PodeJsonResponse -Value $global:PageData.Content
        $global:PageData = $null
    }

    # add sse open route
    if (Test-PodeWebResponseType -Type Sse) {
        Add-PodeRoute -Method Get -Path "/pode.web-dynamic/pages/$($pageMeta.ID)/sse-open" -ArgumentList @{ ID = $Id } -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            ConvertTo-PodeSseConnection -Name 'Pode.Web.Actions' -Group $Data.ID
        }

        # add sse close route
        Add-PodeRoute -Method Post -Path "/pode.web-dynamic/pages/$($pageMeta.ID)/sse-close" -EndpointName $EndpointName -ScriptBlock {
            $clientId = Get-PodeHeader -Name 'X-PODE-SSE-CLIENT-ID'
            if (![string]::IsNullOrEmpty($clientId)) {
                Close-PodeSseConnection -Name 'Pode.Web.Actions' -ClientId $clientId
            }
        }
    }

    if ($PassThru) {
        return $pageMeta
    }
}

function Add-PodeWebPage {
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
        $Path,

        [Parameter()]
        [object[]]
        $Middleware,

        [Parameter()]
        [ValidateSet('Default', 'Error', 'Overwrite', 'Skip')]
        $IfExists = 'Default',

        [Parameter()]
        [int]
        $Index = [int]::MaxValue,

        [Parameter()]
        [string]
        $DisplayName,

        [Parameter()]
        [string]
        $Title,

        [Parameter()]
        [ValidateNotNull()]
        [string]
        $Group = [string]::Empty,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Icon = 'file',

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
        $NewTab,

        [switch]
        $Hide,

        [switch]
        $NoSidebar,

        [switch]
        $NoNavigation,

        [switch]
        $HomePage,

        [switch]
        $PassThru
    )

    # ensure elements are correct
    if (!(Test-PodeWebContent -Content $Content -ComponentType Element)) {
        throw 'A Page can only contain elements'
    }

    # test if group exists - otherwise create a basic group entry
    if (!(Test-PodeWebPageGroup -Name $Group)) {
        New-PodeWebPageGroup -Name $Group
    }

    # generate page ID
    $Id = Get-PodeWebPageId -Id $Id -Name $Name -Group $Group

    # test if page/page-link exists
    if (Test-PodeWebPage -Id $Id) {
        throw "Web page/link already exists: $($Name) [Group: $($Group)]"
    }

    # set page title
    if ([string]::IsNullOrWhiteSpace($DisplayName)) {
        $DisplayName = $Name
    }

    if ([string]::IsNullOrWhiteSpace($Title)) {
        $Title = $DisplayName
    }

    # check for scoped vars
    $ScriptBlock, $mainUsingVars = Convert-PodeScopedVariables -ScriptBlock $ScriptBlock -PSSession $PSCmdlet.SessionState
    $HelpScriptBlock, $helpUsingVars = Convert-PodeScopedVariables -ScriptBlock $HelpScriptBlock -PSSession $PSCmdlet.SessionState

    # setup page meta
    $pageMeta = @{
        Operation        = 'New'
        ComponentType    = 'Page'
        ObjectType       = 'Page'
        ID               = $Id
        Index            = $Index
        Group            = $Group
        Name             = $Name
        Title            = [System.Net.WebUtility]::HtmlEncode($Title)
        DisplayName      = [System.Net.WebUtility]::HtmlEncode($DisplayName)
        NoTitle          = $NoTitle.IsPresent
        NoBackArrow      = $NoBackArrow.IsPresent
        NoBreadcrumb     = $NoBreadcrumb.IsPresent
        NewTab           = $NewTab.IsPresent
        IsDynamic        = $false
        ShowHelp         = ($null -ne $HelpScriptBlock)
        Icon             = $Icon
        Path             = (Get-PodeWebPagePath -Name $Name -Group $Group -Path $Path -NoAppPath)
        Url              = (Get-PodeWebPagePath -Name $Name -Group $Group -Path $Path)
        Hide             = $Hide.IsPresent
        NoSidebar        = $NoSidebar.IsPresent
        NoNavigation     = $NoNavigation.IsPresent
        Navigation       = $Navigation
        Logic            = @{
            ScriptBlock    = $ScriptBlock
            UsingVariables = $mainUsingVars
        }
        Help             = @{
            ScriptBlock    = $HelpScriptBlock
            UsingVariables = $helpUsingVars
        }
        Content          = $Content
        Authentication   = $null
        NoAuthentication = $NoAuthentication.IsPresent
        IsHomePage       = $HomePage.IsPresent
        Access           = @{
            Groups = @($AccessGroups)
            Users  = @($AccessUsers)
        }
        ResponseType     = (Get-PodeWebResponseType)
    }

    # does the page need auth?
    $auth = $null
    if (!$pageMeta.NoAuthentication) {
        $auth = Get-PodeWebState -Name 'auth'
    }
    $pageMeta.Authentication = $auth

    # add page meta to state
    Register-PodeWebPage -Metadata $pageMeta

    # get the endpoints to bind
    if (Test-PodeIsEmpty $EndpointName) {
        $EndpointName = Get-PodeWebState -Name 'endpoint-name'
    }

    # remove the "root" page, if "root-redirect" was originally flagged and this page is for the root path
    if (($pageMeta.Path -eq '/') -and (Get-PodeWebState -Name 'root-redirect')) {
        Remove-PodeRoute -Method Get -Path '/'
    }

    # add the page route
    Add-PodeRoute -Method Get -Path $pageMeta.Path -Authentication $pageMeta.Authentication -ArgumentList @{ Data = $ArgumentList; ID = $Id } -Middleware $Middleware -IfExists $IfExists -EndpointName $EndpointName -ScriptBlock {
        param($Data)
        $global:PageData = (Get-PodeWebState -Name 'pages')[$Data.ID]

        # get auth details of a user
        $authEnabled = ![string]::IsNullOrEmpty((Get-PodeWebState -Name 'auth'))
        $authMeta = $null

        if ($authEnabled) {
            $authData = Get-PodeAuthUser
            $authMeta = @{
                Enabled       = $true
                Logout        = (Get-PodeWebState -Name 'auth-props').Logout
                Authenticated = ($null -ne $authData)
            }

            if ($authMeta.Authenticated) {
                $authMeta['Username'] = Get-PodeWebAuthUsername -User $authData
                $authMeta['Groups'] = Get-PodeWebAuthGroups -User $authData
                $authMeta['Avatar'] = Get-PodeWebAuthAvatarUrl -User $authData
            }
        }

        # check access - 403 if denied
        if (!(Test-PodeWebPageAccess -PageAccess $global:PageData.Access -Auth $authMeta)) {
            Set-PodeResponseStatus -Code 403
        }

        else {
            # show a back arrow?
            if (!$global:PageData.NoBackArrow) {
                $global:PageData.ShowBack = (($null -ne $WebEvent.Query) -and ($WebEvent.Query.Count -gt 0))
                if ($global:PageData.ShowBack -and ($WebEvent.Query.Count -eq 1) -and ($WebEvent.Query.ContainsKey(''))) {
                    $global:PageData.ShowBack = $false
                }
            }
            else {
                $global:PageData.ShowBack = $false
            }

            # render the page
            Write-PodeWebViewResponse -Path 'index' -Data @{
                Page        = $global:PageData
                Title       = $global:PageData.Title
                DisplayName = $global:PageData.DisplayName
                Theme       = (Get-PodeWebTheme)
                Sessions    = @{
                    Enabled = (Test-PodeSessionsEnabled)
                    Tabs    = !(Test-PodeSessionScopeIsBrowser)
                }
                Auth        = $authMeta
            }
        }

        $global:PageData = $null
    }

    Add-PodeRoute -Method Post -Path "/pode.web-dynamic/pages/$($pageMeta.ID)/content" -Authentication $pageMeta.Authentication -ArgumentList @{ Data = $ArgumentList; ID = $Id } -IfExists $IfExists -EndpointName $EndpointName -ScriptBlock {
        param($Data)
        $global:PageData = (Get-PodeWebState -Name 'pages')[$Data.ID]
        Set-PodeWebMetadata

        # get auth details of a user
        $authEnabled = ![string]::IsNullOrEmpty((Get-PodeWebState -Name 'auth'))
        $authMeta = $null

        if ($authEnabled) {
            $authData = Get-PodeAuthUser
            if ($null -ne $authData) {
                $authMeta = @{
                    Username = (Get-PodeWebAuthUsername -User $authData)
                    Groups   = (Get-PodeWebAuthGroups -User $authData)
                }
            }
        }

        # check access - 403 if denied
        if (!(Test-PodeWebPageAccess -PageAccess $global:PageData.Access -Auth $authMeta)) {
            Set-PodeResponseStatus -Code 403
        }
        else {
            # if we have a scriptblock, invoke that to get dynamic elements
            $content = $null
            if ($null -ne $global:PageData.Logic.ScriptBlock) {
                $content = Invoke-PodeWebScriptBlock -Logic $global:PageData.Logic -Arguments $Data.Data
            }

            if (($null -eq $content) -or ($content.Length -eq 0)) {
                $content = $global:PageData.Content
            }

            $navigation = Get-PodeWebNavDefault -Items $global:PageData.Navigation
            Write-PodeJsonResponse -Value (@($navigation) + @($content))
        }

        $global:PageData = $null
    }

    # add sse open route
    if (Test-PodeWebResponseType -Type Sse) {
        Add-PodeRoute -Method Get -Path "/pode.web-dynamic/pages/$($pageMeta.ID)/sse-open" -Authentication $pageMeta.Authentication -ArgumentList @{ Data = $ArgumentList; ID = $Id } -IfExists $IfExists -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $global:PageData = (Get-PodeWebState -Name 'pages')[$Data.ID]

            # get auth details of a user
            $authEnabled = ![string]::IsNullOrEmpty((Get-PodeWebState -Name 'auth'))
            $authMeta = $null

            if ($authEnabled) {
                $authData = Get-PodeAuthUser
                if ($null -ne $authData) {
                    $authMeta = @{
                        Username = (Get-PodeWebAuthUsername -User $authData)
                        Groups   = (Get-PodeWebAuthGroups -User $authData)
                    }
                }
            }

            # check access - 403 if denied
            if (!(Test-PodeWebPageAccess -PageAccess $global:PageData.Access -Auth $authMeta)) {
                Set-PodeResponseStatus -Code 403
            }
            else {
                # open new sse connection
                ConvertTo-PodeSseConnection -Name 'Pode.Web.Actions' -Group $Data.ID
            }

            $global:PageData = $null
        }

        # add sse close route
        Add-PodeRoute -Method Post -Path "/pode.web-dynamic/pages/$($pageMeta.ID)/sse-close" -Authentication $pageMeta.Authentication -ArgumentList @{ Data = $ArgumentList; ID = $Id } -IfExists $IfExists -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $global:PageData = (Get-PodeWebState -Name 'pages')[$Data.ID]

            # get auth details of a user
            $authEnabled = ![string]::IsNullOrEmpty((Get-PodeWebState -Name 'auth'))
            $authMeta = $null

            if ($authEnabled) {
                $authData = Get-PodeAuthUser
                if ($null -ne $authData) {
                    $authMeta = @{
                        Username = (Get-PodeWebAuthUsername -User $authData)
                        Groups   = (Get-PodeWebAuthGroups -User $authData)
                    }
                }
            }

            # check access - 403 if denied
            if (!(Test-PodeWebPageAccess -PageAccess $global:PageData.Access -Auth $authMeta)) {
                Set-PodeResponseStatus -Code 403
            }
            else {
                # if a connection in header, close connection
                $clientId = Get-PodeHeader -Name 'X-PODE-SSE-CLIENT-ID'
                if (![string]::IsNullOrEmpty($clientId)) {
                    Close-PodeSseConnection -Name 'Pode.Web.Actions' -ClientId $clientId
                }
            }

            $global:PageData = $null
        }
    }

    # add the page help route
    $helpPath = "/pode.web-dynamic/pages/$($pageMeta.ID)/help"
    if (($null -ne $HelpScriptBlock) -and !(Test-PodeWebRoute -Path $helpPath)) {
        Add-PodeRoute -Method Post -Path $helpPath -Authentication $pageMeta.Authentication -ArgumentList @{ Data = $ArgumentList; ID = $Id } -IfExists $IfExists -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $global:PageData = (Get-PodeWebState -Name 'pages')[$Data.ID]
            Set-PodeWebMetadata

            # get auth details of a user
            $authEnabled = ![string]::IsNullOrEmpty((Get-PodeWebState -Name 'auth'))
            $authMeta = $null

            if ($authEnabled) {
                $authData = Get-PodeAuthUser
                if ($null -ne $authData) {
                    $authMeta = @{
                        Username = (Get-PodeWebAuthUsername -User $authData)
                        Groups   = (Get-PodeWebAuthGroups -User $authData)
                    }
                }
            }

            # check access - 403 if denied
            if (!(Test-PodeWebPageAccess -PageAccess $global:PageData.Access -Auth $authMeta)) {
                Set-PodeResponseStatus -Code 403
            }
            else {
                $result = Invoke-PodeWebScriptBlock -Logic $global:PageData.Help -Arguments $Data.Data

                if (($null -ne $result) -and !$WebEvent.Response.Headers.ContainsKey('Content-Disposition')) {
                    Write-PodeJsonResponse -Value $result
                }
            }

            $global:PageData = $null
        }
    }

    if ($PassThru) {
        return $pageMeta
    }
}

function Add-PodeWebPageLink {
    [CmdletBinding(DefaultParameterSetName = 'ScriptBlock')]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ScriptBlock')]
        [object[]]
        $Middleware,

        [Parameter()]
        [ValidateSet('Default', 'Error', 'Overwrite', 'Skip')]
        $IfExists = 'Default',

        [Parameter()]
        [int]
        $Index = [int]::MaxValue,

        [Parameter()]
        [string]
        $DisplayName,

        [Parameter()]
        [ValidateNotNull()]
        [string]
        $Group = [string]::Empty,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Icon = 'file',

        [Parameter(Mandatory = $true, ParameterSetName = 'ScriptBlock')]
        [scriptblock]
        $ScriptBlock,

        [Parameter(ParameterSetName = 'ScriptBlock')]
        [object[]]
        $ArgumentList,

        [Parameter(Mandatory = $true, ParameterSetName = 'Url')]
        [string]
        $Url,

        [Parameter()]
        [string[]]
        $AccessGroups = @(),

        [Parameter()]
        [string[]]
        $AccessUsers = @(),

        [Parameter(ParameterSetName = 'ScriptBlock')]
        [string[]]
        $EndpointName,

        [Parameter(ParameterSetName = 'ScriptBlock')]
        [Alias('NoAuth')]
        [switch]
        $NoAuthentication,

        [Parameter(ParameterSetName = 'Url')]
        [switch]
        $NewTab,

        [switch]
        $Hide
    )

    # test if group exists - otherwise create a basic group entry
    if (!(Test-PodeWebPageGroup -Name $Group)) {
        New-PodeWebPageGroup -Name $Group
    }

    # generate page ID
    $Id = Get-PodeWebPageId -Id $Id -Name $Name -Group $Group

    # test if page/page-link exists
    if (Test-PodeWebPage -Id $Id) {
        throw "Web page/link already exists: $($Name) [Group: $($Group)]"
    }

    # set page title
    if ([string]::IsNullOrWhiteSpace($DisplayName)) {
        $DisplayName = $Name
    }

    # check for scoped vars
    $ScriptBlock, $usingVars = Convert-PodeScopedVariables -ScriptBlock $ScriptBlock -PSSession $PSCmdlet.SessionState

    # setup page meta
    $pageMeta = @{
        Operation        = 'New'
        ComponentType    = 'Page'
        ObjectType       = 'Link'
        ID               = $Id
        Index            = $Index
        Name             = $Name
        Group            = $Group
        DisplayName      = [System.Net.WebUtility]::HtmlEncode($DisplayName)
        NewTab           = $NewTab.IsPresent
        Icon             = $Icon
        Path             = (Get-PodeWebPagePath -Name $Name -Group $Group -NoAppPath)
        Url              = (Add-PodeWebAppPath -Url $Url)
        Hide             = $Hide.IsPresent
        IsDynamic        = ($null -ne $ScriptBlock)
        Logic            = @{
            ScriptBlock    = $ScriptBlock
            UsingVariables = $usingVars
        }
        Authentication   = $null
        NoAuthentication = $NoAuthentication.IsPresent
        Access           = @{
            Groups = @($AccessGroups)
            Users  = @($AccessUsers)
        }
        NoEvents         = $true
    }

    # does the page need auth?
    $auth = [string]::Empty
    if (!$pageMeta.NoAuthentication) {
        $auth = Get-PodeWebState -Name 'auth'
    }
    $pageMeta.Authentication = $auth

    # add page meta to state
    Register-PodeWebPage -Metadata $pageMeta

    # add page link
    if (($null -ne $ScriptBlock) -and !(Test-PodeWebRoute -Path $pageMeta.Path)) {
        if (Test-PodeIsEmpty $EndpointName) {
            $EndpointName = Get-PodeWebState -Name 'endpoint-name'
        }

        # remove the "root" page, if "root-redirect" was originally flagged and this page is for the root path
        if (($pageMeta.Path -eq '/') -and (Get-PodeWebState -Name 'root-redirect')) {
            Remove-PodeRoute -Method Get -Path '/'
        }

        # add the route
        Add-PodeRoute -Method Post -Path $pageMeta.Path -Authentication $pageMeta.Authentication -ArgumentList @{ Data = $ArgumentList; ID = $Id } -Middleware $Middleware -IfExists $IfExists -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $pageData = (Get-PodeWebState -Name 'pages')[$Data.ID]
            Set-PodeWebMetadata

            $result = Invoke-PodeWebScriptBlock -Logic $pageData.Logic -Arguments $Data.Data

            if (($null -ne $result) -and !$WebEvent.Response.Headers.ContainsKey('Content-Disposition')) {
                Write-PodeJsonResponse -Value $result
            }
        }
    }
}

function ConvertTo-PodeWebPage {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
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

        Write-Verbose 'Getting exported commands from module'
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

    $sysParams = [System.Management.Automation.PSCmdlet]::CommonParameters.GetEnumerator() | Foreach-Object { $_ }

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
                # build name
                $name = $set.Name
                if ([string]::IsNullOrWhiteSpace($name) -or ($set.Name -iin @('__AllParameterSets'))) {
                    $name = 'Default'
                }

                # build input controls
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
                            New-PodeWebCheckbox -Name "$($name)_$($param.Name)" -DisplayName $param.Name -AsSwitch
                        }
                        else {
                            switch ($type) {
                                'pscredential' {
                                    New-PodeWebCredential -Name "$($name)_$($param.Name)" -DisplayName $param.Name
                                }

                                default {
                                    $multiple = $param.ParameterType.Name.EndsWith('[]')

                                    if ($param.Attributes.TypeId.Name -icontains 'ValidateSetAttribute') {
                                        $values = ($param.Attributes | Where-Object { $_.TypeId.Name -ieq 'ValidateSetAttribute' }).ValidValues
                                        New-PodeWebSelect -Name "$($name)_$($param.Name)" -DisplayName $param.Name -Options $values -SelectedValue $default -Multiple:$multiple
                                    }
                                    elseif ($param.ParameterType.BaseType.Name -ieq 'enum') {
                                        $values = [enum]::GetValues($param.ParameterType)
                                        New-PodeWebSelect -Name "$($name)_$($param.Name)" -DisplayName $param.Name -Options $values -SelectedValue $default -Multiple:$multiple
                                    }
                                    else {
                                        New-PodeWebTextbox -Name "$($name)_$($param.Name)" -DisplayName $param.Name -Value $default
                                    }
                                }
                            }
                        }
                    })

                $elements += (New-PodeWebHidden -Name '_Function_Name_' -Value $cmd)
                $elements += (New-PodeWebHidden -Name '_Parameter_Set_Name_' -Value $name)

                # build form
                $formId = "form_param_$($cmd)_$($name)"
                $form = New-PodeWebForm -Name "$($name)_Parameters_Form" -Id $formId -Content $elements -NoAuthentication:$NoAuthentication -ScriptBlock {
                    $cmd = $WebEvent.Data['_Function_Name_']
                    $WebEvent.Data.Remove('_Function_Name_')

                    $setName = $WebEvent.Data['_Parameter_Set_Name_']
                    $WebEvent.Data.Remove('_Parameter_Set_Name_')

                    $_args = @{}
                    foreach ($key in $WebEvent.Data.Keys) {
                        $argKey = $key -ireplace "$($setName)_", ''

                        if ($argKey -imatch '(?<name>.+)_(Username|Password)$') {
                            $name = $Matches['name']
                            $uKey = "$($argKey)_$($name)_Username"
                            $pKey = "$($argKey)_$($name)_Password"

                            if (![string]::IsNullOrWhiteSpace($WebEvent.Data[$uKey]) -and ![string]::IsNullOrWhiteSpace($WebEvent.Data[$pKey])) {
                                $creds = (New-Object System.Management.Automation.PSCredential -ArgumentList $WebEvent.Data[$uKey], (ConvertTo-SecureString -AsPlainText $WebEvent.Data[$pKey] -Force))
                                $_args[$name] = $creds
                            }
                        }
                        else {
                            if ($WebEvent.Data[$key] -iin @('true', 'false')) {
                                $_args[$argKey] = ($WebEvent.Data[$key] -ieq 'true')
                            }
                            else {
                                if ($WebEvent.Data[$key].Contains(',')) {
                                    $_args[$argKey] = ($WebEvent.Data[$key] -isplit ',' | ForEach-Object { $_.Trim() })
                                }
                                else {
                                    $_args[$argKey] = $WebEvent.Data[$key]
                                }
                            }
                        }
                    }

                    try {
                    (. $cmd @_args) |
                            New-PodeWebTextbox -Name 'Output_Result' -Multiline -Preformat |
                            Out-PodeWebElement
                    }
                    catch {
                        $_.Exception |
                            New-PodeWebTextbox -Name 'Output_Error' -Multiline -Preformat |
                            Out-PodeWebElement
                    }
                }

                $card = New-PodeWebCard -Name "$($name)_Parameters" -DisplayName 'Parameters' -Content $form
                New-PodeWebTab -Name $name -Content $card
            })

        $group = [string]::Empty
        if ($GroupVerbs) {
            $group = $cmdInfo.Verb
            if ([string]::IsNullOrWhiteSpace($group)) {
                $group = '_'
            }
        }

        Add-PodeWebPage `
            -Name $cmd `
            -Icon Settings `
            -Content $tabs `
            -Group $group `
            -NoAuthentication:$NoAuthentication
    }
}

function Use-PodeWebPages {
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

function Get-PodeWebPage {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    param(
        [Parameter(ParameterSetName = 'Id')]
        [string]
        $Id,

        [Parameter(ParameterSetName = 'Name')]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Name')]
        [string]
        $Group,

        [Parameter(ParameterSetName = 'Name')]
        [switch]
        $NoGroup
    )

    # get all pages
    $pages = Get-PodeWebState -Name 'pages'
    if (($null -eq $pages) -or ($pages.Count -eq 0)) {
        return $null
    }

    # if ID, check
    if (![string]::IsNullOrWhiteSpace($Id)) {
        return $pages[$Id]
    }

    # get page values
    $pages = $pages.Values

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

function Test-PodeWebPage {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Id')]
        [string]
        $Id,

        [Parameter(Mandatory = $true, ParameterSetName = 'Name')]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Name')]
        [string]
        $Group,

        [Parameter(ParameterSetName = 'Name')]
        [switch]
        $NoGroup
    )

    # by ID
    if (![string]::IsNullOrWhiteSpace($Id)) {
        return (Get-PodeWebState -Name 'pages').ContainsKey($Id)
    }

    # by Name/Group
    else {
        # get pages
        $pages = Get-PodeWebPage -Name $Name -Group $Group -NoGroup:$NoGroup

        # are there any pages?
        if ($null -eq $pages) {
            return $false
        }

        return (@($pages) | Measure-Object).Count -gt 0
    }
}

function New-PodeWebPageGroup {
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
        $Icon,

        [switch]
        $NoCounter,

        [switch]
        $Hide,

        [switch]
        $PassThru
    )

    # test if page group exists
    if (Test-PodeWebPageGroup -Name $Name) {
        throw "Page Group already exists: $($Name)"
    }

    # set display name
    if ([string]::IsNullOrEmpty($DisplayName)) {
        $DisplayName = $Name
    }

    # setup group meta
    $groupMeta = @{
        Operation     = 'New'
        ComponentType = 'Group'
        ObjectType    = 'Group'
        ID            = Get-PodeWebRandomName
        Name          = $Name
        DisplayName   = [System.Net.WebUtility]::HtmlEncode($DisplayName)
        Icon          = $Icon
        NoCounter     = $NoCounter.IsPresent
        Hide          = $Hide.IsPresent
        Pages         = @{}
    }

    # add group meta to state
    $groups = Get-PodeWebState -Name 'groups'
    $groups[$Name] = $groupMeta

    if ($PassThru) {
        return $groupMeta
    }
}

function Get-PodeWebPageGroup {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name = $null
    )

    $groups = Get-PodeWebState -Name 'groups'

    # get all groups on null
    if ($null -eq $Name) {
        return $groups
    }

    # return specific group
    return $groups[$Name]
}

function Test-PodeWebPageGroup {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name
    )

    return (Get-PodeWebState -Name 'groups').ContainsKey($Name)
}

function Remove-PodeWebPageGroup {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name
    )

    $null = (Get-PodeWebState -Name 'groups').Remove($Name)
}

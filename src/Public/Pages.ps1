function Set-PodeWebLoginPage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
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

        [switch]
        $PassThru
    )

    # check content
    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'The Login page can only contain layouts and/or elements'
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
        Group = $GroupProperty
        Avatar = $AvatarProperty
        Theme = $ThemeProperty
        Logout = $true
    }

    # get home url
    $sysUrls = Get-PodeWebState -Name 'system-urls'

    # set a default logo/url
    if ([string]::IsNullOrWhiteSpace($Logo)) {
        $Logo = '/pode.web/images/icon.png'
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
    $Id = Get-PodeWebPageId -Name 'login' -System

    # setup page meta
    $pageMeta = @{
        ComponentType = 'Page'
        ObjectType = 'Page'
        ID = $Id
        Route = @{
            Login = @{
                Path = '/login' #TODO: customisable
                Url = (Add-PodeWebAppPath -Url '/login')
            }
            Logout = @{
                Path = '/logout' #TODO: customisable
                Url = (Add-PodeWebAppPath -Url '/logout')
            }
        }
        Name = 'Login'
        Content = $Content
        SignInMessage = (Protect-PodeWebValue -Value $SignInMessage -Default 'Please sign in' -Encode)
        IsSystem = $true
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
            Page = $global:PageData
            Theme = Get-PodeWebTheme
            Logo = $using:Logo
            LogoUrl = $using:LogoUrl
            Background = @{
                Image = $using:BackgroundImage
            }
            SignInMessage = $global:PageData.SignInMessage
            Copyright = $using:Copyright
            Auth = @{
                Name = $using:Authentication
                IsOAuth2 = $using:isOAuth2
                GrantType = $using:grantType
            }
        }

        $global:PageData = $null
    }

    Add-PodeRoute -Method Post -Path $pageMeta.Route.Login.Path -Authentication $Authentication -EndpointName $endpointNames -Login

    # add the logout route
    Add-PodeRoute -Method Post -Path $pageMeta.Route.Logout.Path -Authentication $Authentication -EndpointName $endpointNames -Logout

    # login content
    Add-PodeRoute -Method Post -Path "$($pageMeta.Route.Login.Path)/content" -ArgumentList @{ ID = $Id } -EndpointName $endpointNames -ScriptBlock {
        param($Data)
        $global:PageData = (Get-PodeWebState -Name 'pages')[$Data.ID]
        Write-PodeJsonResponse -Value $global:PageData.Content
        $global:PageData = $null
    }

    # add an authenticated home route
    # Remove-PodeWebRoute -Method Get -Path $sysUrls.Home.Path -EndpointName $endpointNames

    # Add-PodeRoute -Method Get -Path $sysUrls.Home.Path -Authentication $Authentication -EndpointName $endpointNames -ScriptBlock {
    #     $page = Get-PodeWebFirstPublicPage
    #     if ($null -ne $page) {
    #         Move-PodeResponseUrl -Url (Get-PodeWebPagePath -Page $page)
    #         return
    #     }

    #     $authData = Get-PodeWebAuthData
    #     $username = Get-PodeWebAuthUsername -AuthData $authData
    #     $groups = Get-PodeWebAuthGroups -AuthData $authData
    #     $avatar = Get-PodeWebAuthAvatarUrl -AuthData $authData
    #     $theme = Get-PodeWebTheme
    #     $navigation = Get-PodeWebNavDefault

    #     Write-PodeWebViewResponse -Path 'index' -Data @{
    #         Page = @{
    #             Name = 'Home'
    #             Title = 'Home'
    #             DisplayName = 'Home'
    #             Path = '/'
    #             IsSystem = $true
    #         }
    #         Theme = $theme
    #         Navigation = $navigation
    #         Auth = @{
    #             Enabled = $true
    #             Logout = (Get-PodeWebState -Name 'auth-props').Logout
    #             Authenticated = $authData.IsAuthenticated
    #             Username = $username
    #             Groups = $groups
    #             Avatar = $avatar
    #         }
    #     }
    # }

    # Remove-PodeWebRoute -Method Post -Path "/content" -EndpointName $endpointNames

    # Add-PodeRoute -Method Post -Path "/content" -Authentication $Authentication -EndpointName $endpointNames -ScriptBlock {
    #     Write-PodeJsonResponse -Value @()
    # }

    if ($PassThru) {
        return $pageMeta
    }
}

# function Set-PodeWebHomePage
# {
#     [CmdletBinding()]
#     param(
#         [Parameter()]
#         [hashtable[]]
#         $Content,

#         [Parameter()]
#         [scriptblock]
#         $ScriptBlock,

#         [Parameter()]
#         [object[]]
#         $ArgumentList,

#         [Parameter()]
#         [string]
#         $DisplayName,

#         [Parameter()]
#         [string]
#         $Title,

#         [Parameter()]
#         [ValidateNotNullOrEmpty()]
#         [string]
#         $Icon = 'home',

#         [Parameter()]
#         [hashtable[]]
#         $Navigation,

#         [Parameter()]
#         [Alias('NoAuth')]
#         [switch]
#         $NoAuthentication,

#         [switch]
#         $NoTitle,

#         [switch]
#         $NoSidebar,

#         [switch]
#         $NoNavigation,

#         [switch]
#         $PassThru
#     )

#     # ensure layouts are correct
#     if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
#         throw 'The Home Page can only contain layouts/elements'
#     }

#     # set page title
#     if ([string]::IsNullOrWhiteSpace($DisplayName)) {
#         $DisplayName = 'Home'
#     }

#     if ([string]::IsNullOrWhiteSpace($Title)) {
#         $Title = $DisplayName
#     }

#     # route path
#     $routePath = '/'

#     # setup page meta
#     $pageMeta = @{
#         ComponentType = 'Page'
#         ObjectType = 'Page'
#         Path = $routePath
#         Name = 'Home'
#         Title = [System.Net.WebUtility]::HtmlEncode($Title)
#         DisplayName = [System.Net.WebUtility]::HtmlEncode($DisplayName)
#         NoTitle = $NoTitle.IsPresent
#         Icon = $Icon
#         Url = $routePath
#         NoSidebar = $NoSidebar.IsPresent
#         NoNavigation = $NoNavigation.IsPresent
#         Navigation = $Navigation
#         ScriptBlock = $ScriptBlock
#         Content = $Content
#         IsSystem = $true
#     }

#     # add page meta to state
#     $pages = Get-PodeWebState -Name 'pages'
#     $pages[$routePath] = $pageMeta

#     # does the page need auth?
#     $auth = $null
#     if (!$NoAuthentication) {
#         $auth = (Get-PodeWebState -Name 'auth')
#     }

#     # get the endpoints to bind
#     $endpointNames = Get-PodeWebState -Name 'endpoint-name'

#     # remove route
#     Remove-PodeWebRoute -Method Get -Path $routePath -EndpointName $endpointNames

#     # re-add route
#     Add-PodeRoute -Method Get -Path $routePath -Authentication $auth -ArgumentList @{ Data = $ArgumentList; Path = $routePath } -EndpointName $endpointNames -ScriptBlock {
#         param($Data)
#         $global:PageData = (Get-PodeWebState -Name 'pages')[$Data.Path]

#         # we either render the home page, or move to the first page if home page is blank
#         $comps = $global:PageData.Content
#         if ((($null -eq $comps) -or ($comps.Length -eq 0)) -and ($null -eq $global:PageData.ScriptBlock)) {
#             $page = Get-PodeWebFirstPublicPage
#             if ($null -ne $page) {
#                 Move-PodeResponseUrl -Url (Get-PodeWebPagePath -Page $page)
#                 return
#             }
#         }

#         $authData = Get-PodeWebAuthData
#         $username = Get-PodeWebAuthUsername -AuthData $authData
#         $groups = Get-PodeWebAuthGroups -AuthData $authData
#         $avatar = Get-PodeWebAuthAvatarUrl -AuthData $authData
#         $theme = Get-PodeWebTheme

#         Write-PodeWebViewResponse -Path 'index' -Data @{
#             Page = $global:PageData
#             Theme = $theme
#             Auth = @{
#                 Enabled = ![string]::IsNullOrWhiteSpace((Get-PodeWebState -Name 'auth'))
#                 Logout = (Get-PodeWebState -Name 'auth-props').Logout
#                 Authenticated = $authData.IsAuthenticated
#                 Username = $username
#                 Groups = $groups
#                 Avatar = $avatar
#             }
#         }

#         $global:PageData = $null
#     }

#     Remove-PodeWebRoute -Method Post -Path "$($routePath)content" -EndpointName $endpointNames

#     Add-PodeRoute -Method Post -Path "$($routePath)content" -Authentication $auth -ArgumentList @{ Data = $ArgumentList; Path = $routePath } -EndpointName $endpointNames -ScriptBlock {
#         param($Data)
#         $global:PageData = (Get-PodeWebState -Name 'pages')[$Data.Path]

#         $content = $null
#         if ($null -ne $global:PageData.ScriptBlock) {
#             $content = Invoke-PodeScriptBlock -ScriptBlock $global:PageData.ScriptBlock -Arguments $Data.Data -Splat -Return
#         }

#         if (($null -eq $content) -or ($content.Length -eq 0)) {
#             $content = $global:PageData.Content
#         }

#         $navigation = Get-PodeWebNavDefault -Items $global:PageData.Navigation
#         Write-PodeJsonResponse -Value (@($navigation) + @($content))

#         $global:PageData = $null
#     }

#     if ($PassThru) {
#         return $pageMeta
#     }
# }

function Add-PodeWebPage
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()] #TODO:
        [string]
        $Path,

        [Parameter()] #TODO:
        [object[]]
        $Middleware,

        [Parameter()] #TODO:
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

    # ensure layouts are correct
    if (!(Test-PodeWebContent -Content $Content -ComponentType Layout, Element)) {
        throw 'A Page can only contain layouts/elements'
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

    # setup page meta
    $pageMeta = @{
        ComponentType = 'Page'
        ObjectType = 'Page'
        ID = $Id
        Index = $Index
        Group = $Group
        Name = $Name
        Title = [System.Net.WebUtility]::HtmlEncode($Title)
        DisplayName = [System.Net.WebUtility]::HtmlEncode($DisplayName)
        NoTitle = $NoTitle.IsPresent
        NoBackArrow = $NoBackArrow.IsPresent
        NoBreadcrumb = $NoBreadcrumb.IsPresent
        NewTab = $NewTab.IsPresent
        IsDynamic = $false
        ShowHelp = ($null -ne $HelpScriptBlock)
        Icon = $Icon
        Path = (Get-PodeWebPagePath -Name $Name -Group $Group -Path $Path -NoAppPath)
        Url = (Get-PodeWebPagePath -Name $Name -Group $Group -Path $Path)
        Hide = $Hide.IsPresent
        NoSidebar = $NoSidebar.IsPresent
        NoNavigation = $NoNavigation.IsPresent
        Navigation = $Navigation
        ScriptBlock = $ScriptBlock
        HelpScriptBlock = $HelpScriptBlock
        Content = $Content
        NoAuthentication = $NoAuthentication.IsPresent
        IsHomePage = $HomePage.IsPresent
        Access = @{
            Groups = @($AccessGroups)
            Users = @($AccessUsers)
        }
    }

    # add page meta to state
    Register-PodeWebPage -Metadata $pageMeta

    # does the page need auth?
    $auth = $null
    if (!$NoAuthentication) {
        $auth = Get-PodeWebState -Name 'auth'
    }

    # get the endpoints to bind
    if (Test-PodeIsEmpty $EndpointName) {
        $EndpointName = Get-PodeWebState -Name 'endpoint-name'
    }

    # add the page route
    Add-PodeRoute -Method Get -Path $pageMeta.Path -Authentication $auth -ArgumentList @{ Data = $ArgumentList; ID = $Id } -EndpointName $EndpointName -ScriptBlock {
        param($Data)
        $global:PageData = (Get-PodeWebState -Name 'pages')[$Data.ID]

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

        # get auth details of a user
        $authData = Get-PodeWebAuthData
        $username = Get-PodeWebAuthUsername -AuthData $authData
        $groups = Get-PodeWebAuthGroups -AuthData $authData
        $avatar = Get-PodeWebAuthAvatarUrl -AuthData $authData
        $theme = Get-PodeWebTheme

        $authMeta = @{
            Enabled = ![string]::IsNullOrWhiteSpace((Get-PodeWebState -Name 'auth'))
            Logout = (Get-PodeWebState -Name 'auth-props').Logout
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
            Write-PodeWebViewResponse -Path 'index' -Data @{
                Page = $global:PageData
                Title = $global:PageData.Title
                DisplayName = $global:PageData.DisplayName
                Theme = $theme
                Auth = $authMeta
            }
        }

        $global:PageData = $null
    }

    Add-PodeRoute -Method Post -Path "/pode.web/pages/$($pageMeta.ID)/content" -Authentication $auth -ArgumentList @{ Data = $ArgumentList; ID = $Id } -EndpointName $EndpointName -ScriptBlock {
        param($Data)
        $global:PageData = (Get-PodeWebState -Name 'pages')[$Data.ID]

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
            # if we have a scriptblock, invoke that to get dynamic elements
            $content = $null
            if ($null -ne $global:PageData.ScriptBlock) {
                $content = Invoke-PodeScriptBlock -ScriptBlock $global:PageData.ScriptBlock -Arguments $Data.Data -Splat -Return
            }

            if (($null -eq $content) -or ($content.Length -eq 0)) {
                $content = $global:PageData.Content
            }

            $navigation = Get-PodeWebNavDefault -Items $global:PageData.Navigation
            Write-PodeJsonResponse -Value (@($navigation) + @($content))
        }

        $global:PageData = $null
    }

    # add the page help route
    $helpPath = "/pode.web/pages/$($pageMeta.ID)/help"
    if (($null -ne $HelpScriptBlock) -and !(Test-PodeWebRoute -Path $helpPath)) {
        Add-PodeRoute -Method Post -Path $helpPath -Authentication $auth -ArgumentList @{ Data = $ArgumentList; ID = $Id } -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $global:PageData = (Get-PodeWebState -Name 'pages')[$Data.ID]

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
                $result = Invoke-PodeScriptBlock -ScriptBlock $global:PageData.HelpScriptBlock -Arguments $Data.Data -Splat -Return
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

    if ($PassThru) {
        return $pageMeta
    }
}

function Add-PodeWebPageLink
{
    [CmdletBinding(DefaultParameterSetName='ScriptBlock')]
    param(
        [Parameter()]
        [string]
        $Id,
    
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(ParameterSetName='ScriptBlock')] #TODO:
        [object[]]
        $Middleware,

        [Parameter()] #TODO:
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

    # setup page meta
    $pageMeta = @{
        ComponentType = 'Page'
        ObjectType = 'Link'
        ID = $Id
        Index = $Index
        Name = $Name
        Group = $Group
        DisplayName = [System.Net.WebUtility]::HtmlEncode($DisplayName)
        NewTab = $NewTab.IsPresent
        Icon = $Icon
        Path = (Get-PodeWebPagePath -Name $Name -Group $Group -NoAppPath)
        Url = (Add-PodeWebAppPath -Url $Url)
        Hide = $Hide.IsPresent
        IsDynamic = ($null -ne $ScriptBlock)
        ScriptBlock = $ScriptBlock
        Access = @{
            Groups = @($AccessGroups)
            Users = @($AccessUsers)
        }
        NoEvents = $true
    }

    # add page meta to state
    Register-PodeWebPage -Metadata $pageMeta

    # add page link
    if (($null -ne $ScriptBlock) -and !(Test-PodeWebRoute -Path $pageMeta.Path)) {
        $auth = $null
        if (!$NoAuthentication) {
            $auth = (Get-PodeWebState -Name 'auth')
        }

        if (Test-PodeIsEmpty $EndpointName) {
            $EndpointName = Get-PodeWebState -Name 'endpoint-name'
        }

        Add-PodeRoute -Method Post -Path $pageMeta.Path -Authentication $auth -ArgumentList @{ Data = $ArgumentList; ID = $Id } -EndpointName $EndpointName -ScriptBlock {
            param($Data)
            $pageData = (Get-PodeWebState -Name 'pages')[$Data.ID]

            $result = Invoke-PodeScriptBlock -ScriptBlock $pageData.ScriptBlock -Arguments $Data.Data -Splat -Return
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

            New-PodeWebTab -Name $name -Content $form
        })

        $group = [string]::Empty
        if ($GroupVerbs) {
            $group = $cmdInfo.Verb
            if ([string]::IsNullOrWhiteSpace($group)) {
                $group = '_'
            }
        }

        Add-PodeWebPage -Name $cmd -Icon Settings -Content $tabs -Group $group -NoAuthentication:$NoAuthentication
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
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(ParameterSetName='Name')]
        [string]
        $Group,

        [Parameter(ParameterSetName='Name')]
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

function Test-PodeWebPage
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(ParameterSetName='Name')]
        [string]
        $Group,

        [Parameter(ParameterSetName='Name')]
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

function New-PodeWebPageGroup
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
        ComponentType = 'Group'
        ObjectType = 'Group'
        ID = Get-PodeWebRandomName
        Name = $Name
        DisplayName = [System.Net.WebUtility]::HtmlEncode($DisplayName)
        Icon = $Icon
        NoCounter = $NoCounter.IsPresent
        Hide = $Hide.IsPresent
        Pages = @{}
    }

    # add group meta to state
    $groups = Get-PodeWebState -Name 'groups'
    $groups[$Name] = $groupMeta

    if ($PassThru) {
        return $groupMeta
    }
}

function Get-PodeWebPageGroup
{
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

function Test-PodeWebPageGroup
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name
    )

    return (Get-PodeWebState -Name 'groups').ContainsKey($Name)
}

function Remove-PodeWebPageGroup
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name
    )

    $null = (Get-PodeWebState -Name 'groups').Remove($Name)
}
# Pages

There are 3 different kinds of pages in Pode.Web, which are defined below. Other than the Login page, the Home and normal Webpages can be populated with custom elements. When you add pages to your site, they appear on the sidebar for navigation - unless they are specified to be hidden from the sidebar.

## Login

To enable the use of a login page, and lock your site behind authentication is simple! First, just setup sessions and define the authentication method you want via the usual `Enable-PodeSessionMiddleware`, `New-PodeAuthScheme` and `Add-PodeAuth` in Pode. Then, pass the authentication name into [`Set-PodeWebLoginPage`](../../Functions/Pages/Set-PodeWebLoginPage) - and that's it!

!!! note
    Since the login page uses a form to logging a user in, the best scheme to use is Forms: `New-PodeAuthScheme -Form`. OAuth also works, as the login page will automatically trigger the relevant redirects.

```powershell
Enable-PodeSessionMiddleware -Duration 120 -Extend

New-PodeAuthScheme -Form | Add-PodeAuth -Name Example -ScriptBlock {
    param($username, $password)

    return @{
        User = @{
            ID ='M0R7Y302'
            Name = 'Morty'
            Type = 'Human'
        }
    }
}

Set-PodeWebLoginPage -Authentication Example
```

By default the Pode icon is displayed as the logo, but you can change this by using the `-Logo` parameter; this takes a literal or relative URL to an image file.

### IIS

If you're hosting the site using IIS, and want to use Windows Authentication within IIS, then you can setup authentication in Pode.Web via [`Set-PodeWebAuth`](../../Functions/Utilities/Set-PodeWebAuth). This works similar to `Set-PodeWebLoginPage`, and sets up authentication on the pages, but it doesn't cause a login page or the sign-in/out buttons to appear. Instead, Pode.Web gets the session from IIS, and then displays the logged in user at the top - similar to how the login page would after a successful login.

```powershell
Enable-PodeSessionMiddleware -Duration 120 -Extend
Add-PodeAuthIIS -Name Example
Set-PodeWebAuth -Authentication Example
```

### Custom Fields

By default the Login page will display a login form with Username and Password inputs. This can be overridden by supplying custom Layouts and Elements to the `-Content` parameter of [`Set-PodeWebLoginPage`](../../Functions/Pages/Set-PodeWebLoginPage). Any custom content will be placed between the "Please sign in" message and the "Sign In" button.

```powershell
# setup sessions
Enable-PodeSessionMiddleware -Duration 120 -Extend

# define a new custom authentication scheme, which needs a client, username, and password
$custom_scheme = New-PodeAuthScheme -Custom -ScriptBlock {
    param($opts)

    # get the client/user/password from the request's post data
    $client = $WebEvent.Data.client
    $username = $WebEvent.Data.username
    $password = $WebEvent.Data.password

    # return the data in a array, which will be passed to the validator script
    return @($client, $username, $password)
}

# now, add a new custom authentication validator using the scheme you created above
$custom_scheme | Add-PodeAuth -Name Example -ScriptBlock {
    param($client, $username, $password)

    # check if the client is valid in some database
    return @{
        User = @{
            ID ='M0R7Y302'
            Name = 'Morty'
            Type = 'Human'
        }
    }

    # return a user object (return $null if validation failed)
    return  @{ User = $user }
}

# set the login page to use the custom auth, and also custom login fields
Set-PodeWebLoginPage -Authentication Example -Content @(
    New-PodeWebTextbox -Type Text -Name 'client' -Id 'client' -Placeholder 'Client' -Required -AutoFocus -DynamicLabel
    New-PodeWebTextbox -Type Text -Name 'username' -Id 'username' -Placeholder 'Username' -Required -DynamicLabel
    New-PodeWebTextbox -Type Password -Name 'password' -Id 'password' -Placeholder 'Password' -Required -DynamicLabel
)
```

Which would look like below:

![login_custom](../../images/login_custom.png)

## Home

Every site is setup with a default empty home page. If you choose not to add anything to your home page, then Pode.Web will automatically redirect to the first Webpage.

To setup the home page with content, you use [`Set-PodeWebHomePage`](../../Functions/Pages/Set-PodeWebHomePage). At its simplest this just takes an array of `-Content` to render on the page. For example, if you wanted to add a quick Hero element to your home page:

```powershell
Set-PodeWebHomePage -Content @(
    New-PodeWebHero -Title 'Welcome!' -Message 'This is the home page' -Content @(
        New-PodeWebText -Value 'Here is some text!' -InParagraph -Alignment Center
    )
)
```

or, you can do this dynamically by supplying `-ScriptBlock` instead:

```powershell
Set-PodeWebHomePage -ScriptBlock {
    New-PodeWebHero -Title 'Welcome!' -Message 'This is the home page' -Content @(
        New-PodeWebText -Value 'Here is some text!' -InParagraph -Alignment Center
    )
}
```

If you want to hide the title on the home page, you can pass `-NoTitle`. You can also change the home page icon via `-Icon`.

## Webpage

By adding a page to your site, Pode.Web will add a link to it on your site's sidebar navigation. You can also group pages together so you can collapse groups of them. To add a page to your site you use [`Add-PodeWebPage`](../../Functions/Pages/Add-PodeWebPage), and you can give your page a `-Name` and an `-Icon` to display on the sidebar. Pages can either be [static](#static) or [dynamic](#dynamic).

!!! note
    The `-Icon` is the name of a [Material Design Icon](https://materialdesignicons.com), a list of which can be found on their [website](https://pictogrammers.github.io/@mdi/font/5.4.55/). When supplying the name, just supply the part after `mdi-`. For example, `mdi-github` should be `-Icon 'github'`.

For example, to add a simple Charts page to your site, to show a Windows counter:

```powershell
Add-PodeWebPage -Name Charts -Icon 'bar-chart-2' -Content @(
    New-PodeWebCard -Content @(
        New-PodeWebCounterChart -Counter '\Processor(_Total)\% Processor Time'
    )
)
```

You can split up your pages into different .ps1 files, if you do and you place them within a `/pages` directory, then [`Use-PodeWebPages`](../../Functions/Pages/Use-PodeWebPages) will auto-load them all for you.

### Link

If you just need to place a redirect link into the sidebar, then use [`Add-PodeWebPageLink`](../../Functions/Pages/Add-PodeWebPageLink). This works in a similar way to `Add-PodeWebPage`, but takes either a flat `-Url` to redirect to, or a `-ScriptBlock` that you can return actions from. Page links can also be grouped, like normal pages.

Flat URLs:

```powershell
Add-PodeWebPageLink -Name Twitter -Url 'https://twitter.com' -Icon 'twitter' -NewTab
```

Or a dynamic link:

```powershell
Add-PodeWebPageLink -Name Twitter -Icon Twitter -ScriptBlock {
    Move-PodeWebUrl -Url 'https://twitter.com' -NewTab
}
```

### Group

You can group multiple pages together on the sidebar by using the `-Group` parameter on [`Add-PodeWebPage`](../../Functions/Pages/Add-PodeWebPage). This will group pages together into a collapsible container.

### Help Icon

A help icon can be displayed to the right of the page's title by supplying a `-HelpScriptBlock` to [`Add-PodeWebPage`](../../Functions/Pages/Add-PodeWebPage). This scriptblock is used to return actions such as: displaying a modal when the help icon is clicked; redirect the user to a help page; or any other possible actions to help a user out.

### Static

A static page is one that uses just `-Content`; this is a page that will render the same elements on every page load, regardless of payload or query parameters supplied to the page.

For example, this page will always render a form to search for processes:

```powershell
Add-PodeWebPage -Name Processes -Icon Activity -Content @(
    New-PodeWebCard -Content @(
        New-PodeWebForm -Name 'Search' -ScriptBlock {
            Get-Process -Name $WebEvent.Data.Name -ErrorAction Ignore |
                Select-Object Name, ID, WorkingSet, CPU |
                New-PodeWebTextbox -Name 'Output' -Multiline -Preformat -ReadOnly |
                Out-PodeWebElement
        } -Content @(
            New-PodeWebTextbox -Name 'Name'
        )
    )
)
```

### Dynamic

Add dynamic page uses a `-ScriptBlock` instead of `-Content`, the scriptblock lets you render different elements depending on query/payload data in the `$WebEvent`. The scriptblock also has access to a `$PageData` object, containing information about the current page - such as Name, Group, Access, etc.

For example, the below page will render a table of services if a `value` query parameter is not present. Otherwise, if it is present, then a page with a code-block showing information about the service is displayed:

```powershell
Add-PodeWebPage -Name Services -Icon Settings -ScriptBlock {
    $value = $WebEvent.Query['value']

    # table of services
    if ([string]::IsNullOrWhiteSpace($value)) {
        New-PodeWebCard -Content @(
            New-PodeWebTable -Name 'Services' -DataColumn Name -Click -ScriptBlock {
                foreach ($svc in (Get-Service)) {
                    [ordered]@{
                        Name = $svc.Name
                        Status = "$($svc.Status)"
                    }
                }
            }
        )
    }

    # code-block with service info
    else {
        $svc = Get-Service -Name $value | Out-String

        New-PodeWebCard -Name "$($value) Details" -Content @(
            New-PodeWebCodeBlock -Value $svc -NoHighlight
        )
    }
}
```

You can also supply `-Content` while using `-ScriptBlock`. If the scriptblock returns no data, then whatever is supplied to `-Content` is treated as the default content for the page.

For example, the below is the same as the above example, but this time the table is set using `-Content`:

```powershell
$servicesTable = New-PodeWebCard -Content @(
    New-PodeWebTable -Name 'Services' -DataColumn Name -Click -ScriptBlock {
        foreach ($svc in (Get-Service)) {
            [ordered]@{
                Name = $svc.Name
                Status = "$($svc.Status)"
            }
        }
    }
)

Add-PodeWebPage -Name Services -Icon Settings -Content $servicesTable -ScriptBlock {
    $value = $WebEvent.Query['value']

    # use default layouts - in this case, the services table
    if ([string]::IsNullOrWhiteSpace($value)) {
        return
    }

    # code-block with service info
    $svc = Get-Service -Name $value | Out-String

    New-PodeWebCard -Name "$($value) Details" -Content @(
        New-PodeWebCodeBlock -Value $svc -NoHighlight
    )
}
```

You can pass values to the scriptblock by using the `-ArgumentList` parameter. This accepts an array of values/objects, and they are supplied as parameters to the scriptblock:

```powershell
Add-PodeWebPage -Name Services -Icon Settings -ArgumentList 'Value1', 2, $false -ScriptBlock {
    param($value1, $value2, $value3)

    # $value1 = 'Value1'
    # $value2 = 2
    # $value3 = $false
}
```

### No Authentication

If you add a page when you've enabled authentication, you can set a page to be accessible without authentication by supplying the `-NoAuth` switch to [`Add-PodeWebPage`](../../Functions/Pages/Add-PodeWebPage).

If you do this and you add all elements/layouts dynamically (via `-ScriptBlock`), then there's no further action needed.

If however you're added the elements/layouts using the `-Content` parameter, then certain elements/layouts will also need their `-NoAuth` switches to be supplied (such as charts, for example), otherwise data/actions will fail with a 401 response.

### Sidebar

When you add a page by default it will show in the sidebar. You can stop pages/links from appearing in the sidebar by using the `-Hide` switch:

```powershell
Add-PodeWebPage -Name Charts -Hide -Content @(
    New-PodeWebCard -Content @(
        New-PodeWebCounterChart -Counter '\Processor(_Total)\% Processor Time'
    )
)
```


## Hide Navigations

You can hide the sidebar on a page (home or webpage) by using the `-NoSidebar` switch; useful for dashboard pages:

```powershell
Add-PodeWebPage -Name Charts -NoSidebar -Content @(
    New-PodeWebCard -Content @(
        New-PodeWebCounterChart -Counter '\Processor(_Total)\% Processor Time'
    )
)
```

Conversely, you can also hide the top navigation bar by using the `-NoNavigation` switch as well.

## Convert Module

Similar to how Pode has a function to convert a Module to a REST API; Pode.Web has one that can convert a Module into Web Pages: [`ConvertTo-PodeWebPage`](../../Functions/Pages/ConvertTo-PodeWebPage)!

For example, if you wanted to make a web portal for the [Pester](https://github.com/pester/Pester) module:

```powershell
Import-Module Pode.Web

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http

    # set the use of templates
    Use-PodeWebTemplates -Title 'Pester'

    # convert module to pages
    ConvertTo-PodeWebPage -Module Pester -GroupVerbs
}
```

## Events

The Login, Home and Webpages support registering the following events, and they can be registered via [`Register-PodeWebPageEvent`](../../Functions/Events/Register-PodeWebPageEvent):

| Name | Description |
| ---- | ----------- |
| Load | Fires when the page has fully loaded, including js/css/etc. |
| Unload | Fires when the has fully unloaded/closed |
| BeforeUnload | Fires just before the page is about to unload/close |

To register an event for each page type:

* `Login`: you'll need to use `-PassThru` on [`Set-PodeWebLoginPage`](../../Functions/Pages/Set-PodeWebLoginPage) and pipe the result in [`Register-PodeWebPageEvent`](../../Functions/Events/Register-PodeWebPageEvent).
* `Home`: you'll need to use `-PassThru` on [`Set-PodeWebHomePage`](../../Functions/Pages/Set-PodeWebHomePage) and pipe the result in [`Register-PodeWebPageEvent`](../../Functions/Events/Register-PodeWebPageEvent).
* `Webpage`: you'll need to use `-PassThru` on [`Add-PodeWebPage`](../../Functions/Pages/Add-PodeWebPage) and pipe the result in [`Register-PodeWebPageEvent`](../../Functions/Events/Register-PodeWebPageEvent).

For example, if you want to show a message on a Webpage just before it closes:

```powershell
Add-PodeWebPage -Name Example -Content $some_layouts -PassThru |
    Register-PodeWebPageEvent -Type BeforeUnload -ScriptBlock {
        Show-PodeWebToast -Message "Bye!"
    }
```

Or on the Login page, after it's finished loading (note: you will need to use the `-NoAuth` switch):

```powershell
Set-PodeWebLoginPage -Authentication Example -PassThru |
    Register-PodeWebPageEvent -Type Load -NoAuth -ScriptBlock {
        Show-PodeWebToast -Message "Hi!"
    }
```

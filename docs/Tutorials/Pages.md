# Pages

There are 3 different kinds of pages in Pode.Web, which are defined below. Besides the Login page, the Home and normal Webpages can be populated with Layouts and Elements. When you add pages to your site, they appear on sidebar for navigation.

## Login

To enable the use of a login page, and lock your site behind authentication is simple! First, just setup sessions and define the authentication method you want via the usual `Enable-PodeSessionMiddleware`, `New-PodeAuthScheme` and `Add-PodeAuth` in Pode. Then, pass the authentication name into [`Set-PodeWebLoginPage`](../../Functions/Pages/Set-PodeWebLoginPage) - and that's it!

```powershell
Enable-PodeSessionMiddleware -Secret 'schwifty' -Duration 120 -Extend

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

## Home

Every site is setup with a default empty home page. If you choose not to add anything to your home page, then Pode.Web will automatically redirect to the first Webpage.

To setup the home page with content, you use [`Set-PodeWebHomePage`](../../Functions/Pages/Set-PodeWebHomePage). At its simplest this just takes an array of `-Layouts` to render on the page. For example, if you wanted to add a quick Hero element to your home page:

```powershell
Set-PodeWebHomePage -Layouts @(
    New-PodeWebHero -Title 'Welcome!' -Message 'This is the home page' -Content @(
        New-PodeWebText -Value 'Here is some text!' -InParagraph -Alignment Center
    )
)
```

If you want to hide the title on the home page, you can pass `-NoTitle`.

## Webpage

By adding a page to your site, Pode.Web will add a link to it on your site's sidebar navigation. You can also group pages together so you can collapse groups of them. To add a page to your site you use [`Add-PodeWebPage`](../../Functions/Pages/Add-PodeWebPage), and you can give your page a `-Name` and an `-Icon` to display on the sidebar. Pages can either be [static](#static) or [dynamic](#dynamic).

!!! note
    The `-Icon` is the name of a [Material Design Icon](https://materialdesignicons.com), a list of which can be found on their [website](https://pictogrammers.github.io/@mdi/font/5.4.55/). When supplyig the name, just supply the part after `mdi-`. For example, `mdi-github` should be `-Icon 'github'`.

For example, to add a simple Charts page to your site, to show a Windows counter:

```powershell
Add-PodeWebPage -Name Charts -Icon 'bar-chart-2' -Layouts @(
    New-PodeWebCard -Content @(
        New-PodeWebCounterChart -Counter '\Processor(_Total)\% Processor Time'
    )
)
```

You can split up your pages into different .ps1 files, if you do and you place them within a `/pages` directory, then [`Use-PodeWebPages`](../../Functions/Pages/Use-PodeWebPages) will auto-load them all for you.

### Link

If you just need to place a redirect link into the sidebar, then use [`Add-PodeWebPageLink`](../../Functions/Pages/Add-PodeWebPageLink). This works in a similar way to `Add-PodeWebPage`, but takes either a flat `-Url` to redirect to, or a `-ScriptBlock` that you can return output actions from - *not* layouts/elements. Page links can also be grouped, like normal pages.

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

### Static

A static page is one that uses just `-Layouts`; this is a page that will render the same layouts/elements on every page load, regardless of payload or query parameters supplied to the page.

For example, this page will always render a form to search for processes:

```powershell
Add-PodeWebPage -Name Processes -Icon Activity -Layouts @(
    New-PodeWebCard -Content @(
        New-PodeWebForm -Name 'Search' -ScriptBlock {
            Get-Process -Name $WebEvent.Data.Name -ErrorAction Ignore |
                Select-Object Name, ID, WorkingSet, CPU |
                Out-PodeWebTextbox -Multiline -Preformat -ReadOnly
        } -Content @(
            New-PodeWebTextbox -Name 'Name'
        )
    )
)
```

### Dynamic

Add dynamic page uses a `-ScriptBlock` instead of `-Layouts`, the scriptblock lets you render different layouts/elements depending on query/payload data in the `$WebEvent`. The scriptblock also has access to a `$PageData` object, containing information about the current page - such as Name, Group, Access, etc.

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

You can also supply `-Layouts` while using `-ScriptBlock`. If the scriptblock returns no data, then whatever is supplied to `-Layouts` is treated as the default content for the page.

For example, the below is the same as the above example, but this time the table is set using `-Layouts`:

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

Add-PodeWebPage -Name Services -Icon Settings -Layouts $servicesTable -ScriptBlock {
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

### No Authentication

If you add a page when you've enabled authentication, you can set a page to be accessible without authentication by supplying the `-NoAuth` switch to [`Add-PodeWebPage`](../../Functions/Pages/Add-PodeWebPage).

If you do this and you add all elements/layouts dynamically (via `-ScriptBlock`), then there's no further action needed.

If however you're added the elements/layouts using the `-Layouts` parameter, then certain elements/layouts will also need their `-NoAuth` switches to be supplied (such as charts, for example), otherwise data/actions will fail with a 401 response.

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

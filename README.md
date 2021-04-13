# Pode.Web

> This is still a work in progress, until v1.0.0 expect possible breaking changes in some releases.

[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/Badgerati/Pode.Web/master/LICENSE.txt)
[![GitHub Actions](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fbadgerati%2Fpode.web%2Fbadge&style=flat&label=GitHub)](https://actions-badge.atrox.dev/badgerati/pode.web/goto)
[![Gitter](https://badges.gitter.im/Badgerati/Pode.svg)](https://gitter.im/Badgerati/Pode?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![PowerShell](https://img.shields.io/powershellgallery/dt/pode.web.svg?label=PowerShell&colorB=085298)](https://www.powershellgallery.com/packages/Pode.Web)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/Badgerati?color=%23ff69b4&logo=github&style=flat&label=Sponsers)](https://github.com/sponsors/Badgerati)

This is a web template framework for use with the [Pode](https://github.com/Badgerati/Pode) PowerShell web server (v2.2.0+).

It allows you to build web pages purely with PowerShell - no HTML, CSS, or JavaScript knowledge required!

You can build charts, forms, tables, general text, tabs, login pages, etc. There's a light, dark, and terminal themes, and you can supply a custom CSS file.

## Libraries

The Pode.Web templates are built using [Bootstrap](https://getbootstrap.com), [jQuery](https://jquery.com), [Feather icons](https://feathericons.com), [Chart.js](https://www.chartjs.org), and [Highlight.js](https://github.com/highlightjs/highlight.js).

To speed-up loading of pages, enable caching within your `server.psd1` file:

```powershell
@{
    Web = @{
        Static = @{
            Cache = @{
                Enable = $true
            }
        }
    }
}
```

> Note: where an `-Icon` parameter is available, refer to [Feather icons](https://feathericons.com) for names

## Contributing

Pull Requests, Bug Reports and Feature Requests are welcome! Feel free to help out with Issues and Projects!

To build Pode.Web, before running any examples, run the following:

```powershell
Invoke-Build Build
```

To work on issues you can fork Pode.Web, and then open a Pull Request for approval. Pull Requests should be made against the `develop` branch. Each Pull Request should also have an appropriate issue created.

## Usage

To use the Pode.Web templates, you first need to call `Use-PodeWebTemplates`; you can supply a Title, Logo, FavIcon, or change the Theme:

```powershell
Import-Module Pode
Import-Module Pode.Web

Start-PodeServer {
    Use-PodeWebTemplates -Title 'Some Title' -Theme Dark
}
```

The `-Logo` and `-FavIcon` must be URL paths relative to your site's `/public` directory.

You can import custom CSS/JS files by using `Import-PodeWebStylesheet` or `Import-PodeWebJavaScript`. You can also setup social icons using `Set-PodeWebSocial`.

### Login

By default, a site will not use authentication. To do so, you need to set sessions/authentication, and then call `Set-PodeWebLoginPage`:

```powershell
Import-Module Pode
Import-Module Pode.Web

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http

    # enable sessions and authentication
    Enable-PodeSessionMiddleware -Secret 'schwifty' -Duration (10 * 60) -Extend

    New-PodeAuthScheme -Form | Add-PodeAuth -Name Login -ScriptBlock {
        param($username, $password)

        # here you'd check a real user storage, this is just for example
        if ($username -eq 'morty' -and $password -eq 'pickle') {
            return @{
                User = @{ ID ='M0R7Y302'; Name = 'Morty'; Type = 'Human' }
            }
        }

        return @{ Message = 'Invalid details supplied' }
    }

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Login Example'
    Set-PodeWebLoginPage -Authentication Login
}
```

Accessing any page will auto-redirect to a login page. If you want a page to be accessible without authentication - like a simple Home/About Page - supply `-NoAuth` to `Add-PodeWebPage` or `Set-PodeWebHomePage`. If you do this, and that page contains elements that calls backend routes, ensure you supply `-NoAuth` where appropriate or you'll get 401 errors.

### Module to Pages

Similar to how Pode has a function to convert a Module to a REST API; Pode.Web has one that can convert a Module into Web Pages: `ConvertTo-PodeWebPage`!

For example, if you wanted to make a web portal for the Pester module:

```powershell
Import-Module Pode
Import-Module Pode.Web

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http

    # set the use of templates
    Use-PodeWebTemplates -Title 'Pester'

    # convert module to pages
    ConvertTo-PodeWebPage -Module Pester -NoAuthentication -GroupVerbs
}
```

or if you want to force authentication:

```powershell
Import-Module Pode
Import-Module Pode.Web

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http

    # enable sessions and authentication
    Enable-PodeSessionMiddleware -Secret 'schwifty' -Duration (10 * 60) -Extend

    New-PodeAuthScheme -Form | Add-PodeAuth -Name Login -ScriptBlock {
        param($username, $password)

        # here you'd check a real user storage, this is just for example
        if ($username -eq 'morty' -and $password -eq 'pickle') {
            return @{
                User = @{ ID ='M0R7Y302'; Name = 'Morty'; Type = 'Human' }
            }
        }

        return @{ Message = 'Invalid details supplied' }
    }

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Pester'
    Set-PodeWebLoginPage -Authentication Login

    # convert module to pages
    ConvertTo-PodeWebPage -Module Pester -GroupVerbs
}
```

## Layouts

Layouts let you customise the way elements are rendered/controlled. Layouts can contain other layouts, or elements - apart from certain layouts.

* Grids (only contains Cells, which can only contain other layouts)
* Tabs (only contains Tabs, which can only contain other layouts)
* Card
* Container
* Modal
* Hero
* Carousel (only contains Slides, which can contain other layouts/elements)
* Steps (only contains Steps, which can contain other layouts/elements)

## Elements

These are the base elements that can be used in most layouts. In some cases, some elements can contain other elements, or even layouts.

* Textbox
* File Upload
* Paragraph (can either be a value, or contain other elements)
* Code Block
* Code
* Checkbox
* Radio
* Select
* Range
* Progress Bar
* Image
* Header
* Quote
* List
* Link
* Text
* Line
* Hidden
* Credentials
* DateTime
* Raw
* Button
* Alert (can either be a value, or contain other elements)
* Icon
* Spinner
* Badge
* Comment Block
* Charts / CounterCharts
* Tables + Pagination
* Monaco Code Editor (WIP)
* Forms (can either be a value, or contain other elements)
* Timers
* Breadcrumbs (used to set the breadcrumb items at the top of the page)

> Tables, Forms, and Charts each have an `-AsCard` switch, is auto-wraps the element in a Card layout.

## Outputs

Outputs allow you to manipulate the frontend from action ScriptBlocks - such as submitting a form which renders a Toast, and outputs to a Table:

* Tables (out/sync)
* Table Row (update)
* Charts (out)
* Textbox (out)
* Toast (show)
* Validation (out)
* Form (reset)
* Text (out)
* Badge (out)
* Checkbox (out)
* Modal (show/hide)
* Error (show)
* Desktop Notifications (show)
* Page (move/refresh)
* URL (move)
* Tabs (move)
* Breadcrumb (out)

## Examples

> More examples can be found in the examples directory (the full.ps1 has example of nearly everything)

### Home Page

This is a simple example with a basic home page, and a page to query processes:

```powershell
Import-Module Pode
Import-Module Pode.Web

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http

    # set the use of templates
    Use-PodeWebTemplates -Title 'Basic Example'

    # set the home page elements (just a simple paragraph)
    $section = New-PodeWebCard -Name 'Welcome' -NoTitle -Content @(
        New-PodeWebParagraph -Value 'This is an example homepage, with some example text'
        New-PodeWebParagraph -Value 'Using some example paragraphs'
    )

    Set-PodeWebHomePage -Layouts $section -Title 'Awesome Homepage'

    # add a page to search process (output as json in an appended textbox)
    $form = New-PodeWebForm -Name 'Search' -AsCard -ScriptBlock {
        Get-Process -Name $WebEvent.Data.Name -ErrorAction Ignore | Select-Object Name, ID, WorkingSet, CPU | Out-PodeWebTextbox -Multiline -Preformat -AsJson
    } -Content @(
        New-PodeWebTextbox -Name 'Name'
    )

    Add-PodeWebPage -Name Processes -Icon Activity -Layouts $form
}
```

Navigate to `http://localhost:8090/`.

### Login Page

This example is similar to above, but this time with authentication and a login page:

```powershell
Import-Module Pode
Import-Module Pode.Web

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http

    # enable sessions and authentication
    Enable-PodeSessionMiddleware -Secret 'schwifty' -Duration (10 * 60) -Extend

    New-PodeAuthScheme -Form | Add-PodeAuth -Name Login -ScriptBlock {
        param($username, $password)

        # here you'd check a real user storage, this is just for example
        if ($username -eq 'morty' -and $password -eq 'pickle') {
            return @{
                User = @{ ID ='M0R7Y302'; Name = 'Morty'; Type = 'Human' }
            }
        }

        return @{ Message = 'Invalid details supplied' }
    }

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Basic Example'
    Set-PodeWebLoginPage -Authentication Login

    # set the home page controls (just a simple paragraph)
    $section = New-PodeWebCard -Name 'Welcome' -NoTitle -Content @(
        New-PodeWebParagraph -Value 'This is an example homepage, with some example text'
        New-PodeWebParagraph -Value 'Using some example paragraphs'
    )
    Set-PodeWebHomePage -Layouts $section -Title 'Awesome Homepage'

    # add a page to search process (output as json in an appended textbox)
    $form = New-PodeWebForm -Name 'Search' -AsCard -ScriptBlock {
        Get-Process -Name $WebEvent.Data.Name -ErrorAction Ignore | Select-Object Name, ID, WorkingSet, CPU | Out-PodeWebTextbox -Multiline -Preformat -AsJson
    } -Content @(
        New-PodeWebTextbox -Name 'Name'
    )

    Add-PodeWebPage -Name Processes -Icon Activity -Layouts $form
}
```

Navigate to `http://localhost:8090/`. The login details are `morty` and `pickle`.

## Screenshots

### Login

![Login](/images/login.png)

### Table Filter

![TableFilter](/images/table_filter.png)
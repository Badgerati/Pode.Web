# Pode.Web

> This is still a work in progress, until v1.0.0 expect possible breaking changes in some releases.

[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/Badgerati/Pode.Web/master/LICENSE.txt)
[![Gitter](https://badges.gitter.im/Badgerati/Pode.svg)](https://gitter.im/Badgerati/Pode?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![PowerShell](https://img.shields.io/powershellgallery/dt/pode.web.svg?label=PowerShell&colorB=085298)](https://www.powershellgallery.com/packages/Pode.Web)

This is a web template framework for use with the [Pode](https://github.com/Badgerati/Pode) PowerShell web server (version 2.0+).

It allows you to build web pages purely with PowerShell - no HTML, CSS, or JavaScript knowledge required!

You can build charts, forms, tables, general text, tabs, login pages, etc. There's a light/dark theme, and you can supply and custom CSS file yourself.

## Libraries

The Pode.Web templates are built using [Bootstrap](https://getbootstrap.com), [jQuery](https://jquery.com), [Feather icons](https://feathericons.com), [Chart.js](https://www.chartjs.org), and [Highlight.js](https://github.com/highlightjs/highlight.js).

At present these are loaded using the jsDelivr CDN.

> Note: where a `-Icon` parameter is available, refer to [Feather icons](https://feathericons.com) for names

## Usage

To use the Pode.Web templates, you first need to call `Use-PodeWebTemplates`; you can supply a Title, Logo, FavIcon, custom Stylesheet, or change the Theme:

```powershell
Import-Module Pode
Import-Module Pode.Web

Start-PodeServer {
    Use-PodeWebTemplates -Title 'Some Title' -Theme Dark
}
```

The `-Logo`, `-FavIcon`, and `-Stylesheet` must be URL paths relative to your site's `/public` directory.

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

Like how Pode has a function to convert a Module to a REST API; Pode.Web has one that can convert a Module into Web Pages: `ConvertTo-PodeWebPage`!

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

## Components

Components are the base elements that can contain and render other elements:

* Tables + Pagination
* Forms
* Sections
* Charts / CounterCharts
* Modals

## Layouts

Custom layouts contain components:

* Grids
* Tabs

## Elements

These are the building elements that can be used in components:

* Textbox
* File Upload
* Paragraph
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
* Hidden
* Credentials
* Raw
* Button
* Alert
* Icon
* Badge
* Spinner
* Comment Block

## Outputs

Outputs allow you to manipulate the frontend from action ScriptBlocks - such as submitting a form which renders a Toast, and outputs to a Table:

* Tables (out/sync)
* Charts (out)
* Textbox (out)
* Toast (show)
* Validation (out)
* Form (reset)
* Text (out)
* Checkbox (out)
* Modal (show/hide)
* Desktop Notifications (show)

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
    $section = New-PodeWebSection -Name 'Welcome' -NoHeader -Elements @(
        New-PodeWebParagraph -Value 'This is an example homepage, with some example text'
        New-PodeWebParagraph -Value 'Using some example paragraphs'
    )

    Set-PodeWebHomePage -Components $section -Title 'Awesome Homepage'

    # add a page to search process (output as json in an appended textbox)
    $form = New-PodeWebForm -Name 'Search' -ScriptBlock {
        Get-Process -Name $InputData.Name -ErrorAction Ignore | Select-Object Name, ID, WorkingSet, CPU | Out-PodeWebTextbox -Multiline -Preformat -AsJson
    } -Elements @(
        New-PodeWebTextbox -Name 'Name'
    )

    Add-PodeWebPage -Name Processes -Icon Activity -Components $form
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
    $section = New-PodeWebSection -Name 'Welcome' -NoHeader -Elements @(
        New-PodeWebParagraph -Value 'This is an example homepage, with some example text'
        New-PodeWebParagraph -Value 'Using some example paragraphs'
    )
    Set-PodeWebHomePage -Components $section -Title 'Awesome Homepage'

    # add a page to search process (output as json in an appended textbox)
    $form = New-PodeWebForm -Name 'Search' -ScriptBlock {
        Get-Process -Name $InputData.Name -ErrorAction Ignore | Select-Object Name, ID, WorkingSet, CPU | Out-PodeWebTextbox -Multiline -Preformat -AsJson
    } -Elements @(
        New-PodeWebTextbox -Name 'Name'
    )

    Add-PodeWebPage -Name Processes -Icon Activity -Components $form
}
```

Navigate to `http://localhost:8090/`. The login details are `morty` and `pickle`.

## Screenshots

### Login

![Login](/images/login.png)

### Table Filter

![TableFilter](/images/table_filter.png)
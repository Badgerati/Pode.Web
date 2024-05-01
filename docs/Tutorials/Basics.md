# Basics

To use Pode.Web you'll first need to import the module:

```powershell
Import-Module -Name Pode.Web

Start-PodeServer {
    # logic
}
```

## Cache Static Content

To speed up the loading of pages, enable caching within your `server.psd1` file:

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

## Timeout

The default timeout in Pode is 30 seconds, so if you have elements/Routes you know that will run for longer than this then you'll need to increase the default timeout value. This can be done by adding the following to your `server.psd1` file, where the `Timeout` value is in seconds ([more info](https://badgerati.github.io/Pode/Tutorials/RequestLimits/#timeout)):

```powershell
@{
    Server = @{
        Request = @{
            Timeout = 60
        }
    }
}
```

## Use the Templates

Pode.Web contains extension functions that can be used within your [Pode](https://github.com/Badgerati/Pode) server. To initialise Pode.Web and start using its functions you'll first need to call [`Use-PodeWebTemplates`](../../Functions/Utilities/Use-PodeWebTemplates) as one of the first functions within your `Start-PodeServer` scriptblock. This will let you define the title of your website, the default theme, and the logo/favicon.

!!! important
    You **must** call [`Use-PodeWebTemplates`](../../Functions/Utilities/Use-PodeWebTemplates) before you can start using any other function within the Pode.Web module. Ideally, you should make this the first function call within `Start-PodeServer` after you have called `Add-PodeEndpoint`.

```powershell
Import-Module -Name Pode.Web

Start-PodeServer {
    Add-PodeEndpoint -Address localhost -Port 8080 -Protocol Http
    Use-PodeWebTemplates -Title 'Example' -Theme Dark
}
```

If your server uses multiple endpoints, you can set your website to be bound to only one of them via `-EndpointName`:

```powershell
Import-Module -Name Pode.Web

Start-PodeServer {
    Add-PodeEndpoint -Address localhost -Port 8080 -Protocol Http -Name User
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http -Name Admin

    # this will bind the site to the Admin endpoint
    Use-PodeWebTemplates -Title 'Example' -Theme Dark -EndpointName Admin
}
```

### Response Type

By default Pode.Web will use SSE to send data back to any connected clients, this allows feedback from Pode.Web's actions to be done asynchronously - if you have a button click that does some lengthy processing, you can update a client on the current progress.

However, if required, you can switch Pode.Web's response type back to HTTP via the `-ResponseType` parameter on [`Use-PodeWebTemplates`](../../Functions/Utilities/Use-PodeWebTemplates).

```powershell
Import-Module -Name Pode.Web

Start-PodeServer {
    Add-PodeEndpoint -Address localhost -Port 8080 -Protocol Http
    Use-PodeWebTemplates -Title 'Example' -ResponseType Http
}
```

### Root Redirect

You can have [`Use-PodeWebTemplates`](../../Functions/Utilities/Use-PodeWebTemplates) set up a default root (`/`) Route for you, which simply redirects the user to the first created Page of your site, by supplying the `-RootRedirect` switch.

This will let users navigate to `http://localhost:8080/` and be redirected to a page without seeing a 404 error.

## Add some Pages

Once the templates are enabled, you can start to add some pages! You can find more information on the [Pages](../Pages) page, but in general, there are 2 types of pages:

* Login
* Page

To add a new page, you use [`Add-PodeWebPage`](../../Functions/Pages/Add-PodeWebPage), supplying the `-Name` of the page and a `-ScriptBlock` for defining the elements on the page:

```powershell
Add-PodeWebPage -Name 'Services' -Icon 'Settings' -ScriptBlock {
    New-PodeWebCard -Content @(
        New-PodeWebTable -Name 'Services' -ScriptBlock {
            foreach ($svc in (Get-Service)) {
                [ordered]@{
                    Name   = $svc.Name
                    Status = "$($svc.Status)"
                }
            }
        }
    )
}
```

The above would render a new page with a table, showing all the services on the computer.

### Sidebar

Pages added to your site will appear in the sidebar on the left of your pages. The sidebar has a filter box at the top by default, but this can be removed via `-NoPageFilter`:

```powershell
Use-PodeWebTemplates -Title 'Example' -Theme Dark -NoPageFilter
```

You can also force the sidebar to be hidden by default via `-HideSidebar`:

```powershell
Use-PodeWebTemplates -Title 'Example' -Theme Dark -HideSidebar
```

## Custom Scripts/Styles

You can reference custom JavaScript and CSS files to use via [`Import-PodeWebJavaScript`](../../Functions/Utilities/Import-PodeWebJavaScript) and [`Import-PodeWebStylesheet`](../../Functions/Utilities/Import-PodeWebStylesheet). Both take a relative/literal `-Url` to the file.

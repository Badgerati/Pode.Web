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

## Initialise the Templates

Pode.Web contains extension functions that can be used within your [Pode](https://github.com/Badgerati/Pode) server. To initialise Pode.Web, and start using its functions, you'll first need to call [`Initialize-PodeWebTemplates`](../../Functions/Utilities/Initialize-PodeWebTemplates) as one of the first functions within your `Start-PodeServer` scriptblock. This will let you define the title of your website, the default theme, and the logo/favicon.

!!! important
    You **must** call [`Initialize-PodeWebTemplates`](../../Functions/Utilities/Initialize-PodeWebTemplates) before you can start using any other function within the Pode.Web module. Ideally, you should make this the first function call within `Start-PodeServer` after you have called `Add-PodeEndpoint`.

```powershell
Import-Module -Name Pode.Web

Start-PodeServer {
    Add-PodeEndpoint -Address localhost -Port 8080 -Protocol Http
    Initialize-PodeWebTemplates -Title 'Example' -Theme Dark
}
```

If your server uses multiple endpoints, you can set your website to be bound to only one of them via `-EndpointName`:

```powershell
Import-Module -Name Pode.Web

Start-PodeServer {
    Add-PodeEndpoint -Address localhost -Port 8080 -Protocol Http -Name User
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http -Name Admin

    # this will bind the site to the Admin endpoint
    Initialize-PodeWebTemplates -Title 'Example' -Theme Dark -EndpointName Admin
}
```

### Connection Type

#### HTTP

By default Pode.Web will use HTTP connections to send data back to connected clients - this means the standard request/response pattern for HTTP connections will be used. If you have a Form on your page and a user submits it, and then you have multiple Actions - such as table/progress updates - within that Form's scriptblock, then these Actions will all occur after the scriptblock has completed.

For a lot of peoples use-cases this pattern is sufficient: user clicks a button, your server does some work and then responds back with a single action.

#### SSE

If required, Pode.Web does have support for SSE connections - instead of the default of HTTP. This allows feedback from Pode.Web's Actions to be done asynchronously - if a user submits a button for a Form that does some lengthy processing, you can update a client on the current progress; multiple Actions respond in "real-time", not all at the end of processing the scriptblock like standard HTTP connections.

To switch to SSE connections pass the `-ConnectionType` parameter on [`Initialize-PodeWebTemplates`](../../Functions/Utilities/Initialize-PodeWebTemplates):

```powershell
Import-Module -Name Pode.Web

Start-PodeServer {
    Add-PodeEndpoint -Address localhost -Port 8080 -Protocol Http
    Initialize-PodeWebTemplates -Title 'Example' -ConnectionType Sse
}
```

!!! warning
    SSE connections are left open between the client and server, if too many are opened you will start to see CPU/performance issues.

    Additionally, most browsers only allow 6 SSE connections open per window - not tab, per **window**. Pode.Web does close SSE connections on the client-side when you swap between pages and close tabs/windows, but if you have 6 tabs open you might start receiving errors from your browser, or seeing "hanging" issues.

    Furthermore, when SSE connections are closed client-side - which will be common - they will remain "open" on the server for ~60 seconds before auto-cleanup removes stale connections on the server-side.

### Root Redirect

You can have [`Initialize-PodeWebTemplates`](../../Functions/Utilities/Initialize-PodeWebTemplates) set up a default root (`/`) Route for you, which simply redirects the user to the first created Page of your site, by supplying the `-RootRedirect` switch.

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
Initialize-PodeWebTemplates -Title 'Example' -Theme Dark -NoPageFilter
```

You can also force the sidebar to be hidden by default via `-HideSidebar`:

```powershell
Initialize-PodeWebTemplates -Title 'Example' -Theme Dark -HideSidebar
```

## Custom Scripts/Styles

You can reference custom JavaScript and CSS files to use via [`Import-PodeWebJavaScript`](../../Functions/Utilities/Import-PodeWebJavaScript) and [`Import-PodeWebStylesheet`](../../Functions/Utilities/Import-PodeWebStylesheet). Both take a relative/literal `-Url` to the file.

For each, you can also supply additional parameters to help define how the JavaScript or CSS file should be retrieved, such as: async; crossorigin; integrity; etc.

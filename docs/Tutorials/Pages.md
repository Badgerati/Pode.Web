# Pages

There are 3 different kinds of pages in Pode.Web, which are defined below. Besides the Login page, the Home and normal Webpages can be populated with Layouts and Elements. When you add pages to your site, they appear on sidebar for navigation.

## Login

To enable the user of a login page, and lock your site behind authentication is simple! First, just define the authentication method you want via the usual `New-PodeAuthScheme` and `Add-PodeAuth` in Pode. Then, pass the authentication name into [`Set-PodeWebLoginPage`](../../Functions/Pages/Set-PodeWebLoginPage) - and that's it!

```powershell
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

By default the Pode icon is displayed, but you can change this by using the `-Icon` parameter; this takes a literal or relative URL to an image file.

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
    The `-Icon` is the name of a [feather icon](https://feathericons.com), a list of which can be found on their [website](https://feathericons.com)

For example, to add a simple Charts page to your site, to show a Windows counter:

```powershell
Add-PodeWebPage -Name Charts -Icon 'bar-chart-2' -Layouts @(
    New-PodeWebCard -Content @(
        New-PodeWebCounterChart -Counter '\Processor(_Total)\% Processor Time'
    )
)
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

Add dynamic page uses a `-ScriptBlock` instead of `-Layouts`, the scriptblock lets you render different layouts/elements depending on query/payload data in the `$WebEvent`.

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

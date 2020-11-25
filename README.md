# Pode.Web

> This is still a work in progress!

This is a web template framework for use with the [Pode](https://github.com/Badgerati/Pode) PowerShell web server (version 2.0+).

It allows you to build web pages purely with PowerShell - no HTML, CSS, or JavaScript knowledge required!

## Libraries

The Pode.Web templates are built using [Bootstrap](https://getbootstrap.com), [jQuery](https://jquery.com), [Feather icons](https://feathericons.com), and [Chart.js](https://www.chartjs.org).

At present these are loaded using a CDN, though they may get bundled with the module to make it more self-contained.

## Example

> More example can be found in the examples directory

### Basic

This is a simple example with a basic home page, and a page to query processes:

```powershell
Import-Module Pode
Import-Module Pode.Web

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http

    # set the use of templates
    Use-PodeWebTemplates -Title 'Basic Example'

    # set the home page controls (just a simple paragraph)
    $section = New-PodeWebSection -Name 'Welcome' -NoHeader -Controls @(
        New-PodeWebParagraph -Value 'This is an example homepage, with some example text'
        New-PodeWebParagraph -Value 'Using some example paragraphs'
    )
    Set-PodeWebHomePage -Components $section -Title 'Awesome Homepage'

    # add a page to search process (output as json in an appended textbox)
    $form = New-PodeWebForm -Name 'Search' -ScriptBlock {
        Get-Process -Name $InputData.Name -ErrorAction Ignore | Select-Object Name, ID, WorkingSet, CPU | Out-PodeWebTextbox -Multiline -Preformat -AsJson
    } -Controls @(
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
    $section = New-PodeWebSection -Name 'Welcome' -NoHeader -Controls @(
        New-PodeWebParagraph -Value 'This is an example homepage, with some example text'
        New-PodeWebParagraph -Value 'Using some example paragraphs'
    )
    Set-PodeWebHomePage -Components $section -Title 'Awesome Homepage'

    # add a page to search process (output as json in an appended textbox)
    $form = New-PodeWebForm -Name 'Search' -ScriptBlock {
        Get-Process -Name $InputData.Name -ErrorAction Ignore | Select-Object Name, ID, WorkingSet, CPU | Out-PodeWebTextbox -Multiline -Preformat -AsJson
    } -Controls @(
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
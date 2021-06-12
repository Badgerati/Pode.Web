# <img src="https://github.com/Badgerati/Pode/blob/develop/images/icon.png?raw=true" width="25" /> Pode.Web

> This is still a work in progress, until v1.0.0 expect possible breaking changes in some releases.

[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/Badgerati/Pode.Web/master/LICENSE.txt)
[![Documentation](https://img.shields.io/github/v/release/badgerati/pode.web?label=docs)](https://badgerati.github.io/Pode.Web)
[![GitHub Actions](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fbadgerati%2Fpode.web%2Fbadge&style=flat&label=GitHub)](https://actions-badge.atrox.dev/badgerati/pode.web/goto)
[![Gitter](https://badges.gitter.im/Badgerati/Pode.svg)](https://gitter.im/Badgerati/Pode?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![PowerShell](https://img.shields.io/powershellgallery/dt/pode.web.svg?label=PowerShell&colorB=085298)](https://www.powershellgallery.com/packages/Pode.Web)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/Badgerati?color=%23ff69b4&logo=github&style=flat&label=Sponsers)](https://github.com/sponsors/Badgerati)

This is a web template framework for use with the [Pode](https://github.com/Badgerati/Pode) PowerShell web server (v2.2.0+).

It allows you to build web pages purely with PowerShell - no HTML, CSS, or JavaScript knowledge required!

You can build charts, forms, tables, general text, tabs, login pages, etc. There's a light, dark, and terminal themes, and you can supply a custom CSS file.

## 📦 Libraries

The Pode.Web templates are built using [Bootstrap](https://getbootstrap.com), [jQuery](https://jquery.com), [Material Design Icons](https://materialdesignicons.com), [Chart.js](https://www.chartjs.org), and [Highlight.js](https://github.com/highlightjs/highlight.js).

## 📘 Documentation

All documentation and tutorials for Pode.Web can be [found here](https://badgerati.github.io/Pode.Web) - this documentation will be for the latest release.

To see the docs for other releases, branches or tags, you can host the documentation locally. To do so you'll need to have the [`InvokeBuild`](https://github.com/nightroman/Invoke-Build) module installed; then:

```powershell
Invoke-Build Docs
```

Then navigate to `http://127.0.0.1:8000` in your browser.

## 🚀 Features

* Like [Pode](https://github.com/Badgerati/Pode), this is already cross-platform! (with support for PS5)
* Easily add pages, with different layouts and elements
* Support for authentication with a login page!
* Create line, bar, pie, and doughnut charts
* Support for forms, with all kinds of input elements
* Show toast messages on the page, or send desktop notifications
* Display data in tables, with pagination, sorting and filtering
* Use a stepper for a more controlled flow of form input
* Or, use a tabs layout for your pages!
* Show or right code via the Monaco editor (still WIP)
* Render code in code-blocks with code highlighting!
* Support for Light, Dark, Terminal, and custom themes

## 📦 Install

You can install Pode.Web from the PowerShell Gallery:

```powershell
Install-Module -Name Pode.Web
```

## 🙌 Contributing

Pull Requests, Bug Reports and Feature Requests are welcome! Feel free to help out with Issues and Projects!

To build Pode.Web, before running any examples, run the following:

```powershell
Invoke-Build Build
```

To work on issues you can fork Pode.Web, and then open a Pull Request for approval. Pull Requests should be made against the `develop` branch. Each Pull Request should also have an appropriate issue created.

## 🔥 Quick Example

The below will build a web page that shows a chart with the top 10 processes running on your machine, and that auto-refreshes every minute:

```powershell
Import-Module Pode.Web

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http

    # set the use of the pode.web templates
    Use-PodeWebTemplates -Title 'Example' -Theme Dark

    # add the page
    Add-PodeWebPage -Name Processes -Icon Activity -Layouts @(
        New-PodeWebChart -Name 'Top Processes' -Type Bar -AutoRefresh -AsCard -ScriptBlock {
            Get-Process |
                Sort-Object -Property CPU -Descending |
                Select-Object -First 10 |
                ConvertTo-PodeWebChartData -LabelProperty ProcessName -DatasetProperty CPU
        }
    )
}
```

![chart_processes](/images/chart_processes.png)

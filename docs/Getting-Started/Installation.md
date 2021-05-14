# Installation

Pode.Web is a PowerShell module that works along side [Pode](https://github.com/Badgerati/Pode), and it can be installed from the PowerShell Gallery. Once installed, you can use the module in your Pode server.

## Minimum Requirements

Before installing Pode.Web, the minimum requirements must be met:

* Pode v2.2.0+

Which also includes Pode's minimum requirements:
* OS:
    * Windows
    * Linux
    * MacOS
    * Raspberry Pi
* PowerShell:
    * Windows PowerShell 5+
    * PowerShell (Core) 6+
* .NET Framework 4.7.2+ (For Windows PowerShell)

## PowerShell Gallery

[![PowerShell](https://img.shields.io/powershellgallery/dt/pode.web.svg?label=Downloads&colorB=085298)](https://www.powershellgallery.com/packages/Pode.Web)

To install Pode.Web from the PowerShell Gallery, you can use the following:

```powershell
Install-Module -Name Pode.Web
```

## Using the Module

Once installed, you then need to import the module at the top of your Pode server's script; unlike Pode, the module's functions are not automatically exported:

```powershell
Import-Module -Name Pode.Web

Start-PodeServer {
    Use-PodeWebTemplates -Title '<Title>'
}
```

Then, you can jump over to the [Basics](../Tutorials/Basics)!

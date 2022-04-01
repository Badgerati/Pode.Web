# Installation

Pode.Web is a PowerShell module that works along side [Pode](https://github.com/Badgerati/Pode), and it can be installed from the PowerShell Gallery, or Docker. Once installed, you can use the module in your Pode server.

## Minimum Requirements

Before installing Pode.Web, the minimum requirements must be met:

* [Pode](https://github.com/Badgerati/Pode) v2.6.0+

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

## Docker

[![Docker](https://img.shields.io/docker/stars/badgerati/pode.web.svg?label=Stars)](https://hub.docker.com/r/badgerati/pode.web/)
[![Docker](https://img.shields.io/docker/pulls/badgerati/pode.web.svg?label=Pulls)](https://hub.docker.com/r/badgerati/pode.web/)

Like Pode, Pode.Web also has Docker images available. The images use Pode v2.6.2 on either an Ubuntu Focal image (default), an Alpine image, or an ARM32 image (for Raspberry Pis).

* To pull down the latest Pode.Web image you can do:

```powershell
# for latest
docker pull badgerati/pode.web:latest

# or the following for a specific version:
docker pull badgerati/pode.web:0.8.0
```

* To pull down the Alpine Pode.Web image you can do:

```powershell
# for latest
docker pull badgerati/pode.web:latest-alpine

# or the following for a specific version:
docker pull badgerati/pode.web:0.8.0-alpine
```

* To pull down the ARM32 Pode.Web image you can do:

```powershell
# for latest
docker pull badgerati/pode.web:latest-arm32

# or the following for a specific version:
docker pull badgerati/pode.web:0.8.0-arm32
```

Once pulled, you can [view here](../../Hosting/Docker) on how to use the image.

## GitHub Package Registry

You can also get the Pode.Web docker image from the GitHub Package Registry! The images are the same as the ones hosted in Docker.

* To pull down the latest Pode.Web image you can do:

```powershell
# for latest
docker pull docker.pkg.github.com/badgerati/pode.web/pode.web:latest

# or the following for a specific version:
docker pull docker.pkg.github.com/badgerati/pode.web/pode.web:0.8.0
```

* To pull down the Alpine Pode image you can do:

```powershell
# for latest
docker pull docker.pkg.github.com/badgerati/pode.web/pode.web:latest-apline

# or the following for a specific version:
docker pull docker.pkg.github.com/badgerati/pode.web/pode.web:0.8.0-alpine
```

* To pull down the ARM32 Pode.Web image you can do:

```powershell
# for latest
docker pull docker.pkg.github.com/badgerati/pode.web/pode.web:latest-arm32

# or the following for a specific version:
docker pull docker.pkg.github.com/badgerati/pode.web/pode.web:0.8.0-arm32
```

Once pulled, you can [view here](../../Hosting/Docker) on how to use the image.

## Using the Module

Once installed, you then need to import the module at the top of your Pode server's script; unlike Pode, the module's functions are not automatically exported:

```powershell
Import-Module -Name Pode.Web

Start-PodeServer {
    Use-PodeWebTemplates -Title '<Title>'
}
```

Then, you can jump over to the [Basics](../../Tutorials/Basics)!

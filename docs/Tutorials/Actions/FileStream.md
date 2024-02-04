# FileStream

This page details the actions available to FileStream elements.

## Clear

To clear the content of a FileStream, you can use [`Clear-PodeWebFileStream`](../../../Functions/Actions/Clear-PodeWebFileStream):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Clear' -ScriptBlock {
        Clear-PodeWebFileStream -Name 'Example'
    }

    New-PodeWebFileStream -Name 'Example' -Url '/logs/error.log'
)
```

## Start

To start a FileStream that's paused, you can use [`Start-PodeWebFileSteam`](../../../Functions//Start-PodeWebFileSteam):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Start' -ScriptBlock {
        Start-PodeWebFileStream -Name 'Example'
    }

    New-PodeWebFileStream -Name 'Example' -Url '/logs/error.log'
)
```

## Stop

To stop/pause a FileStream that's running, you can use [`Stop-PodeWebFileSteam`](../../../Functions//Stop-PodeWebFileSteam):

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Stop' -ScriptBlock {
        Stop-PodeWebFileStream -Name 'Example'
    }

    New-PodeWebFileStream -Name 'Example' -Url '/logs/error.log'
)
```

## Restart

To restart a FileStream, you can use [`Restart-PodeWebFileSteam`](../../../Functions//Restart-PodeWebFileSteam) and this will stop, clear, and the start the FileStream element:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Restart' -ScriptBlock {
        Restart-PodeWebFileStream -Name 'Example'
    }

    New-PodeWebFileStream -Name 'Example' -Url '/logs/error.log'
)
```

## Update

To update the Url that a FileStream is currently streaming data from, you can use [`Update-PodeWebFileStream`](../../../Functions/Actions/Update-PodeWebFileStream). This will stop, clear, update the Url, and the start the FileStream element:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Update 1' -ScriptBlock {
        Update-PodeWebFileStream -Name 'Example' -Url '/logs/error.log'
    }
    New-PodeWebButton -Name 'Update 2' -ScriptBlock {
        Update-PodeWebFileStream -Name 'Example' -Url '/logs/error2.log'
    }

    New-PodeWebFileStream -Name 'Example' -Url '/logs/error.log'
)
```

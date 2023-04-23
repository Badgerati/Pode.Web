# Video

This page details the actions available to Video.

## Start

To play video that's currently stopped/paused, you can use [`Start-PodeWebVideo`](../../../Functions/Actions/Start-PodeWebVideo):

```powershell
New-PodeWebCard -Content @(
    New-PodeWebVideo -Name 'example' -Thumbnail 'https://samplelib.com/lib/preview/mp4/sample-5s.jpg' -Source @(
        New-PodeWebVideoSource -Url 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4'
    )
)

New-PodeWebContainer -Content @(
    New-PodeWebButton -Name 'Play' -ScriptBlock {
        Start-PodeWebVideo -Name 'example'
    }
)
```

## Stop

To pause video that's currently playing, you can use [`Stop-PodeWebVideo`](../../../Functions/Actions/Stop-PodeWebVideo):

```powershell
New-PodeWebCard -Content @(
    New-PodeWebVideo -Name 'example' -Thumbnail 'https://samplelib.com/lib/preview/mp4/sample-5s.jpg' -Source @(
        New-PodeWebVideoSource -Url 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4'
    )
)

New-PodeWebContainer -Content @(
    New-PodeWebButton -Name 'Stop' -ScriptBlock {
        Stop-PodeWebVideo -Name 'example'
    }
)
```

## Reset

To reload an video element, and also reset the video back to the start, you can use [`Reset-PodeWebVideo`](../../../Functions/Actions/Reset-PodeWebVideo):

```powershell
New-PodeWebCard -Content @(
    New-PodeWebVideo -Name 'example' -Thumbnail 'https://samplelib.com/lib/preview/mp4/sample-5s.jpg' -Source @(
        New-PodeWebVideoSource -Url 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4'
    )
)

New-PodeWebContainer -Content @(
    New-PodeWebButton -Name 'Reset' -ScriptBlock {
        Reset-PodeWebVideo -Name 'example'
    }
)
```

## Update

To update the sources/tracks of an video element, you can use [`Update-PodeWebVideo`](../../../Functions/Actions/Update-PodeWebVideo). This will clear all current sources/tracks, add the new ones, and then reload the element:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebVideo -Name 'example' -Thumbnail 'https://samplelib.com/lib/preview/mp4/sample-5s.jpg' -Source @(
        New-PodeWebVideoSource -Url 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4'
    )
)

New-PodeWebContainer -Content @(
    Update-PodeWebVideo -Name 'sample' -Thumbnail 'https://samplelib.com/lib/preview/mp4/sample-10s.jpg' -Source @(
        New-PodeWebVideoSource -Url 'https://samplelib.com/lib/preview/mp4/sample-10s.mp4'
    )
)
```

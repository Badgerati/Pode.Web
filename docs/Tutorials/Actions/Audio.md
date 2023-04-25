# Audio

This page details the actions available to Audio.

## Start

To play audio that's currently stopped/paused, you can use [`Start-PodeWebAudio`](../../../Functions/Actions/Start-PodeWebAudio):

```powershell
New-PodeWebCard -Content @(
    New-PodeWebAudio -Name 'example' -Source @(
        New-PodeWebAudioSource -Url 'https://samplelib.com/lib/preview/mp3/sample-6s.mp3'
    )
)

New-PodeWebContainer -Content @(
    New-PodeWebButton -Name 'Play' -ScriptBlock {
        Start-PodeWebAudio -Name 'example'
    }
)
```

## Stop

To pause audio that's currently playing, you can use [`Stop-PodeWebAudio`](../../../Functions/Actions/Stop-PodeWebAudio):

```powershell
New-PodeWebCard -Content @(
    New-PodeWebAudio -Name 'example' -Source @(
        New-PodeWebAudioSource -Url 'https://samplelib.com/lib/preview/mp3/sample-6s.mp3'
    )
)

New-PodeWebContainer -Content @(
    New-PodeWebButton -Name 'Stop' -ScriptBlock {
        Stop-PodeWebAudio -Name 'example'
    }
)
```

## Reset

To reload an audio element, and also reset the audio back to the start, you can use [`Reset-PodeWebAudio`](../../../Functions/Actions/Reset-PodeWebAudio):

```powershell
New-PodeWebCard -Content @(
    New-PodeWebAudio -Name 'example' -Source @(
        New-PodeWebAudioSource -Url 'https://samplelib.com/lib/preview/mp3/sample-6s.mp3'
    )
)

New-PodeWebContainer -Content @(
    New-PodeWebButton -Name 'Reset' -ScriptBlock {
        Reset-PodeWebAudio -Name 'example'
    }
)
```

## Update

To update the sources/tracks of an audio element, you can use [`Update-PodeWebAudio`](../../../Functions/Actions/Update-PodeWebAudio). This will clear all current sources/tracks, add the new ones, and then reload the element:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebAudio -Name 'example' -Source @(
        New-PodeWebAudioSource -Url 'https://samplelib.com/lib/preview/mp3/sample-6s.mp3'
    )
)

New-PodeWebContainer -Content @(
    Update-PodeWebAudio -Name 'example' -Source @(
        New-PodeWebAudioSource -Url 'https://samplelib.com/lib/preview/mp3/sample-9s.mp3'
    )
)
```

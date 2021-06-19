# TextStream

A text stream element is a readonly textarea that will stream the contents of a file from the server - usually a text/log file from the `/public` directory. To add a text streaming element to your page you can use [`New-PodeWebTextStream`](../../../Functions/Elements/New-PodeWebTextStream).

The simplest text stream just needs a `-FileUrl` being supplied; this URL should be a relative/literal URL path to a static text file.

!!! important
    The server the file is being streamed from must support the Range HTPP header - Pode already supports this.

For example, the following will stream a log file from the `/public/logs/error.log` file:

```powershell
New-PodeWebContainer -Content @(
    New-PodeWebTextStream -FileUrl '/logs/error.log'
)
```

Which looks like below:
![textstream_simple](../../../images/textstream_simple.png)

You can control the height and refresh interval of the element via the `-Height` and `-Interval` parameters. The interval is specified as a number of seconds - the default is 10secs.

Each text stream element renders with a header which shows the file being streamed; you can hide the header using the `-NoHeader` switch.

## Connection

If the connection (or any error) occurs while streaming the file, then the header (or just the border if the header is hidden) will turn read and the streaming will stop.

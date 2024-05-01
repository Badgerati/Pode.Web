# Updating Async

In Pode.Web you can update users asynchronously, whether it be updating the rows of a Table from a long-running Task to retrieve data, or sending a Toast to all connected users from a Timer, it can be done asynchronously by sending events back to the user(s).

!!! important
    This feature is dependent on using SSE, if you have `-ResponseType Http` configured on your `Use-PodeWebTemplates` call, then asynchronous updates won't work.

## Connections

When a user opens a Page of your site, Pode.Web automatically assigns that user a connection with a `ClientId` and places them into a `Group` which is just the PageId - allowing you to send events back to either 1 user, a group of users, or all users.

## Automatic Updates

By default, all action calls will be sent back to the relevant user asynchronously if they are called from within the scope of an Element's `-ScriptBlock`. For example, the following page will update a Progress Bar for a long-running Form to show the progress being made back to the user:

```powershell
Add-PodeWebPage -Name 'Example' -ScriptBlock {
    New-PodeWebContainer -Content @(
        New-PodeWebForm -Name 'Long Running Form' -ScriptBlock {
            Update-PodeWebProgress -Name 'FormProgress' -Value 0 -Colour Blue
            Show-PodeWebElement -Name 'FormProgress' -ObjectType 'Progress'

            1..10 | ForEach-Object {
                Start-Sleep -Seconds 1
                Update-PodeWebProgress -Name 'FormProgress' -Value ($_ * 10)
            }

            Update-PodeWebProgress -Name 'FormProgress' -Value 100 -Colour Green
        } -Content @(
            New-PodeWebTextbox -Name 'Text' -Type Text
        )

        New-PodeWebProgress -Name 'FormProgress' -HideName -Striped -Animated |
            Hide-PodeWebElement
    )
}
```

## Manual Updates

The example Form shown above handles the event routing back to the relevant user for you automatically however, this has to be handled manually when using Tasks, Timers, or Schedules as they have no awareness of the `$WebEvent` scope.

To do this, Pode.Web provides the following async helper functions which will aid you in creating an "AsyncEvent" scope for utilities like Tasks, Timers, and Schedules:

* [`Set-PodeWebAsyncEvent`](../../Functions/Async/Set-PodeWebAsyncEvent)
* [`Get-PodeWebAsyncEvent`](../../Functions/Async/Get-PodeWebAsyncEvent)
* [`New-PodeWebAsyncEvent`](../../Functions/Async/New-PodeWebAsyncEvent)
* [`Export-PodeWebAsyncEvent`](../../Functions/Async/Export-PodeWebAsyncEvent)
* [`Set-PodeWebAsyncHeader`](../../Functions/Async/Set-PodeWebAsyncHeader)

!!! note
    The logic being described below for Tasks, Timers, and Schedules is not specific to each - for example, you could use the Schedules logic to broadcast a global Toast to all users in a Task. The examples below will just likely be the more common scenarios for each.

### Tasks

Let's say we have a Table with some data that we want to show to a user however, the data for the rows to display takes quite some time to retrieve. Instead of retrieving the data within the Table's `-ScriptBlock` and facing HTTP timeouts, you could offload that retrieval to a Task and have that update the Table for you.

To set this up you'll first need a table via [`New-PodeWebTable`](../../Functions/Elements/New-PodeWebTable), and then you'll also need to make a call to [`Set-PodeWebAsyncHeader`](../../Functions/Async/Set-PodeWebAsyncHeader) - this informs the frontend that the request to populate the Table is going to be done asynchronously, in a function outside the scope of the current HTTP request:

```powershell
New-PodeWebTable -Name 'Processes' -Paginate -ScriptBlock {
    Set-PodeWebAsyncHeader
}
```

Next, you'll need to invoke the Task which will retrieve the data - we'll set the Task up next! Besides the pagination details, you'll also need to pass a new AsyncEvent object. While in the scope of a `$WebEvent` (ie: the Table's scriptblock) you can fetch this object via [`Export-PodeWebAsyncEvent`](../../Functions/Async/Export-PodeWebAsyncEvent) - this will retrieve the required async properties and build an AsyncEvent object for you:

```powershell
New-PodeWebTable -Name 'Processes' -Paginate -ScriptBlock {
    Set-PodeWebAsyncHeader
    $null = Invoke-PodeTask -Name 'GetProcesses' -ArgumentList @{
        AsyncEvent = Export-PodeWebAsyncEvent
        PageIndex  = $WebEvent.Data.PageIndex
        PageSize   = $WebEvent.Data.PageSize
    }
}
```

The Task in question will then be setup to expect the AsyncEvent argument, plus the 2 pagination arguments. The first thing you'll need to do is call [`Set-PodeWebAsyncEvent`](../../Functions/Async/Set-PodeWebAsyncEvent) and pass it the AsyncEvent object - this will set up an async scope for Pode.Web's events to use later on:

```powershell
Add-PodeTask -Name 'GetProcesses' -ScriptBlock {
    param([hashtable]$AsyncEvent, [int]$PageIndex, [int]$PageSize)
    $AsyncEvent | Set-PodeWebAsyncEvent
}
```

With all of that done, you can then retrieve the data as usual and pipe that in [`Update-PodeWebTable`](../../Functions/Actions/Update-PodeWebTable):

```powershell
Add-PodeTask -Name 'GetProcesses' -ScriptBlock {
    param([hashtable]$AsyncEvent, [int]$PageIndex, [int]$PageSize)
    $AsyncEvent | Set-PodeWebAsyncEvent
    Start-Sleep -Seconds 2

    $processes = Get-Process | Select-Object -Property Name, ID, WorkingSet, CPU
    $totalCount = $processes.Length
    $processes = $processes[(($PageIndex - 1) * $PageSize) .. (($PageIndex * $PageSize) - 1)]
    $processes | Update-PodeWebTable -Name 'Processes' -PageIndex $PageIndex -TotalItemCount $totalCount
}
```

!!! tip
    You can use a Task to call other actions as well and update other elements - not just Tables! ??

### Timers / Schedules

You can use Timers and/or Schedules to send events back to connected clients, whether it be to update a Chart for all users viewing a specific page, or to send a Toast to all connected users.

The following sections describe how to do each:

#### All Users

Let's say we want to broadcast a Toast to every user, every hour, via a Schedule. This can be achieved by manually creating an AsyncEvent via [`New-PodeWebAsyncEvent`](../../Functions/Async/New-PodeWebAsyncEvent), passing the `-All` switch, and then piping that into [`Set-PodeWebAsyncEvent`](../../Functions/Async/Set-PodeWebAsyncEvent):

```powershell
Add-PodeSchedule -Name 'All' -Cron (New-PodeCron -Every Hour) -ScriptBlock {
    New-PodeWebAsyncEvent -All | Set-PodeWebAsyncEvent
    Show-PodeWebToast -Message 'Hi, everyone!'
}
```

#### Users on a Page

Let's say we have a Chart on a page, and we want to update that Chart for all users on that page with a new item every 10 seconds, via a Timer. This can be achieved by manually creating an AsyncEvent via [`New-PodeWebAsyncEvent`](../../Functions/Async/New-PodeWebAsyncEvent), passing the `-Group` parameter as the `-Id` of the page, and then piping that into [`Set-PodeWebAsyncEvent`](../../Functions/Async/Set-PodeWebAsyncEvent):

```powershell
# add a page with a chart
Add-PodeWebPage -Name 'Example' -Id 'page_example' -ScriptBlock {
    New-PodeWebCard -Name 'Chart' -NoTitle -Content @(
        New-PodeWebChart -Name 'Numbers' -Type Line -ScriptBlock {} -Append -TimeLabels -MaxItems 15
    )
}

# timer to update chart page every 10s for all users viewing that page
Add-PodeTimer -Name 'Chart Update' -Interval 10 -ScriptBlock {
    New-PodeWebAsyncEvent -Group 'page_example' | Set-PodeWebAsyncEvent

    $item = @{
        Key    = 1
        Values = @(@{
                Key   = 'Number'
                Value = (Get-Random -Maximum 10)
            })
    }

    $item | Update-PodeWebChart -Name 'Numbers'
}
```

#### Specific User

To send an event back to a specific user you'll need to know their ClientId, this will be retrievable from most Element scriptblocks in `$WebEvent.Sse.ClientId`, and will need to be stored/mapped to a user in a datastore - or passed directly to the Timer/Schedule via an argument.

Assuming you're using a data store and a fake `Get-UserClientId` function, you could send a Toast to a specific user as follows, by manually creating an AsyncEvent via [`New-PodeWebAsyncEvent`](../../Functions/Async/New-PodeWebAsyncEvent), passing the `-ClientId` parameter, and then piping that into [`Set-PodeWebAsyncEvent`](../../Functions/Async/Set-PodeWebAsyncEvent):

```powershell
Add-PodeSchedule -Name 'All' -Cron (New-PodeCron -Every Hour) -ScriptBlock {
    $clientId = Get-UserClientId -Email 'joe.bloggs@example.com'
    New-PodeWebAsyncEvent -ClientId $clientId | Set-PodeWebAsyncEvent
    Show-PodeWebToast -Message 'Hi, Joe!'
}
```

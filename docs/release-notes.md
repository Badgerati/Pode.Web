# Release Notes

## v0.5.1

```plain
### Enhancements
* #126: Adds `New-PodeWebMinMax` form element
* #126: Adds `Get-PodeWebUsername` to get the username of the authenticated user (same name in the navbar)

### Bugs
* #126: Fix a bug when selecting a tile for updating

### Packaging
* #118: Bump chart.js to 3.4.1
* #119: Bump highlightjs to 11.1.0
* #123: Bump monaco-editor to 0.26.1
```

## v0.5.0

```plain
### Features
* #46: New FileStream element, which allows the streaming of files from the server
* #93: New Layout type: Tile
* #99: Adds a new Accordion layout
* #100: Adds new FileStream element for file streaming
* #106: Add new element for iFrames

### Enhancements
* #48: Add new `Use-PodeWebPages` to auto-import pages from a Pages folder
* #54: Adds support for server-side Filtering, Paging, and Sorting on Tables
* #71: Adds `-NewTab` to Pages, Links, and Buttons, and adds new `Add-PodeWebPageLink`
* #73: Move from Feather Icons to Material Design Icons
* #74: Add `-NoPageFilter` switch to hide sidebar page filter
* #75: Add support for different sized Grid Cells (thanks @the-mentor!)
* #76: Add `-NoHide` switch on Card (thanks @ili101!)
* #79: New `Get-PodeWebPage`/`Test-PodeWebPage` functions
* #80: Icon on login page should be clickable, back to home page
* #81: Add group to Page URL, so you can have the same named page in two different groups
* #88: Add Spin, Flip, and Rotate parameters for Icons
* #92: Get `-NoAuth` from PageData for Elements created in a Page's ScriptBlock
* #101: Add Sync-PodeWebChart as an output action for reloading Charts
* #102: Add parameters for min/max values of x/y axes on Charts
* #105: Elements with `-AutoRefresh` switch now have a `-RefreshIntervals` parameter
* Allow for icons to be in Tabs
* Allow for a `-BackgroundImage` on `Set-PodeWebLoginPage`
* Add `-AppendIcon`, `-AppendText`, and `-Width` on `New-PodeWebTextbox`
* Add `-Width` to `New-PodeWebGrid` to automatically put X cells on a row
* Add `-HelpScriptBlock` to `Add-PodeWebPage` to show a help icon for a page
* `New-PodeWebList` can now take an array of `New-PodeWebListItem` for dynamic lists

### Bugs
* #47: Fix deprecated jQuery functions
* #60: You no longer need to supply both `-Click` and `-ClickScriptblock` on a Table
* #87: Fix the heart emoji to be an icon in "Powered By"

### Documentation
* #61: The Basics link on Getting-Started is broken
* Update the docs to mention that the Login page needs sessions

### Packaging
* Bump monaco-editor from 0.23.0 to 0.25.2
* Bump @highlightjs/cdn-assets from 10.7.1 to 11.0.1
* Bump chart.js from 2.9.4 to 3.4.0
```

## v0.4.1

```plain
### Documentation
* #3: There's now documentation!!

### Other Changes
* `Out-PodeWebTable` has been split into `Out-PodeWebTable` and `Update-PodeWebTable`
* `Update-PodeWebTableRow` `-TableId` has been split into `-Id` and `-Name`
* `Out-PodeWebChart` has been split into `Out-PodeWebChart` and `Update-PodeWebChart`
* `ConvertTo-PodeWebChartDataset` has been renamed to `ConvertTo-PodeWebChartData`
* `Out-PodeWebTextbox` has been split into `Out-PodeWebTextbox` and `Update-PodeWebTextbox`
* `Out-PodeWebText` has been renamed to `Update-PodeWebText`
* `Out-PodeWebBadge` has been renamed to `Update-PodeWebBadge`
* `Out-PodeWebCheckbox` has been renamed to `Update-PodeWebCheckbox`
* `Show-PodeWebError` has been renamed to `Out-PodeWebError`
```

## v0.4.0

```plain
### Enhancements
* #28: Add `-ClickScriptblock` to `New-PodeWebTable` to allow dynamic actions on row clicks
* #29: Bundle the libraries with Pode.Web, instead of using a CDN
* #36: Add support for adding navigation links and dropdowns to the NavBar
* #39: Add support for breadcrumbs at the top of pages (tables auto-generate these)
* #39: Add support for `-Icon` on modal headers
* #39: Add support for `-Icon` on table columns, as well as `-Alignment` and `-Name` (for a different display name)
* #39: Allow for a `-Title` tooltip on spinners and icons
* #39: Allow `Show/Hide-PodeWebModal` and `-Sync-PodeWebTable` to select select via `-Name`

### Bugs
* #27: Fix for table and chart outputs being auto-wrapped
* #28: Fix duplicate querystring values from table clicks
* #30: Fix issue with empty file attachments
```

## v0.3.0

```plain
Important: This release contains vast breaking changes to v0.2.0 - Layouts and Elements have been reworked.

* #8: Massive refactor of Layouts and Elements
* #9: Adds `datetime-local` option for `New-PodeWebTextbox`, and a new `New-PodeWebDatetime`
* #10: Fixes for downloading files via AJAX
* #12: Fixes for button executing multiple times
* #13: Better theme support, and a new Auto theme dependant on user's system theme
* #15: Fixes for file uploads not being submitted
* #16: Add support for updating a single row in a table
* #17: Add support for custom themes
* #18: Add support for `-EndpointName`
* #19: Add support for initial value on CodeEditor, and support to upload value to server
* #24: Fix issue with HTML encoding on `Out-PodeWebText`
```

## v0.2.1

```plain
### Changes
* #6 - Fix parameter set not resolved
* Fix charts not refreshing properly
```

## v0.2.0

```plain
### Breaking Changes
* `$InputData` has been removed, just use Pode's `$WebEvent.Data`
* `-DarkMode` is now `-Theme`
* Hashtable for raw chart data has changed, the `Value` is now `Values`. This can be left as a single value for ease.

### Changes
* Table pagination
* Desktop notifications
* Collapsible sidebar/sections
* Multiple datasets on charts
* Spinner, Comment Box, and Line elements
* Monaco editor
* Hero and Timer components 
```

## v0.1.0

```plain
* Initial release
```

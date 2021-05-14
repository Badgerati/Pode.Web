# Release Notes

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

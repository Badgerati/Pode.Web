# Release Notes

## v0.8.0

```plain
### Features
* #276: Enable security headers by default

### Enhancements
* #91: While Charts and Tables are loading, a growing spinner is displayed
* #129: Adds a new `Set-PodeWebAuth` for auths that don't need a login page, like IIS
* #270: Allow Buttons to be shown as an outline, rather than a solid colour
* #272: Add output actions for Buttons: Disable, Enable, Update, Invoke
* #273: Add a Submit output action for Forms
* #275: Allow for Table Columns to be hidden
* #284: Allow for a Grid Cell `-Width` to allow be supplied as a percentage
* #290: Show a default "avatar" icon for logged in users
* #295: Clean up table pagination controls, and add items per page support
* #297: Add support for custom Layouts/Elements on the login page

### Bugs
* #273: Allow the Submit/Reset text of Form buttons to be customised
* #291: Fix for ANSI colour characters appearing in textboxes on PS7.2+
* #291: Fix a rare issue for an empty home page to redirect to a login page and 404

### Packaging
* #281: Bump monaco-editor to 0.33.0
* #282: Bump highlightjs to 11.5.0
* #286: Package Pode.Web as a Docker image
* #296: Bump mdi/fonts to 6.6.96
```

## v0.7.1

```plain
### Bugs
* #254: Fix the colour of IconOnly buttons in the Light theme
* #267: Fix icon positioning when used in table headers
* #268: Fix the hover value of buttons to be the DisplayName

### Packaging
* #257: Bump highlightjs to 11.4.0
* #262: Bump monaco-editor to 0.32.1
* #204: Bump jquery-ui to 1.13.1
* #198: Bump chart.js to 3.7.1
```

## v0.7.0

```plain
### Features
* #212: Add Video element support via `New-PodeWebVideo`
* #213: Add Audio element support via `New-PodeWebAudio`
* #234: Add events support for pages

### Enhancements
* #161: Add `-DisplayName` and `-DisplayOptions` parameters to various elements
* #202: Add support for IIS Website Applications
* #207: Add `-Hide` switch for pages so they don't appear in the sidebar
* #208: Add `-Required` switch on form input elements
* #210: Add `Update-PodeWebCodeEditor` and `Clear-PodeWebCodeEditor` output actions
* #211: Add `-ShowReset` switch on forms, to display an optional Reset button
* #214: Add support for customising a form's method/action properties
* #222: Add ruby pronuncation support to `New-PodeWebText`
* #226: Textboxes, Charts, Images, and Table Columns now allow raw CSS values for Widths
* #230: Add `-Type` parameter for DateTime, Credentials and MinMax elements
* #235: Add `-Accept` parameter on FileUpload
* #242: Add `-Compact` switch on Tables, and `-Default` parameters on Table Columns
* #245: Add Enable/Disable output actions for checkboxes, and support on Update
* #246: Add `Update-PodeWebIFrame` output action
* #247: Add `-NoSidebar` switch for pages, so they don't display the sidebar

### Bugs
* #199: Fix alphabetical page sorting in the sidebar
* #209: Add spinner to the Sign In button
* #215: Fix styling glitch when 2 Steps layouts displayed one after another
* #233: Fix issue causing `Update-PodeWebText` to not work with code/blocks
* #238: Add `-Force` switch on `Update-PodeWebTable` to update pagiable tables externally
* #242: Fix `Initialize-PodeWebTable` not being respected on update calls
* #242: Fix "0" values never being displayed

### Packaging
* #241: Bump chart.js to 3.6.2
```

## v0.6.2

```plain
### Packaging
* #195: Bump highlightjs to 11.3.1
* #198: Bump chart.js to 3.6.0
* #203: Bump monaco-editor to 0.30.1
* #204: Bump materialdesignicons to 6.5.95
* #205: Bump bootstrap to 4.6.1
```

## v0.6.1

```plain
### Packaging
* #123: Bump monaco-editor to 0.29.1
* #178: Bump materialdesignicons to 6.2.95
```

## v0.6.0

```plain
### Features
* #156: Add support for most of the common JavaScript events on most elements

### Enhancements
* #89: Add `-CssStyle` parameters to Elements/Layouts
* #115: Add output actions to allows switching of themes on the fly
* #122: Add `-Mode` parameter on `New-PodeWebAccordion`, to start Collapsed/Expanded
* #125: Add `-HideSidebar` switch to `Use-PodeWebTemplates`
* #140: Add Clear output actions for Charts, Tables, and Textboxes
* #147: Add support for Select elements to be more dynamic
* #149: Allow for the Size of a multi-select element to be alterted
* #151: Enable `Update-PodeWebTableRow` to be able to alter a row's background/text colour
* #153: Add more colours for charts, and let them be customised
* #154: Display pages in groups in alphabetical order
* #155: Remove the "choose an option" option from Select (if needed, add via `-Options`)
* #162: Add new `-NoForm` switch on most form elements, so they can be used outside a Form
* #164: Output actions for Hide/Show components, and Update/Remove component styles
* #165: Add new `-Alignment` parameter for Cells
* #176: Update charts rather than full rebuild
* #177: Add better support for initialising empty tables
* #179: Add FileStream output actions

### Bugs
* #128: Fix bug with `ConvertTo-PodeWebPage` on modules using cmdlets
* #130: Fix FileUpload elements within a Step layout
* #137: Add missing `-ArgumentList` to `Add-PodeWebPage`
* #144: Fix bug when two pages with the same name could be set as Active
* #167: The `-Name` parameter for a Timer doesn't need to be mandatory
* #168: Make the home page redirect to the first page with no access restrictions

### Packaging
* #118: Bump chart.js to 3.5.1
* #119: Bump highlightjs to 11.2.0
* #123: Bump monaco-editor to 0.27.0
* #178: Bump materialdesignicons to 6.1.95
```

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

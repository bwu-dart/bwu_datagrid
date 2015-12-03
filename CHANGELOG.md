## 0.0.24
- Fix #125 (missing `.toList()`

## 0.0.23
- Fix #121 (Unhandled exception: type 'int' is not a subtype of type 'double'.)
  in newer Dartium versions (1.13.0-devx)
  
## 0.0.22
- fix for breaking change in Dart 1.10.0 in `classes.add`

## 0.0.21
- widen dependency constraint on quiver

## 0.0.20
- use dartformat
- extend dependency constraint to allow Polymer 0.16.0

## 0.0.19 (not published)
- exclude `example/asset/example.css` and
`lib/asset/smoothness/jquery-ui-1.8.16.custom.css` from being inlined by the
Polymer transformer.
- Move sparkline to dev_dependency
- Remove script tags for `platform.js` and `dart_support.js` from entry pages
because `pub build`/`pub serve` adds them automatically (`platform.js` was also
renamed to `web_components.js` anyway).

## 0.0.18
- Widen dependency constraints on Polymer
- !! Polymer 0.15.0 or some Dart update broke drag-n-drop for range selection and
 row reordering. Drag-n-drop for column reordering still works (doesn't use HTML5
 drag-n-drop) I'll have yet to investigate to find the cause.
## 0.0.17
- Update to Polymer 0.14.0
- Change DataView row id from String to dynamic

## 0.0.16
- Add BwuAttached event to simplify remove an re-attach. See also #97

## 0.0.15
- Possible fix of #97

## 0.0.14
- Upgrade to Polymer 0.13.0

## 0.0.13
- Remove the blue background added for debugging purposes only.

## 0.0.12
- Looks much better in Firefox (haven't changed anything -
maybe the new Firefox (31) has better custom element/shadow DOM support
or the Polymer polyfills work better on Firefox now (or both)
There are still a few issues with Firefox though.
- Updated to Polymer 0.12.1
- Add example 11 auto-height
- Add example 12 fill-browser
- Add example 13 getItem-sorting
- Add example header-row
- Add example checkbox row select
- Add example spreadsheet
- Add example grouping

## 0.0.11
- Add example 10 async post render
- Uses BWU Sparkline for inline charts
- Uses Polymer 0.11.0-dev.6

## 0.0.10
- Nothing (inadvertently skipped)

## 0.0.9
- Add example 09 row reordering
- Add drag and drop
- Add cell selection/range selection
- Add example 08 alternative display

## 0.0.8
- #51 add tree functionality (expand/collapse) to the grid

## 0.0.7
- Fix #48 click header to sort the column leads to drag

## 0.0.6
- Add example 04_model
- Add columnpicker
- Add reorder columns
- Add filter
- Add sort by click on the column header
- Add paging
- Add top-panel
- Add force fit columns
- Add synchronous resize

## 0.0.5
* add example composite_editor_item_details added
* add example totals_via_data_provider added
* upgrade to Polymer 0.10.0-pre.13

## 0.0.4

* add example 03a_compound_editors added
* add example 03b_editing_with_undo added
* add example 07_events
* add example 14_highlighting

## 0.0.3
* add basic editing support
* add example 03_editing
* fix examples to run when built to JavaScript and are available on GitHub Pages

## 0.0.2

* fix formatters
* add example 02_formatters

## 0.0.1

* can display data
* can scroll
* can resize columns
* add plugin bwu_auto_tooltips
* add example-autotooltips

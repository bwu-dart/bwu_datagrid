# Theming

## Provided styles

### Basic styles
- `lib/datagrid/bwu_datagrid_style.html` contains the basic styles for BWU Datagrid and is loaded by default.
- `lib/datagrid/bwu_datagrid_header_column.html` contains the basic styles for the column header cells.
- `lib/datagrid/bwu_datagrid_headers.html` and `lib/datagrid/bwu_datagrid_headerrow_column.html` also contain a few
styles and CSS mixins that are used to layout the column headers and can be customized by a few provided CSS mixin
hooks.

### Default theme
Additionally a custom theme can be loaded by setting the `theme` property of the BWU Datagrid component to a name of an
imported style module.
The default value for the `theme` property is `bwu-datagrid-default-theme`, which is defined in
`lib/datagrid/bwu_datagrid_default_theme.html`

The `bwu_datagrid_header_column` elements get the same theme name assigned but with an additional `-header-column`
suffix. When a style module with this name was imported, it gets applied to header columns.

library bwu_datagrid.groupitem_metadata_providers;

import 'dart:html' as dom;
import 'dart:async' as async;

import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;
import 'package:bwu_datagrid/editors/editors.dart' as ed;
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/dataview/dataview.dart';
import 'package:bwu_datagrid/plugins/plugin.dart';

class DefaultGroupCellFormatter extends fm.CellFormatter {
  GroupItemMetadataProvider giMetadataProvider;

  DefaultGroupCellFormatter(this.giMetadataProvider);

  @override
  void format(dom.Element target, int row, int cell, dynamic value,
      Column columnDef, core.ItemBase item) {
    assert(value == null || value is String);
    final core.Group group = item as core.Group;
    if (!giMetadataProvider.enableExpandCollapse) {
      target.append(group.title);
      return;
    }

    final String indentation = '${group.level * 15}px';

    target.innerHtml = '';
    target
      ..append(new dom.SpanElement()
        ..classes.add('${giMetadataProvider.toggleCssClass}')
        ..classes.add(
            '${group.isCollapsed ? giMetadataProvider.toggleCollapsedCssClass : giMetadataProvider.toggleExpandedCssClass}')
        ..style.marginLeft = indentation)
      ..append(new dom.SpanElement()
        ..classes.add('${giMetadataProvider.groupTitleCssClass}')
        ..attributes['level'] = '${group.level}'
        ..append(group.title));
  }
}

class DefaultTotalsCellFormatter extends core.GroupTotalsFormatter {
  GroupItemMetadataProvider giMetadataProvider;

  @override
  void format(dom.Element target, core.GroupTotals totals, Column columnDef) {
    if (columnDef.groupTotalsFormatter != null) {
      columnDef.groupTotalsFormatter.format(target, totals, columnDef);
    } else {
      target.innerHtml = '';
    }
  }
}

/// Provides item metadata for group (Group) and totals (Totals) rows produced by the DataView.
/// This metadata overrides the default behavior and formatting of those rows so that they appear and function
/// correctly when processed by the grid.
///
/// This class also acts as a grid plugin providing event handlers to expand & collapse groups.
/// If "grid.registerPlugin(...)" is not called, expand & collapse will not work.
class GroupItemMetadataProvider extends Plugin {
  //BwuDatagrid _grid;

  String groupCssClass;
  String groupTitleCssClass;
  String totalsCssClass;
  bool groupFocusable;
  bool totalsFocusable;
  String toggleCssClass;
  String toggleExpandedCssClass;
  String toggleCollapsedCssClass;
  bool enableExpandCollapse = true;
  fm.Formatter _groupFormatter;
  core.GroupTotalsFormatter _totalsFormatter;

  GroupItemMetadataProvider(
      {this.groupCssClass: "bwu-datagrid-group",
      this.groupTitleCssClass: "bwu-datagrid-group-title",
      this.totalsCssClass: "bwu-datagrid-group-totals",
      this.groupFocusable: true,
      this.totalsFocusable: false,
      this.toggleCssClass: "bwu-datagrid-group-toggle",
      this.toggleExpandedCssClass: "expanded",
      this.toggleCollapsedCssClass: "collapsed",
      this.enableExpandCollapse: true,
      fm.Formatter groupFormatter,
      core.GroupTotalsFormatter totalsFormatter}) {
    _groupFormatter = groupFormatter = new DefaultGroupCellFormatter(this);
    _totalsFormatter = totalsFormatter = new DefaultTotalsCellFormatter();
  }

  @override
  void init(BwuDatagrid grid) {
    super.init(grid);
    _gridClickSubscription = grid.onBwuClick.listen(_handleGridClick);
    _gridKeyDownSubscription = grid.onBwuKeyDown.listen(_handleGridKeyDown);
  }

  fm.Formatter getGroupFormatter() {
    if (_groupFormatter != null) {
      return _groupFormatter;
    }
    return new DefaultGroupCellFormatter(this);
  }

  core.GroupTotalsFormatter _getTotalsFormatter() {
    if (_totalsFormatter != null) {
      return _totalsFormatter;
    }
    return new DefaultTotalsCellFormatter();
  }

  async.StreamSubscription<core.Click> _gridClickSubscription;
  async.StreamSubscription<core.KeyDown> _gridKeyDownSubscription;

  @override
  void destroy() {
    if (_gridClickSubscription != null) {
      _gridClickSubscription.cancel();
    }
    if (_gridKeyDownSubscription != null) {
      _gridKeyDownSubscription.cancel();
    }
  }

  void _handleGridClick(core.Click e) {
    BwuDatagrid grid = e.sender;
    core.ItemBase item = grid.getDataItem(e.cell.row);
    if (item != null &&
        item is core.Group &&
        (e.causedBy.target as dom.Element).classes.contains(toggleCssClass)) {
      final Range range = grid.getRenderedRange();
      if (grid.dataProvider is DataView<core.ItemBase>) {
        final DataView<core.ItemBase> dp =
            grid.dataProvider as DataView<core.ItemBase>;
        dp.setRefreshHints(<String, dynamic>{
          'ignoreDiffsBefore': range.top,
          'ignoreDiffsAfter': range.bottom
        });

        if (item.isCollapsed) {
          dp.expandGroup(<String>[item.groupingKey]);
        } else {
          dp.collapseGroup(<String>[item.groupingKey]);
        }
      }
      e.stopImmediatePropagation();
      e.preventDefault();
    }
  }

  // TODO:  add -/+ handling
  void _handleGridKeyDown(core.KeyDown e) {
    BwuDatagrid grid = e.sender;
    if (enableExpandCollapse && (e.causedBy.keyCode == dom.KeyCode.SPACE)) {
      final Cell activeCell = grid.getActiveCell();
      if (activeCell != null) {
        core.ItemBase item = grid.getDataItem(activeCell.row);
        if (item != null && item is core.Group) {
          final Range range = grid.getRenderedRange();

          if (grid.dataProvider is DataView<core.ItemBase>) {
            final DataView<core.ItemBase> dp =
                grid.dataProvider as DataView<core.ItemBase>;

            (grid.dataProvider as DataView<core.ItemBase>)
                .setRefreshHints(<String, dynamic>{
              'ignoreDiffsBefore': range.top,
              'ignoreDiffsAfter': range.bottom
            });

            if (item.isCollapsed) {
              dp.expandGroup(<String>[item.groupingKey]);
            } else {
              dp.collapseGroup(<String>[item.groupingKey]);
            }
          }

          e.stopImmediatePropagation();
          e.preventDefault();
        }
      }
    }
  }

  RowMetadata getGroupRowMetadata(core.ItemBase item) {
    return new RowMetadata(
        selectable: false,
        focusable: groupFocusable,
        cssClasses: groupCssClass,
        columns: <String, Column>{
          '0': new Column(
              colspan: "*", formatter: getGroupFormatter(), editor: null)
        });
  }

  RowMetadata getTotalsRowMetadata(core.ItemBase item) {
    return new RowMetadata(
        selectable: false,
        focusable: totalsFocusable,
        cssClasses: totalsCssClass,
        formatter: _getTotalsFormatter(),
        editor: null);
  }
}

class RowMetadata {
  bool selectable;
  bool focusable;
  String cssClasses;
  Map<String, Column> columns = <String, Column>{};
  fm.Formatter formatter;
  ed.Editor editor;

  RowMetadata(
      {this.selectable,
      this.focusable,
      this.cssClasses,
      this.columns,
      this.formatter,
      this.editor});
}

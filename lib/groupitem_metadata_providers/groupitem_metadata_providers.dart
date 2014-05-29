library bwu_dart.bwu_datagrid.groupitem_metadata_providers;

import 'dart:html' as dom;
import 'dart:async' as async;

import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/formatters/formatters.dart';
import 'package:bwu_datagrid/editors/editors.dart';
import 'package:bwu_datagrid/core/core.dart';
import 'package:bwu_datagrid/dataview/dataview.dart';


class DefaultGroupCellFormatter extends Formatter {

  GroupItemMetadataProvider giMetadataProvider;

  DefaultGroupCellFormatter(this.giMetadataProvider);

   @override
   void call(dom.HtmlElement target, int row, int cell, String value, Column columnDef, /*Item/Map*/ item) {
    if (!giMetadataProvider.enableExpandCollapse) {
      return item['title'];
    }

    var indentation = '${item.level * 15}px';

    target.innerHtml = '';
    target
        ..append(
            new dom.SpanElement()
                ..classes.add('${giMetadataProvider.toggleCssClass}')
                ..classes.add('${item['collapsed'] ? giMetadataProvider.toggleCollapsedCssClass : giMetadataProvider.toggleExpandedCssClass}')
                ..style.marginLeft = '${indentation}px')
        ..append(new dom.SpanElement()
                ..classes.add('${giMetadataProvider.groupTitleCssClass}')
                ..attributes['level']='${item.level}'
                ..text = item.title);
  }
}

class DefaultTotalsCellFormatter extends Formatter {
  GroupItemMetadataProvider giMetadataProvider;

  @override
  void call(dom.HtmlElement target, int row, int cell, String value, Column columnDef, /*Item/Map*/ item) {
    if(columnDef.groupTotalsFormatter != null) {
      columnDef.groupTotalsFormatter(target, row, cell, null, columnDef, item);
    }
    target.innerHtml = '';
  }
}

/***
 * Provides item metadata for group (Group) and totals (Totals) rows produced by the DataView.
 * This metadata overrides the default behavior and formatting of those rows so that they appear and function
 * correctly when processed by the grid.
 *
 * This class also acts as a grid plugin providing event handlers to expand & collapse groups.
 * If "grid.registerPlugin(...)" is not called, expand & collapse will not work.
 *
 */
class GroupItemMetadataProvider {
  BwuDatagrid _grid;

  String groupCssClass= "bwu-datagrid-group";
  String groupTitleCssClass= "bwu-datagrid-group-title";
  String totalsCssClass= "bwu-datagrid-group-totals";
  bool groupFocusable= true;
  bool totalsFocusable= false;
  String toggleCssClass= "bwu-datagrid-group-toggle";
  String toggleExpandedCssClass= "expanded";
  String toggleCollapsedCssClass= "collapsed";
  bool enableExpandCollapse= true;
  Formatter _groupFormatter;
  Formatter _totalsFormatter;

  GroupItemMetadataProvider({this.groupCssClass, this.groupTitleCssClass, this.totalsCssClass,
      this.groupFocusable, this.totalsFocusable, this.toggleCssClass, this.toggleExpandedCssClass,
      this.toggleCollapsedCssClass, this.enableExpandCollapse, Formatter groupFormatter, Formatter totalsFormatter}) {
    _groupFormatter = groupFormatter;
    _totalsFormatter = totalsFormatter;
    _gridClickSubscription = _grid.onBwuClick.listen(_handleGridClick);
    _gridKeyDownSubscription = _grid.onBwuKeyDown.listen(_handleGridKeyDown);
  }

  Formatter _getGroupFormatter() {
    if(_groupFormatter != null) {
      return _groupFormatter;
    }
    return new DefaultGroupCellFormatter(this);
  }

  Formatter _getTotalsFormatter() {
    if(_totalsFormatter != null) {
      return _totalsFormatter;
    }
    return new DefaultTotalsCellFormatter();
  }

  async.StreamSubscription _gridClickSubscription;
  async.StreamSubscription _gridKeyDownSubscription;

  void destroy() {
    if(_gridClickSubscription != null) {
      _gridClickSubscription.cancel();
    }
    if(_gridKeyDownSubscription != null) {
      _gridKeyDownSubscription.cancel();
    }
  }

  void _handleGridClick(Click e) {
    BwuDatagrid grid = e.sender;
    ItemBase item = grid.getDataItem(e.cell.row);
    if (item != null && item is Group && (e.causedBy.target as dom.HtmlElement).classes.contains(toggleCssClass)) {
      var range = _grid.getRenderedRange();
      if(grid.dataProvider is DataView) {
        var dp = grid.dataProvider as DataView;
        dp.setRefreshHints({
          'ignoreDiffsBefore': range.top,
          'ignoreDiffsAfter': range.bottom
        });


        if (item.isCollapsed) {
          dp.expandGroup(item.groupingKey);
        } else {
          dp.collapseGroup(item.groupingKey);
        }
      }
      e.stopImmediatePropagation();
      e.preventDefault();
    }
  }

  // TODO:  add -/+ handling
  void _handleGridKeyDown(KeyDown e) {
    BwuDatagrid grid = e.sender;
    if (enableExpandCollapse && (e.causedBy.which == dom.KeyCode.SPACE)) {
      var activeCell = grid.getActiveCell();
      if (activeCell != null) {
        ItemBase item = grid.getDataItem(activeCell.row);
        if (item != null && item is Group) {
          var range = _grid.getRenderedRange();

          if(grid.dataProvider is DataView) {
            var dp = grid.dataProvider as DataView;

            (grid.dataProvider as DataView).setRefreshHints({
              'ignoreDiffsBefore': range.top,
              'ignoreDiffsAfter': range.bottom
            });

            if (item.isCollapsed) {
              dp.expandGroup(item.groupingKey);
            } else {
              dp.collapseGroup(item.groupingKey);
            }
          }

          e.stopImmediatePropagation();
          e.preventDefault();
        }
      }
    }
  }

  RowMetadata getGroupRowMetadata(ItemBase item) {
    return new RowMetadata(
      selectable: false,
      focusable: groupFocusable,
      cssClasses: groupCssClass,
      columns: {
        '0': new Column(
            colspan: "*",
            formatter: _getGroupFormatter(),
            editor: null
          )
        });
      }

  RowMetadata getTotalsRowMetadata(ItemBase item) {
    return new RowMetadata(
      selectable: false,
      focusable: totalsFocusable,
      cssClasses: totalsCssClass,
      formatter: _getTotalsFormatter(),
      editor: null
    );
  }
}

class RowMetadata {
  bool selectable;
  bool focusable;
  String cssClasses;
  Map<String,Column> columns = <String,Column>{};
  Formatter formatter;
  Editor editor;

  RowMetadata({this.selectable, this.focusable, this.cssClasses, this.columns, this.formatter, this.editor});
}

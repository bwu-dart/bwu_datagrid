library bwu_dart.bwu_datagrid.groupitem_metadata_providers;

import 'dart:html' as dom;
import 'dart:async' as async;

import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';
//(function ($) {
//  $.extend(true, window, {
//    Slick: {
//      Data: {
//        GroupItemMetadataProvider: GroupItemMetadataProvider
//      }
//    }
//  });


  /***
   * Provides item metadata for group (Slick.Group) and totals (Slick.Totals) rows produced by the DataView.
   * This metadata overrides the default behavior and formatting of those rows so that they appear and function
   * correctly when processed by the grid.
   *
   * This class also acts as a grid plugin providing event handlers to expand & collapse groups.
   * If "grid.registerPlugin(...)" is not called, expand & collapse will not work.
   *
   * @class GroupItemMetadataProvider
   * @module Data
   * @namespace Slick.Data
   * @constructor
   * @param options
   */
class GroupitemMetadataProvider {
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
  Function _groupFormatter;
  Function _totalsFormatter;

  GroupitemMetadataProvider(this.groupCssClass, this.groupTitleCssClass, this.totalsCssClass,
      this.groupFocusable, this.totalsFocusable, this.toggleCssClass, this.toggleExpandedCssClass,
      this.toggleCollapsedCssClass, this.enableExpandCollapse, this._groupFormatter, this._totalsFormatter) {
    gridClickSubscription = _grid.onClick.listen(handleGridClick);
    gridKeyDownSubscription = _grid.onKeyDown.listen(handleGridKeyDown);
  }

  Function get groupFormatter {
    if(_groupFormatter != null) {
      return _groupFormatter;
    }
    return defaultGroupCellFormatter;
  }

  Function get totalsFormatter {
    if(_totalsFormatter != null) {
      return _totalsFormatter;
    }
    return defaultTotalsCellFormatter;
  }


  String defaultGroupCellFormatter(int row, int cell, String value, ColumnDefinition columnDef, Item item) {
    if (!enableExpandCollapse) {
      return item.title;
    }

    var indentation = item.level * 15 + "px";

    return "<span class='" + toggleCssClass + " " +
        (item.collapsed ? toggleCollapsedCssClass : toggleExpandedCssClass) +
        "' style='margin-left:" + indentation +"'>" +
        "</span>" +
        "<span class='" + groupTitleCssClass + "' level='" + item.level + "'>" +
        (item.collapsed ? toggleCollapsedCssClass : toggleExpandedCssClass) +
        "' style='margin-left:" + indentation +"'>" +
        "</span>" +
        "<span class='" + groupTitleCssClass + "' level='" + item.level + "'>" +
          item.title +
        "</span>";
  }

  String defaultTotalsCellFormatter(int row, int cell, String value, ColumnDefinition columnDef, Item item) {
    return (columnDef.groupTotalsFormatter && columnDef.groupTotalsFormatter(item, columnDef)) || "";
  }


  async.StreamSubscription gridClickSubscription;
  async.StreamSubscription gridKeyDownSubscription;

  void destroy() {
    if(gridClickSubscription != null) {
      gridClickSubscription.cancel();
    }
    if(gridKeyDownSubscription != null) {
      gridKeyDownSubscription.cancel();
    }
  }


  void handleGridClick(dom.MouseEvent e) {
    var args = e.detail as Map;
    var item = getDataItem(args['row']);
    if (item && item is Group && (e.target as dom.HtmlElement).classes.contains(toggleCssClass)) {
      var range = _grid.getRenderedRange();
      getData().setRefreshHints({
        'ignoreDiffsBefore': range.top,
        'ignoreDiffsAfter': range.bottom
      });

      if (item.collapsed) {
        getData().expandGroup(item.groupingKey);
      } else {
        getData().collapseGroup(item.groupingKey);
      }

      e.stopImmediatePropagation();
      e.preventDefault();
    }
  }

  // TODO:  add -/+ handling
  void handleGridKeyDown(dom.KeyboardEvent e) {
    Map args = e.detail as Map;
    if (enableExpandCollapse && (e.which == dom.KeyCode.SPACE)) {
      var activeCell = getActiveCell();
      if (activeCell != null) {
        var item = getDataItem(activeCell.row);
        if (item && item is Group) {
          var range = _grid.getRenderedRange();
          getData().setRefreshHints({
            'ignoreDiffsBefore': range.top,
            'ignoreDiffsAfter': range.bottom
          });

          if (item.collapsed) {
            getData().expandGroup(item.groupingKey);
          } else {
            getData().collapseGroup(item.groupingKey);
          }

          e.stopImmediatePropagation();
          e.preventDefault();
        }
      }
    }
  }

  Map getGroupRowMetadata(Item item) {
    return {
      'selectable': false,
      'focusable': groupFocusable,
      'cssClasses': groupCssClass,
      'columns': {
        0: {
          'colspan': "*",
          'formatter': groupFormatter,
          'editor': null
        }
      }
    };
  }

  Map getTotalsRowMetadata(Item item) {
    return {
      'selectable': false,
      'focusable': totalsFocusable,
      'cssClasses': totalsCssClass,
      'formatter': totalsFormatter,
      'editor': null
    };
  }


//    return {
//      "init": init,
//      "destroy": destroy,
//      "getGroupRowMetadata": getGroupRowMetadata,
//      "getTotalsRowMetadata": getTotalsRowMetadata
//    };
}

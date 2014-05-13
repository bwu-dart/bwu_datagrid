library bwu_dart.bwu_datagrid.plugin.auto_tooltips;

import 'dart:html' as dom;
import 'dart:async' as async;

import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'plugin.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/tools/html.dart' as tools;

class AutoTooltipsOptions {
  bool enableForCells;
  bool enableForHeaderCells;
  int maxTooltipLength;

  AutoTooltipsOptions({this.enableForCells : true, this.enableForHeaderCells : false, this.maxTooltipLength});
}

/**
   * AutoTooltips plugin to show/hide tooltips when columns are too narrow to fit content.
   * @constructor
   * @param {boolean} [options.enableForCells=true]        - Enable tooltip for grid cells
   * @param {boolean} [options.enableForHeaderCells=false] - Enable tooltip for header cells
   * @param {number}  [options.maxToolTipLength=null]      - The maximum length for a tooltip
   */
class AutoTooltips extends Plugin {


  AutoTooltipsOptions options;

  AutoTooltips([this.options]) : super() {
    if(options == null) {
      options = new AutoTooltipsOptions();
    }
  }

  async.StreamSubscription mouseEnterSubscription;
  async.StreamSubscription headerMouseEnterSubscription;
  /**
   * Initialize plugin.
   */
  @override
  void init(BwuDatagrid grid) {
    super.init(grid);
    if (options.enableForCells) {
      mouseEnterSubscription = grid.onBwuMouseEnter.listen(handleMouseEnter);
    }
    if (options.enableForHeaderCells) {
      headerMouseEnterSubscription = grid.onBwuHeaderMouseEnter.listen(handleHeaderMouseEnter);
    }
  }

  /**
   * Destroy plugin.
   */
  void destroy() {
    if (mouseEnterSubscription != null) {
      mouseEnterSubscription.cancel();
    }
    if (headerMouseEnterSubscription != null) {
      headerMouseEnterSubscription.cancel();
    }
  }

  /**
   * Handle mouse entering grid cell to add/remove tooltip.
   * @param {jQuery.Event} e - The event
   */
  void handleMouseEnter(core.MouseEnter e) {
    var cell = grid.getCellFromEvent(e.causedBy);
    if (cell != null) {
      var $node = grid.getCellNode(cell.row, cell.cell);
      var text;
      if (tools.innerWidth($node) < $node.children[0].scrollWidth) {
        text = $node.text.trim();
        if (options.maxTooltipLength && text.length > options.maxTooltipLength) {
          text = text.substring(0, options.maxTooltipLength - 3) + "...";
        }
      } else {
        text = "";
      }
      $node.attributes["title"] = text;
    }
  }

  /**
   * Handle mouse entering header cell to add/remove tooltip.
   * @param {jQuery.Event} e     - The event
   * @param {object} args.column - The column definition
   */
  void handleHeaderMouseEnter(core.HeaderMouseEnter e) {
    //var detail = e.detail as core.HeaderMouseEnter;
    var column = e.data;
    var $node = tools.closest((e.causedBy.target as dom.HtmlElement), '.bwu-datagrid-header-column');
    if($node == null) {
      print($node);
      $node = tools.closest((e.causedBy.target as dom.HtmlElement), '.bwu-datagrid-header-column');
    }
    if (column.toolTip == null) {
      $node.attributes["title"] =tools.innerWidth($node) < $node.scrollWidth ? column.name : "";
    }
  }
}
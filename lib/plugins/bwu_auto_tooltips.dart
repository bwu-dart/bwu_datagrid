library bwu_dart.bwu_datagrid.plugin.auto_tooltips;

import 'dart:html' as dom;
import 'dart:async' as async;

import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'plugin.dart';

class AutoTooltipsOptions {
  bool enableForCells = true;
  bool enableForHeaderCells = false;
  bool maxTooltipLength = null;

  AutoTooltipsOptions({this.enableForCells, this.enableForHeaderCells, this.maxTooltipLength});
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
    if(options = null) {
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
      mouseEnterSubscription = grid.onMouseEnter.listen(handleMouseEnter);
    }
    if (options.enableForHeaderCells) {
      headerMouseEnterSubscription = grid.onHeaderMouseEnter.listen(handleHeaderMouseEnter);
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
  void handleMouseEnter(dom.MouseEvent e) {
    var cell = grid.getCellFromEvent(e);
    if (cell != null) {
      var $node = grid.getCellNode(cell['row'], cell['cell']);
      var text;
      if ($node.innerWidth() < $node.children[0].scrollWidth) {
        text = $node.text.trim();
        if (options.maxTooltipLength && text.length > options.maxTooltipLength) {
          text = text.substring(0, options.maxTooltipLength - 3) + "...";
        }
      } else {
        text = "";
      }
      $node.attr("title", text);
    }
  }

  /**
   * Handle mouse entering header cell to add/remove tooltip.
   * @param {jQuery.Event} e     - The event
   * @param {object} args.column - The column definition
   */
  void handleHeaderMouseEnter(dom.MouseEvent e, int args) {
    var column = args.column,
        $node = (e.target as dom.HtmlElement).closest(".slick-header-column");
    if (!column.toolTip) {
      $node.attr("title", ($node.innerWidth() < $node[0].scrollWidth) ? column.name : "");
    }
  }
}
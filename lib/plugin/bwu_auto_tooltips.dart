library bwu_dart.bwu_datagrid.plugin.auto_tooltips;

import 'dart:html' as dom;

import 'packages:bwu_datagrid/bwu_datagrid.dart';
import 'plugin.dart';

class AutoTooltipsOptions {
  bool enableForCells = true;
  bool enableForHeaderCells = false;
  bool maxTooltipLength = null;
}

/**
   * AutoTooltips plugin to show/hide tooltips when columns are too narrow to fit content.
   * @constructor
   * @param {boolean} [options.enableForCells=true]        - Enable tooltip for grid cells
   * @param {boolean} [options.enableForHeaderCells=false] - Enable tooltip for header cells
   * @param {number}  [options.maxToolTipLength=null]      - The maximum length for a tooltip
   */
class AutoTooltips extends Plugin {


  var options = new AutoTooltipsOptions();

  AutoTooltips(this._grid, this.options) : super(_grid);

  /**
   * Initialize plugin.
   */
  void init() {
    if (options.enableForCells) _grid.onMouseEnter.subscribe(handleMouseEnter);
    if (options.enableForHeaderCells) _grid.onHeaderMouseEnter.subscribe(handleHeaderMouseEnter);
  }

  /**
   * Destroy plugin.
   */
  void destroy() {
    if (options.enableForCells) _grid.onMouseEnter.unsubscribe(handleMouseEnter);
    if (options.enableForHeaderCells) _grid.onHeaderMouseEnter.unsubscribe(handleHeaderMouseEnter);
  }

  /**
   * Handle mouse entering grid cell to add/remove tooltip.
   * @param {jQuery.Event} e - The event
   */
  void handleMouseEnter(dom.MouseEvent e) {
    var cell = _grid.getCellFromEvent(e);
    if (cell != null) {
      var $node = _grid.getCellNode(cell.row, cell['cell']);
      var text;
      if ($node.innerWidth() < $node[0].scrollWidth) {
        text = $node.text().trim();
        if (options.maxToolTipLength && text.length > options.maxToolTipLength) {
          text = text.substr(0, options.maxToolTipLength - 3) + "...";
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
library bwu_dart.bwu_datagrid.plugin.auto_tooltips;

import 'dart:html' as dom;
import 'dart:async' as async;
//import 'dart:math' as math;

//import 'package:polymer/polymer.dart' as pm;
//import 'package:core_elements/core_tooltip/core_tooltip.dart' as tt;
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_utils_browser/html/html.dart' as tools;

import 'plugin.dart';

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

  //tt.CoreTooltip tooltip;
  //dom.DivElement ttText;

  AutoTooltips([this.options]) : super() {
    if(options == null) {
      options = new AutoTooltipsOptions();
    }
  }

  async.StreamSubscription mouseEnterSubscription;
  //async.StreamSubscription mouseLeaveSubscription;
  async.StreamSubscription headerMouseEnterSubscription;
  //async.StreamSubscription headerMouseLeaveSubscription;
  /**
   * Initialize plugin.
   */
  @override
  void init(BwuDatagrid grid) {
    super.init(grid);
    if (options.enableForCells) {
      mouseEnterSubscription = grid.onBwuMouseEnter.listen(handleMouseEnter);
      //mouseLeaveSubscription = grid.onBwuMouseLeave.listen(handleMouseLeave);
    }
    if (options.enableForHeaderCells) {
      headerMouseEnterSubscription = grid.onBwuHeaderMouseEnter.listen(handleHeaderMouseEnter);
      //headerMouseLeaveSubscription = grid.onBwuHeaderMouseLeave.listen(handleHeaderMouseLeave);
    }

    //dom.document.registerElement('core-tooltip', tt.CoreTooltip);
//    pm.Polymer.onReady.then((e) {
//      tooltip = new dom.Element.tag('core-tooltip') as tt.CoreTooltip;
//      ttText =new dom.DivElement()..attributes['tip'] = '';
//
//      tooltip.append(ttText);
//      tooltip.style
//        ..position = 'absolute';
//      tooltip.attributes['position']='right';
//
//      //grid.shadowRoot.append(tooltip);
//      dom.document.body.append(tooltip);
//    });

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
    //tooltip.remove();
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
      if (tools.innerWidth($node) < $node.scrollWidth) {
        text = $node.text.trim();
        if (options.maxTooltipLength != null && text.length > options.maxTooltipLength) {
          text = text.substring(0, options.maxTooltipLength - 3) + "...";
        }
        //showTooltip($node);
      } else {
        text = "";
        //tooltip.show = false;
      }
      $node.attributes["title"] = text;
      //ttText.text = text;
    }
  }

//  void showTooltip(dom.HtmlElement $node) {
//    var bcr = $node.getBoundingClientRect();
//    var ttBcr = tooltip.getBoundingClientRect();
//    var transition = '';
//    if(tooltip.show) {
//      var v = (bcr.top - ttBcr.top).abs();
//      var h = (bcr.left - ttBcr.left).abs();
//      var ms = (math.sqrt(v+h) * 10).round();
//      transition = 'top ${ms}ms ease-in-out, left ${ms}ms ease-in-out';
//    }
//    tooltip
//        ..show = true
//        ..style.top = '${bcr.top + (bcr.height * 0.8).round()}px'
//        ..style.left = '${bcr.left + bcr.width}px'
//        ..style.transition = transition;
//
//  }
//  void hideTooltip() {
//    new async.Future.delayed(new Duration(milliseconds: 500), () => tooltip.show = false);
//  }
//
//  void handleMouseLeave(core.MouseLeave e) {
//    hideTooltip();
//  }
//
//  void handleHeaderMouseLeave(core.HeaderMouseLeave e) {
//    hideTooltip();
//  }

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
      $node = tools.closest((e.causedBy.target as dom.HtmlElement), '.bwu-datagrid-header-column');
    }
    if (column.toolTip == null) {
      $node.attributes["title"] =tools.innerWidth($node) < $node.scrollWidth ? column.name : "";
    }
  }
}


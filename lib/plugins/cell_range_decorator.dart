library bwu_datagrid.plugins.cell_range_decorator;

import 'dart:html' as dom;
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/core/core.dart';

abstract class Decorator {
  dom.HtmlElement show(Range r);
  void hide();
}

class CellRangeDecoratorOptions {
  String selectionCssClass;
  Map<String,String> selectionCss;

  CellRangeDecoratorOptions({this.selectionCssClass, this.selectionCss});
}

class CellRangeDecorator extends Decorator {

  var _elem;
  var _defaults = {
    'selectionCssClass': 'slick-range-decorator',
    'selectionCss': {
      'zIndex': '9999',
      'border': '2px dashed red'
    }
  };

  BwuDatagrid _grid;
  CellRangeDecoratorOptions _options;

  /***
   * Displays an overlay on top of a given cell range.
   *
   * TODO:
   * Currently, it blocks mouse events to DOM nodes behind it.
   * Use FF and WebKit-specific "pointer-events" CSS style, or some kind of event forwarding.
   * Could also construct the borders separately using 4 individual DIVs.
   *
   * @param {Grid} grid
   * @param {Object} options
   */
  CellRangeDecorator(this._grid, this._options);


    // TODO options = $.extend(true, {}, _defaults, options);

    @override
    dom.HtmlElement show(Range range) {
      if (!_elem) {
        _elem = new dom.DivElement()
            // TODO (_options.selectionCss) //$("<div></div>", {'css': options.selectionCss})
            ..classes.add(_options.selectionCssClass)
            ..style.position= 'absolute';
        _grid.getCanvasNode.append(_elem);
      }

      var from = _grid.getCellNodeBox(range.fromRow, range.fromCell);
      var to = _grid.getCellNodeBox(range.toRow, range.toCell);

      _elem.style
        ..top = from.top - 1
        ..left = from.left - 1
        ..height = to.bottom - from.top - 2
        ..width = to.right - from.left - 2;

      return _elem;
    }

    @override
    void hide() {
      if (_elem) {
        _elem.remove();
        _elem = null;
      }
    }

//    $.extend(this, {
//      "show": show,
//      "hide": hide
//    });
//  }
}

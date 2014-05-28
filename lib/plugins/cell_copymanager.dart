library bwu_dart.bwu_datagrid.plugin.cell_copymanager;

import 'dart:html' as dom;
import 'dart:async' as async;

import 'package:bwu_datagrid/plugins/plugin.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/core/core.dart' as core;

//  // register namespace
//  $.extend(true, window, {
//    "Slick": {
//      "CellCopyManager": CellCopyManager
//    }
//  });


class CellCopyManager extends Plugin {
  var _copiedRanges;

  CellCopyManager();

  async.StreamSubscription keyDownSubscription;

  @override
  void init(BwuDatagrid grid) {
    super.init(grid);
    keyDownSubscription = grid.onKeyDown.listen(handleKeyDown);
  }

  void destroy() {
    if (keyDownSubscription != null) {
      keyDownSubscription.cancel();
    }
  }

  void handleKeyDown(dom.KeyboardEvent e) {
    Map args = e.detail as Map;
    var ranges;
    if (!grid.getEditorLock.isActive) {
      if (e.which == dom.KeyCode.ESC) {
        if (_copiedRanges) {
          e.preventDefault();
          clearCopySelection();
          grid.eventBus.fire(core.Events.COPY_CANCELLED, new core.CopyCancelled(this, _copiedRanges));
//          onCopyCancelled.notify({
//            ranges: _copiedRanges
//          });
          _copiedRanges = null;
        }
      }

      if (e.which == 67 && (e.ctrlKey || e.metaKey)) {
        ranges = grid.getSelectionModel.getSelectedRanges();
        if (ranges.length != 0) {
          e.preventDefault();
          _copiedRanges = ranges;
          markCopySelection(ranges);
          grid.eventBus.fire(core.Events.COPY_CELLS, new core.CopyCells(this, ranges));
//          onCopyCells.notify({
//            'ranges': ranges
//          });
        }
      }

      if (e.which == 86 && (e.ctrlKey || e.metaKey)) {
        if (_copiedRanges) {
          e.preventDefault();
          clearCopySelection();
          ranges = grid.getSelectionModel.getSelectedRanges();
          grid.eventBus.fire(core.Events.PASTE_CELLS, new core.PasteCells(this, _copiedRanges, ranges));
//          onPasteCells.notify({
//            'from': _copiedRanges,
//            'to': ranges
//          });
          _copiedRanges = null;
        }
      }
    }
  }

  void markCopySelection(List<core.Range> ranges) {
    var columns = grid.getColumns;
    var hash = {};
    for (var i = 0; i < ranges.length; i++) {
      for (var j = ranges[i].fromRow; j <= ranges[i].toRow; j++) {
        hash[j] = {};
        for (var k = ranges[i].fromCell; k <= ranges[i].toCell; k++) {
          hash[j][columns[k].id] = "copied";
        }
      }
    }
    grid.setCellCssStyles("copy-manager", hash);
  }

  void clearCopySelection() {
    grid.removeCellCssStyles("copy-manager");
  }

    //    $.extend(this, {
    //      "init": init,
    //      "destroy": destroy,
    //      "clearCopySelection": clearCopySelection,
    //
    //      "onCopyCells": new Slick.Event(),
    //      "onCopyCancelled": new Slick.Event(),
    //      "onPasteCells": new Slick.Event()
    //    });
}

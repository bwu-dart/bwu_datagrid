library bwu_dart.bwu_datagrid.plugin.cell_copymanager;

import 'dart:html' as dom;
import 'dart:async' as async;

import 'package:bwu_datagrid/plugins/plugin.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/core/core.dart' as core;

class CellCopyManager extends Plugin {
  List<core.Range> _copiedRanges;

  core.EventBus get eventBus => _eventBus;
  core.EventBus _eventBus = new core.EventBus();

  CellCopyManager();

  async.StreamSubscription keyDownSubscription;

  @override
  void init(BwuDatagrid grid) {
    super.init(grid);
    keyDownSubscription = grid.onBwuKeyDown.listen(_handleKeyDown);
  }

  void destroy() {
    if (keyDownSubscription != null) {
      keyDownSubscription.cancel();
    }
  }

  void _handleKeyDown(core.KeyDown e) {
    List<core.Range> ranges;
    if (!grid.getEditorLock.isActive) {
      if (e.causedBy.which == dom.KeyCode.ESC) {
        if (_copiedRanges != null) {
          e.preventDefault();
          clearCopySelection();
          eventBus.fire(core.Events.COPY_CANCELLED, new core.CopyCancelled(this, _copiedRanges));
          _copiedRanges = null;
        }
      }

      if (e.causedBy.which == 67 && (e.causedBy.ctrlKey || e.causedBy.metaKey)) {
        ranges = grid.getSelectionModel.getSelectedRanges();
        if (ranges.length != 0) {
          e.preventDefault();
          _copiedRanges = ranges;
          _markCopySelection(ranges);
          eventBus.fire(core.Events.COPY_CELLS, new core.CopyCells(this, ranges));
        }
      }

      if (e.causedBy.which == 86 && (e.causedBy.ctrlKey || e.causedBy.metaKey)) {
        if (_copiedRanges != null) {
          e.preventDefault();
          clearCopySelection();
          ranges = grid.getSelectionModel.getSelectedRanges();
          eventBus.fire(core.Events.PASTE_CELLS, new core.PasteCells(this, _copiedRanges, ranges));
          _copiedRanges = null;
        }
      }
    }
  }

  void _markCopySelection(List<core.Range> ranges) {
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

  async.Stream<core.CopyCells> get onBwuCopyCells =>
      _eventBus.onEvent(core.Events.COPY_CELLS);

  async.Stream<core.CopyCancelled> get onBwuCopyCancelled =>
      _eventBus.onEvent(core.Events.COPY_CANCELLED);

  async.Stream<core.PasteCells> get onBwuPasteCells =>
      _eventBus.onEvent(core.Events.PASTE_CELLS);
}

library bwu_dart.bwu_datagrid.plugin;

import 'dart:html' as dom;
import 'dart:async' as async;

abstract class Plugin {
  void destroy();
  void init(BwuDataGrid grid);
}

class SelectionModel extends Plugin {

  @override
  void init(BwuDataGrid grid) {

  }

  @override
  void destroy() {
    // TODO: implement destroy
  }

  /**
   * on selected-ranges-changed
   */
  static const ON_SELECTED_RANGES_CHANGED = 'selected-ranges-changed';
  async.Stream<dom.CustomEvent> _onSelectedRangesChanged = new async.Stream<dom.CustomEvent>();
  async.Stream<dom.CustomEvent> get onSelectedRangesChanged =>
//      BwuDatagrid._onSelectedRangesChanged.forTarget(this);
      SelectionModel._onSelectedRangesChanged; //.forTarget(this);

  static const dom.EventStreamProvider<dom.CustomEvent> _onSelectedRangesChanged =
      const dom.EventStreamProvider<dom.CustomEvent>(ON_SELECTED_RANGES_CHANGED);

//  var controller = new StreamController.broadcast();
//         var stream = controller.stream.asyncMap((e) => e);
//         controller.add(1);
}
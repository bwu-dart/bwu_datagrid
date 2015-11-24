part of bwu_datagrid.core;

abstract class Events {
  static const EventType<ActiveCellChanged> ACTIVE_CELL_CHANGED =
      const EventType<ActiveCellChanged>('bwu-active-cell-changed');

  static const EventType<
      ActiveCellPositionChanged> ACTIVE_CELL_POSITION_CHANGED = const EventType<
      ActiveCellPositionChanged>('bwu-active-cell-position-changed');

  static const EventType<AddNewRow> ADD_NEW_ROW =
      const EventType<AddNewRow>('bwu-add-new-row');

  static const EventType<Attached> ATTACHED =
      const EventType<Attached>('bwu-attached');

  static const EventType<BeforeCellEditorDestroy> BEFORE_CELL_EDITOR_DESTROY =
      const EventType<BeforeCellEditorDestroy>(
          'bwu-before-cell-editor-destroy');

  static const EventType<BeforeCellRangeSelected> BEFORE_CELL_RANGE_SELECTED =
      const EventType<BeforeCellRangeSelected>(
          'bwu-before-cell-range-selected');

  static const EventType<BeforeDestroy> BEFORE_DESTROY =
      const EventType<BeforeDestroy>('bwu-before-destroy');

  static const EventType<BeforeEditCell> BEFORE_EDIT_CELL =
      const EventType<BeforeEditCell>('bwu-before-edit-cell');

  static const EventType<BeforeHeaderCellDestroy> BEFORE_HEADER_CELL_DESTROY =
      const EventType<BeforeHeaderCellDestroy>(
          'bwu-before-header-cell-destroy');

  static const EventType<
          BeforeHeaderRowCellDestroy> BEFORE_HEADER_ROW_CELL_DESTROY =
      const EventType<BeforeHeaderRowCellDestroy>(
          'bwu-before-header-row-cell-destroy');

  static const EventType<BeforeMoveRows> BEFORE_MOVE_ROWS =
      const EventType<BeforeMoveRows>('bwu-before-move-rows');

  static const EventType<CellChange> CELL_CHANGE =
      const EventType<CellChange>('bwu-cell-changed');

  static const EventType<CellRangeSelected> CELL_RANGE_SELECTED =
      const EventType<CellRangeSelected>('bwu-cell-range-selected');

  static const EventType<CellCssStylesChanged> CELL_CSS_STYLES_CHANGED =
      const EventType<CellCssStylesChanged>('bwu-cell-css-styles-changed');

  static const EventType<Click> CLICK = const EventType<Click>('bwu-click');

  static const EventType<ColumnsReordered> COLUMNS_REORDERED =
      const EventType<ColumnsReordered>('bwu-columns-reordered');

  static const EventType<ColumnsResized> COLUMNS_RESIZED =
      const EventType<ColumnsResized>('bwu-columns-resized');

  static const EventType<ContextMenu> CONTEXT_MENU =
      const EventType<ContextMenu>('bwu-context-menu');

  static const EventType<CopyCancelled> COPY_CANCELLED =
      const EventType<CopyCancelled>('bwu-copy-cancelled');

  static const EventType<CopyCells> COPY_CELLS =
      const EventType<CopyCells>('bwu-copy-cells');

  static const EventType<DoubleClick> DOUBLE_CLICK =
      const EventType<DoubleClick>('bwu-double-click');

//  static const EventType<CustomDrag> CUSTOM_DRAG = const EventType<CustomDrag>('bwu-custom-drag');
//
//  static const EventType<CustomDragEnd> CUSTOM_DRAG_END = const EventType<CustomDragEnd>('bwu-custom-drag-end');
//
//  static const  EventType<CustomDragStart> CUSTOM_DRAG_START = const EventType<CustomDragStart>('bwu-custom-drag-start');
//
  static const EventType<Drag> DRAG = const EventType<Drag>('bwu-drag');

  static const EventType<DragEnd> DRAG_END =
      const EventType<DragEnd>('bwu-drag-end');

  static const EventType<DragEnter> DRAG_ENTER =
      const EventType<DragEnter>('bwu-drag-enter');

  static const EventType<DragLeave> DRAG_LEAVE =
      const EventType<DragLeave>('bwu-drag-leave');

  static const EventType<DragOver> DRAG_OVER =
      const EventType<DragOver>('bwu-drag-over');

  static const EventType<Drop> DROP = const EventType<Drop>('bwu-drop');

  // TODO this is a jQuery specific event, there is no replacement for it
  //static const DRAG_INIT = const EventType<DragInit>('bwu-drag-init');

  static const EventType<DragStart> DRAG_START =
      const EventType<DragStart>('bwu-drag-start');

  static const EventType<HeaderCellRendered> HEADER_CELL_RENDERED =
      const EventType<HeaderCellRendered>('bwu-header-cell-rendered');

  static const EventType<HeaderClick> HEADER_CLICK =
      const EventType<HeaderClick>('bwu-header-click');

  static const EventType<HeaderContextMenu> HEADER_CONTEX_MENU =
      const EventType<HeaderContextMenu>('bwu-header-context-menu');

  static const EventType<HeaderMouseEnter> HEADER_MOUSE_ENTER =
      const EventType<HeaderMouseEnter>('bwu-header-mouse-enter');

  static const EventType<HeaderMouseLeave> HEADER_MOUSE_LEAVE =
      const EventType<HeaderMouseLeave>('bwu-header-mouse-leave');

  static const EventType<HeaderRowCellRendered> HEADER_ROW_CELL_RENDERED =
      const EventType<HeaderRowCellRendered>('bwu-header-row-cell-rendered');

  static const EventType<KeyDown> KEY_DOWN =
      const EventType<KeyDown>('bwu-key-down');

  static const EventType<MouseEnter> MOUSE_ENTER =
      const EventType<MouseEnter>('bwu-mouse-enter');

  static const EventType<MouseLeave> MOUSE_LEAVE =
      const EventType<MouseLeave>('bwu-mouse-leave');

  static const EventType<MoveRows> MOVE_ROWS =
      const EventType<MoveRows>('bwu-move-rows');

  static const EventType<PagingInfoChanged> PAGING_INFO_CHANGED =
      const EventType<PagingInfoChanged>('bwu-paging-info-changed');

  static const EventType<PasteCells> PASTE_CELLS =
      const EventType<PasteCells>('bwu-paste-cells');

  static const EventType<RowsChanged> ROWS_CHANGED =
      const EventType<RowsChanged>('bwu-rows-changed');

  static const EventType<RowCountChanged> ROW_COUNT_CHANGED =
      const EventType<RowCountChanged>('bwu-row-count-changed');

  static const EventType<Scroll> SCROLL = const EventType<Scroll>('bwu-scroll');

  static const EventType<SelectedRangesChanged> SELECTED_RANGES_CHANGED =
      const EventType<SelectedRangesChanged>('bwu-selected-ranges-changed');

  static const EventType<SelectedRowIdsChanged> SELECTED_ROW_IDS_CHANGED =
      const EventType<SelectedRowIdsChanged>('selected-row-ids-changed');

  static const EventType<SelectedRowsChanged> SELECTED_ROWS_CHANGED =
      const EventType<SelectedRowsChanged>('bwu-selected-rows-changed');

  static const EventType<Sort> SORT = const EventType<Sort>('bwu-sort');

  static const EventType<ValidationError> VALIDATION_ERROR =
      const EventType<ValidationError>('bwu-validation-error');

  static const EventType<ViewportChanged> VIEWPORT_CHANGED =
      const EventType<ViewportChanged>('bwu-viewport-changed');
}

/// An event object for passing data to event handlers and letting them control propagation.
/// <p>This is pretty much identical to how W3C and jQuery implement events.</p>
/// @class EventData
/// @constructor
class EventData {
  final Object sender;
  final dom.Event _causedBy;
  dom.Event get causedBy => _causedBy;
  Map detail = {};
  bool retVal = true;

  bool _isPropagationStopped = false;
  bool _isImmediatePropagationStopped = false;
  bool _isDefaultPrevented = false;

  /// Returns whether stopPropagation was called on this event object.
  /// @method isPropagationStopped
  /// @return {Boolean}
  bool get isPropagationStopped => _isPropagationStopped;

  /// Stops event from propagating up the DOM tree.
  /// @method stopPropagation
  void stopPropagation() {
    _isPropagationStopped = true;
    if (causedBy != null) {
      causedBy.stopPropagation();
    }
  }

  /// Stops event from propagating up the DOM tree.
  /// @method stopPropagation
  void preventDefault() {
    _isDefaultPrevented = true;
    if (causedBy != null) {
      causedBy.preventDefault();
    }
  }

  bool get isDefaultPrevented => _isDefaultPrevented;

  /// Returns whether stopImmediatePropagation was called on this event object.\
  /// @method isImmediatePropagationStopped
  /// @return {Boolean}
  bool get isImmediatePropagationStopped => _isImmediatePropagationStopped;

  /// Prevents the rest of the handlers from being executed.
  /// @method stopImmediatePropagation
  void stopImmediatePropagation() {
    _isImmediatePropagationStopped = true;
    if (causedBy != null) {
      causedBy.stopImmediatePropagation();
    }
  }

  EventData({this.sender, dom.Event causedBy}) : _causedBy = causedBy;
}

class Attached extends EventData {
  Attached(Object sender) : super(sender: sender);
}

class ActiveCellChanged extends EventData {
  final Cell cell;

  ActiveCellChanged(Object sender, this.cell) : super(sender: sender);
}

class ActiveCellPositionChanged extends EventData {
  ActiveCellPositionChanged(Object sender) : super(sender: sender);
}

class AddNewRow extends EventData {
  final DataItem item;
  final Column column;

  AddNewRow(Object sender, this.item, this.column) : super(sender: sender);
}

class BeforeCellEditorDestroy extends EventData {
  final Editor editor;

  BeforeCellEditorDestroy(Object sender, this.editor) : super(sender: sender);
}

class BeforeCellRangeSelected extends EventData {
  final Cell cell;

  BeforeCellRangeSelected(Object sender, this.cell) : super(sender: sender);
}

class BeforeDestroy extends EventData {
  BeforeDestroy(Object sender) : super(sender: sender);
}

class BeforeEditCell extends EventData {
  final Cell cell;
  final DataItem item;
  final Column column;

  BeforeEditCell(Object sender, {this.cell, this.item, this.column})
      : super(sender: sender);
}

class CellChange extends EventData {
  final Cell cell;
  final DataItem item;

  CellChange(Object sender, this.cell, this.item) : super(sender: sender);
}

class BeforeHeaderCellDestroy extends EventData {
  final dom.Element node;
  final Column columnDef;

  BeforeHeaderCellDestroy(Object sender, this.node, this.columnDef)
      : super(sender: sender);
}

// TODO which properties are really needed for this event
class BeforeHeaderRowCellDestroy extends EventData {
  final dom.Element node;
  final Column columnDef;

  BeforeHeaderRowCellDestroy(Object sender, this.node, this.columnDef)
      : super(sender: sender);
}

class BeforeMoveRows extends EventData {
  List<int> rows;
  int insertBefore;

  BeforeMoveRows(Object sender, {this.rows, this.insertBefore})
      : super(sender: sender);
}

class CellCssStylesChanged extends EventData {
  final String key;
  final Map<int, Map<String, String>> hash;

  CellCssStylesChanged(Object sender, this.key, {this.hash: null})
      : super(sender: sender);
}

class CellRangeSelected extends EventData {
  final Range range;

  CellRangeSelected(Object sender, this.range) : super(sender: sender);
}

class Click extends EventData {
  final Cell cell;
  @override
  dom.MouseEvent get causedBy => super.causedBy;

  Click(Object sender, this.cell, {dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

class ColumnsResized extends EventData {
  ColumnsResized(Object sender) : super(sender: sender);
}

class ColumnsReordered extends EventData {
  ColumnsReordered(Object sender) : super(sender: sender);
}

class ContextMenu extends EventData {
  final Cell cell;
  @override
  dom.MouseEvent get causedBy => super.causedBy;

  ContextMenu(Object sender, this.cell, {dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

class CopyCancelled extends EventData {
  final List<Range> copiedRanges;

  CopyCancelled(Object sender, this.copiedRanges) : super(sender: sender);
}

class CopyCells extends EventData {
  final List<Range> ranges;

  CopyCells(Object sender, this.ranges) : super(sender: sender);
}

class DoubleClick extends EventData {
  final Cell cell;
  @override
  dom.MouseEvent get causedBy => super.causedBy;

  DoubleClick(Object sender, this.cell, {dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

//// TODO do we really need different event data containers for DragXxx and CustomDragXxx events?
//// at least these carry the additional cDrag.CustomDrag container
//class CustomDrag extends EventData {
//  dom.MouseEvent get causedBy => super.causedBy;
//  cdrag.CustomDrag causedByCustomDrag;
//  dom.Element guide;
//  dom.Element selectionProxy;
//  int insertBefore;
//  List<int> selectedRows;
//  bool canMove;
//  String mode;
//
//  CustomDrag(Object sender, {this.guide, this.selectionProxy, this.insertBefore,
//    this.selectedRows, this.canMove, this.mode, cdrag.CustomDrag causedByCustomDrag}) : super(sender: sender,
//      causedBy: causedByCustomDrag.causedBy) {
//    this.causedByCustomDrag = causedByCustomDrag;
//  }
//}
//
//class CustomDragEnd extends EventData {
//  dom.MouseEvent get causedBy => super.causedBy;
//  cdrag.CustomDrag causedByCustomDrag;
//  dom.Element guide;
//  dom.Element selectionProxy;
//  bool canMove;
//  List<int> selectedRows;
//  int insertBefore;
//  String mode ;
//
//  CustomDragEnd(Object sender, {this.selectedRows, this.insertBefore,
//      this.guide, this.selectionProxy, this.canMove, this.mode,
//          cdrag.CustomDrag causedByCustomDrag}) : super(sender: sender,
//      causedBy: causedByCustomDrag.causedBy) {
//    this.causedByCustomDrag = causedByCustomDrag;
//  }
//}
//
//class CustomDragStart extends EventData {
//  dom.MouseEvent get causedBy => super.causedBy;
//  cdrag.CustomDrag causedByCustomDrag;
//  List<int> selectedRows;
//  int insertBefore;
//  dom.Element selectionProxy;
//  dom.Element guide;
//
//  CustomDragStart(Object sender, {this.selectedRows, this.insertBefore,
//    this.selectionProxy, this.guide, cdrag.CustomDrag causedByCustomDrag})
//    : super(sender: sender,
//      causedBy: causedByCustomDrag.causedBy){
//        this.causedByCustomDrag = causedByCustomDrag;
//      }
//}

class Drag extends EventData {
//  final Map dd;
  @override
  dom.MouseEvent get causedBy => super.causedBy;
  dom.Element guide;
  dom.Element selectionProxy;
  int insertBefore;
  List<int> selectedRows;
  bool canMove;
  String mode;

  Drag(Object sender,
      {/*this.dd,*/ this.guide,
      this.selectionProxy,
      this.insertBefore,
      this.selectedRows,
      this.canMove,
      this.mode,
      dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

class DragEnd extends EventData {
  //final Map dd;
  @override
  dom.MouseEvent get causedBy => super.causedBy;

  dom.Element guide;
  dom.Element selectionProxy;
  bool canMove;
  List<int> selectedRows;
  int insertBefore;
  String mode;

  DragEnd(Object sender,
      {this.selectedRows,
      this.insertBefore,
      /*this.dd,*/ this.guide,
      this.selectionProxy,
      this.canMove,
      this.mode,
      dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

class DragEnter extends EventData {
  @override
  dom.MouseEvent get causedBy => super.causedBy;

  DragEnter(Object sender, {dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

class DragLeave extends EventData {
  @override
  dom.MouseEvent get causedBy => super.causedBy;

  DragLeave(Object sender, {dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

class DragOver extends EventData {
  @override
  dom.MouseEvent get causedBy => super.causedBy;

  DragOver(Object sender, {dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

class Drop extends EventData {
  @override
  dom.MouseEvent get causedBy => super.causedBy;

  Drop(Object sender, {dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

// TODO this was for a jQuery specific event we don't have
//class DragInit extends EventData {
//  final int dd;
//  dom.MouseEvent get causedBy => super.causedBy;
//
//  DragInit(Object sender, {this.dd, dom.MouseEvent causedBy}) : super(sender: sender,
//      causedBy: causedBy);
//}

class DragStart extends EventData {
  @override
  dom.MouseEvent get causedBy => super.causedBy;
  List<int> selectedRows;
  int insertBefore;
  dom.Element selectionProxy;
  dom.Element guide;

  DragStart(Object sender,
      {this.selectedRows,
      this.insertBefore,
      this.selectionProxy,
      this.guide,
      dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

class HeaderCellRendered extends EventData {
  final dom.Element node;
  final Column columnDef;

  HeaderCellRendered(Object sender, this.node, this.columnDef)
      : super(sender: sender);
}

class HeaderClick extends EventData {
  final Column column;
  @override
  dom.MouseEvent get causedBy => super.causedBy;

  HeaderClick(Object sender, this.column, {dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

class HeaderContextMenu extends EventData {
  final Column column;
  @override
  dom.MouseEvent get causedBy => super.causedBy;

  HeaderContextMenu(Object sender, this.column, {dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

class HeaderMouseEnter extends EventData {
  final Column data;
  @override
  dom.MouseEvent get causedBy => super.causedBy;

  HeaderMouseEnter(Object sender, this.data, {dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

class HeaderMouseLeave extends EventData {
  final String data;
  @override
  dom.MouseEvent get causedBy => super.causedBy;

  HeaderMouseLeave(Object sender, this.data, {dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

class HeaderRowCellRendered extends EventData {
  final dom.Element node;
  final Column columnDef;

  HeaderRowCellRendered(Object sender, this.node, this.columnDef)
      : super(sender: sender);
}

class KeyDown extends EventData {
  final Cell cell;
  @override
  dom.KeyboardEvent get causedBy => super.causedBy;

  KeyDown(Object sender, this.cell, {dom.KeyboardEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

class MouseEnter extends EventData {
  @override
  dom.MouseEvent get causedBy => super.causedBy;

  MouseEnter(Object sender, {dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

class MouseLeave extends EventData {
  @override
  dom.MouseEvent get causedBy => super.causedBy;

  MouseLeave(Object sender, {dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

class MoveRows extends EventData {
  @override
  dom.MouseEvent get causedBy => super.causedBy;

  List<int> rows;
  int insertBefore;

  MoveRows(Object sender,
      {this.rows, this.insertBefore, dom.MouseEvent causedBy})
      : super(sender: sender, causedBy: causedBy);
}

class PagingInfoChanged extends EventData {
  final PagingInfo pagingInfo;

  PagingInfoChanged(Object sender, {this.pagingInfo}) : super(sender: sender);
}

class PasteCells extends EventData {
  final List<Range> from;
  final List<Range> to;

  PasteCells(Object sender, this.from, this.to) : super(sender: sender);
}

class Scroll extends EventData {
  final int scrollLeft;
  final int scrollTop;

  Scroll(Object sender, {this.scrollLeft: 0, this.scrollTop: 0})
      : super(sender: sender);
}

class SelectedRangesChanged extends EventData {
  final List<Range> ranges;

  SelectedRangesChanged(Object sender, this.ranges) : super(sender: sender);
}

class SelectedRowIdsChanged extends EventData {
  final BwuDatagrid grid; // TODO isn't this the sender (probably not when sent from DataView)
  // the id needs to be a valid map key
  final List ids;

  SelectedRowIdsChanged(Object sender, this.grid, this.ids)
      : super(sender: sender);
}

class SelectedRowsChanged extends EventData {
  final List<int> rows;
  @override
  dom.CustomEvent get causedBy => super.causedBy;

  SelectedRowsChanged(Object sender, this.rows, dom.CustomEvent causedBy)
      : super(sender: sender, causedBy: causedBy);
}

class Sort extends EventData {
  final bool multiColumnSort;
  final Column sortColumn;
  final Map<Column, bool> sortColumns;
  final bool sortAsc;

  Sort(Object sender, this.multiColumnSort, this.sortColumn, this.sortColumns,
      this.sortAsc, dom.Event causedBy)
      : super(sender: sender, causedBy: causedBy);
}

class RowCountChanged extends EventData {
  final int oldCount;
  final int newCount;
  RowCountChanged(Object sender, {this.oldCount, this.newCount})
      : super(sender: sender);
}

class RowsChanged extends EventData {
  final List<int> changedRows;

  RowsChanged(Object sender, {this.changedRows}) : super(sender: sender);
}

class ValidationError extends EventData {
  final Editor editor;
  final dom.HtmlElement cellNode;
  final ValidationResult validationResults;
  final Cell cell;
  final Column column;

  ValidationError(Object sender,
      {this.editor,
      this.cellNode,
      this.validationResults,
      this.cell,
      this.column})
      : super(sender: sender);
}

class ViewportChanged extends EventData {
  ViewportChanged(Object sender) : super(sender: sender);
}

part of bwu_datagrid.core;

abstract class Events {
  static const EventType<ActiveCellChanged> activeCellChanged =
      const EventType<ActiveCellChanged>('bwu-active-cell-changed');
  @Deprecated('Use activeCellChanged')
  // ignore: constant_identifier_names
  static const EventType<ActiveCellChanged> ACTIVE_CELL_CHANGED =
      activeCellChanged;

  static const EventType<ActiveCellPositionChanged> activeCellPositionChanged =
      const EventType<ActiveCellPositionChanged>(
          'bwu-active-cell-position-changed');
  @Deprecated('Use activeCellPositionChanged')
  static const EventType<ActiveCellPositionChanged>
      // ignore: constant_identifier_names
      ACTIVE_CELL_POSITION_CHANGED = activeCellPositionChanged;

  static const EventType<AddNewRow> addNewRow =
      const EventType<AddNewRow>('bwu-add-new-row');

  @Deprecated('Use addNewRow')
  // ignore: constant_identifier_names
  static const EventType<AddNewRow> ADD_NEW_ROW = addNewRow;

  static const EventType<Attached> attached =
      const EventType<Attached>('bwu-attached');

  @Deprecated('Use attached')
  // ignore: constant_identifier_names
  static const EventType<Attached> ATTACHED = attached;

  static const EventType<BeforeCellEditorDestroy> beforeCellEditorDestroy =
      const EventType<BeforeCellEditorDestroy>(
          'bwu-before-cell-editor-destroy');

  @Deprecated('Use beforeCellEditorDestroy')
  // ignore: constant_identifier_names
  static const EventType<BeforeCellEditorDestroy> BEFORE_CELL_EDITOR_DESTROY =
      beforeCellEditorDestroy;

  static const EventType<BeforeCellRangeSelected> beforeCellRangeSelected =
      const EventType<BeforeCellRangeSelected>(
          'bwu-before-cell-range-selected');

  @Deprecated('Use beforeCellRangeSelected')
  // ignore: constant_identifier_names
  static const EventType<BeforeCellRangeSelected> BEFORE_CELL_RANGE_SELECTED =
      beforeCellRangeSelected;

  static const EventType<BeforeDestroy> beforeDestroy =
      const EventType<BeforeDestroy>('bwu-before-destroy');

  @Deprecated('Use beforeDestroy')
  // ignore: constant_identifier_names
  static const EventType<BeforeDestroy> BEFORE_DESTROY = beforeDestroy;

  static const EventType<BeforeEditCell> beforeEditCell =
      const EventType<BeforeEditCell>('bwu-before-edit-cell');

  @Deprecated('Use beforeEditCell')
  // ignore: constant_identifier_names
  static const EventType<BeforeEditCell> BEFORE_EDIT_CELL = beforeEditCell;

  static const EventType<BeforeHeaderCellDestroy> beforeHeaderCellDestroy =
      const EventType<BeforeHeaderCellDestroy>(
          'bwu-before-header-cell-destroy');

  @Deprecated('Use beforeHeaderCellDestroy')
  // ignore: constant_identifier_names
  static const EventType<BeforeHeaderCellDestroy> BEFORE_HEADER_CELL_DESTROY =
      beforeHeaderCellDestroy;

  static const EventType<BeforeHeaderRowCellDestroy>
      beforeHeaderRowCellDestroy = const EventType<BeforeHeaderRowCellDestroy>(
          'bwu-before-header-row-cell-destroy');

  @Deprecated('Use beforeHeaderRowCellDestroy')
  static const EventType<BeforeHeaderRowCellDestroy>
      // ignore: constant_identifier_names
      BEFORE_HEADER_ROW_CELL_DESTROY = beforeHeaderRowCellDestroy;

  static const EventType<BeforeMoveRows> beforeMoveRows =
      const EventType<BeforeMoveRows>('bwu-before-move-rows');

  @Deprecated('Use beforeMoveRows')
  // ignore: constant_identifier_names
  static const EventType<BeforeMoveRows> BEFORE_MOVE_ROWS = beforeMoveRows;

  static const EventType<CellChange> cellChange =
      const EventType<CellChange>('bwu-cell-changed');

  @Deprecated('Use cellChange')
  // ignore: constant_identifier_names
  static const EventType<CellChange> CELL_CHANGE = cellChange;

  static const EventType<CellRangeSelected> cellRangeSelected =
      const EventType<CellRangeSelected>('bwu-cell-range-selected');
  @Deprecated('Use cellRangeSelected')
  // ignore: constant_identifier_names
  static const EventType<CellRangeSelected> CELL_RANGE_SELECTED =
      cellRangeSelected;

  static const EventType<CellCssStylesChanged> cellCssStylesChanged =
      const EventType<CellCssStylesChanged>('bwu-cell-css-styles-changed');

  @Deprecated('Use cellCssStylesChanged')
  // ignore: constant_identifier_names
  static const EventType<CellCssStylesChanged> CELL_CSS_STYLES_CHANGED =
      cellCssStylesChanged;

  static const EventType<Click> click = const EventType<Click>('bwu-click');

  @Deprecated('Use click')
  // ignore: constant_identifier_names
  static const EventType<Click> CLICK = click;

  static const EventType<ColumnsReordered> columnsReordered =
      const EventType<ColumnsReordered>('bwu-columns-reordered');

  @Deprecated('Use columnsReordered')
  // ignore: constant_identifier_names
  static const EventType<ColumnsReordered> COLUMNS_REORDERED = columnsReordered;

  static const EventType<ColumnsResized> columnsResized =
      const EventType<ColumnsResized>('bwu-columns-resized');

  @Deprecated('Use columnsResized')
  // ignore: constant_identifier_names
  static const EventType<ColumnsResized> COLUMNS_RESIZED = columnsResized;

  static const EventType<ContextMenu> contextMenu =
      const EventType<ContextMenu>('bwu-context-menu');

  @Deprecated('Use contextMenu')
  // ignore: constant_identifier_names
  static const EventType<ContextMenu> CONTEXT_MENU = contextMenu;

  static const EventType<CopyCancelled> copyCancelled =
      const EventType<CopyCancelled>('bwu-copy-cancelled');

  @Deprecated('Use copyCancelled')
  // ignore: constant_identifier_names
  static const EventType<CopyCancelled> COPY_CANCELLED = copyCancelled;

  static const EventType<CopyCells> copyCells =
      const EventType<CopyCells>('bwu-copy-cells');

  @Deprecated('Use copyCells')
  // ignore: constant_identifier_names
  static const EventType<CopyCells> COPY_CELLS = copyCells;

  static const EventType<DoubleClick> doubleClick =
      const EventType<DoubleClick>('bwu-double-click');

  @Deprecated('Use doubleClick')
  // ignore: constant_identifier_names
  static const EventType<DoubleClick> DOUBLE_CLICK = doubleClick;

//  static const EventType<CustomDrag> CUSTOM_DRAG = const EventType<CustomDrag>('bwu-custom-drag');
//
//  static const EventType<CustomDragEnd> CUSTOM_DRAG_END = const EventType<CustomDragEnd>('bwu-custom-drag-end');
//
//  static const  EventType<CustomDragStart> CUSTOM_DRAG_START = const EventType<CustomDragStart>('bwu-custom-drag-start');
//
  static const EventType<Drag> drag = const EventType<Drag>('bwu-drag');

  @Deprecated('Use drag')
  // ignore: constant_identifier_names
  static const EventType<Drag> DRAG = drag;

  static const EventType<DragEnd> dragEnd =
      const EventType<DragEnd>('bwu-drag-end');

  @Deprecated('Use dragEnd')
  // ignore: constant_identifier_names
  static const EventType<DragEnd> DRAG_END = dragEnd;

  static const EventType<DragEnter> dragEnter =
      const EventType<DragEnter>('bwu-drag-enter');

  @Deprecated('Use dragEnter')
  // ignore: constant_identifier_names
  static const EventType<DragEnter> DRAG_ENTER = dragEnter;

  static const EventType<DragLeave> dragLeave =
      const EventType<DragLeave>('bwu-drag-leave');

  @Deprecated('Use dragLeave')
  // ignore: constant_identifier_names
  static const EventType<DragLeave> DRAG_LEAVE = dragLeave;

  static const EventType<DragOver> dragOver =
      const EventType<DragOver>('bwu-drag-over');

  @Deprecated('Use dragOver')
  // ignore: constant_identifier_names
  static const EventType<DragOver> DRAG_OVER = dragOver;

  static const EventType<Drop> drop = const EventType<Drop>('bwu-drop');

  @Deprecated('Use drop')
  // ignore: constant_identifier_names
  static const EventType<Drop> DROP = drop;

  // TODO this is a jQuery specific event, there is no replacement for it
  //static const DRAG_INIT = const EventType<DragInit>('bwu-drag-init');

  static const EventType<DragStart> dragStart =
      const EventType<DragStart>('bwu-drag-start');

  @Deprecated('Use dragStart')
  // ignore: constant_identifier_names
  static const EventType<DragStart> DRAG_START = dragStart;

  static const EventType<HeaderCellRendered> headerCellRendered =
      const EventType<HeaderCellRendered>('bwu-header-cell-rendered');

  @Deprecated('Use headerCellRenderer')
  // ignore: constant_identifier_names
  static const EventType<HeaderCellRendered> HEADER_CELL_RENDERED =
      headerCellRendered;

  static const EventType<HeaderClick> headerClick =
      const EventType<HeaderClick>('bwu-header-click');

  @Deprecated('Use headerClick')
  // ignore: constant_identifier_names
  static const EventType<HeaderClick> HEADER_CLICK = headerClick;

  static const EventType<HeaderContextMenu> headerContextMenu =
      const EventType<HeaderContextMenu>('bwu-header-context-menu');

  @Deprecated('Use headerContextMenu')
  // ignore: constant_identifier_names
  static const EventType<HeaderContextMenu> HEADER_CONTEX_MENU =
      headerContextMenu;

  static const EventType<HeaderMouseEnter> headerMouseEnter =
      const EventType<HeaderMouseEnter>('bwu-header-mouse-enter');

  @Deprecated('Use headerMouseEnter')
  // ignore: constant_identifier_names
  static const EventType<HeaderMouseEnter> HEADER_MOUSE_ENTER =
      headerMouseEnter;

  static const EventType<HeaderMouseLeave> headerMouseLeave =
      const EventType<HeaderMouseLeave>('bwu-header-mouse-leave');

  @Deprecated('Use headerMouseLeave')
  // ignore: constant_identifier_names
  static const EventType<HeaderMouseLeave> HEADER_MOUSE_LEAVE =
      headerMouseLeave;

  static const EventType<HeaderRowCellRendered> headerRowCellRendered =
      const EventType<HeaderRowCellRendered>('bwu-header-row-cell-rendered');

  @Deprecated('Use headerRowCellRenderer')
  // ignore: constant_identifier_names
  static const EventType<HeaderRowCellRendered> HEADER_ROW_CELL_RENDERED =
      headerRowCellRendered;

  static const EventType<KeyDown> keyDown =
      const EventType<KeyDown>('bwu-key-down');

  @Deprecated('Use keyDown')
  // ignore: constant_identifier_names
  static const EventType<KeyDown> KEY_DOWN = keyDown;

  static const EventType<MouseEnter> mouseEnter =
      const EventType<MouseEnter>('bwu-mouse-enter');

  @Deprecated('Use mouseEnter')
  // ignore: constant_identifier_names
  static const EventType<MouseEnter> MOUSE_ENTER = mouseEnter;

  static const EventType<MouseLeave> mouseLeave =
      const EventType<MouseLeave>('bwu-mouse-leave');

  @Deprecated('Use mouseLeave')
  // ignore: constant_identifier_names
  static const EventType<MouseLeave> MOUSE_LEAVE = mouseLeave;

  static const EventType<MoveRows> moveRows =
      const EventType<MoveRows>('bwu-move-rows');

  @Deprecated('Use moveRows')
  // ignore: constant_identifier_names
  static const EventType<MoveRows> MOVE_ROWS = moveRows;

  static const EventType<PagingInfoChanged> pagingInfoChanged =
      const EventType<PagingInfoChanged>('bwu-paging-info-changed');

  @Deprecated('Use pagingInfoChanged')
  // ignore: constant_identifier_names
  static const EventType<PagingInfoChanged> PAGING_INFO_CHANGED =
      pagingInfoChanged;

  static const EventType<PasteCells> pasteCells =
      const EventType<PasteCells>('bwu-paste-cells');

  @Deprecated('Use pasteCells')
  // ignore: constant_identifier_names
  static const EventType<PasteCells> PASTE_CELLS = pasteCells;

  static const EventType<RowsChanged> rowsChanged =
      const EventType<RowsChanged>('bwu-rows-changed');

  @Deprecated('Use rowsChanged')
  // ignore: constant_identifier_names
  static const EventType<RowsChanged> ROWS_CHANGED = rowsChanged;

  static const EventType<RowCountChanged> rowCountChanged =
      const EventType<RowCountChanged>('bwu-row-count-changed');

  @Deprecated('Use rowCountChanged')
  // ignore: constant_identifier_names
  static const EventType<RowCountChanged> ROW_COUNT_CHANGED = rowCountChanged;

  static const EventType<Scroll> scroll = const EventType<Scroll>('bwu-scroll');

  @Deprecated('Use scroll')
  // ignore: constant_identifier_names
  static const EventType<Scroll> SCROLL = scroll;

  static const EventType<SelectedRangesChanged> selectedRangesChanged =
      const EventType<SelectedRangesChanged>('bwu-selected-ranges-changed');

  @Deprecated('Use selectedRangesChanged')
  // ignore: constant_identifier_names
  static const EventType<SelectedRangesChanged> SELECTED_RANGES_CHANGED =
      selectedRangesChanged;

  static const EventType<SelectedRowIdsChanged> selectedRowIdsChanged =
      const EventType<SelectedRowIdsChanged>('selected-row-ids-changed');

  @Deprecated('Use selectedRowIdsChanged')
  // ignore: constant_identifier_names
  static const EventType<SelectedRowIdsChanged> SELECTED_ROW_IDS_CHANGED =
      selectedRowIdsChanged;

  static const EventType<SelectedRowsChanged> selectedRowsChanged =
      const EventType<SelectedRowsChanged>('bwu-selected-rows-changed');

  @Deprecated('Use selectedRowsChanged')
  // ignore: constant_identifier_names
  static const EventType<SelectedRowsChanged> SELECTED_ROWS_CHANGED =
      selectedRowsChanged;

  static const EventType<Sort> sort = const EventType<Sort>('bwu-sort');

  @Deprecated('Use sort')
  // ignore: constant_identifier_names
  static const EventType<Sort> SORT = sort;

  static const EventType<ValidationError> validationError =
      const EventType<ValidationError>('bwu-validation-error');

  @Deprecated('Use validationError')
  // ignore: constant_identifier_names
  static const EventType<ValidationError> VALIDATION_ERROR = validationError;

  static const EventType<ViewportChanged> viewportChanged =
      const EventType<ViewportChanged>('bwu-viewport-changed');

  @Deprecated('Use viewportChanged')
  // ignore: constant_identifier_names
  static const EventType<ViewportChanged> VIEWPORT_CHANGED = viewportChanged;
}

/// An event object for passing data to event handlers and letting them control propagation.
/// <p>This is pretty much identical to how W3C and jQuery implement events.</p>
/// @class EventData
/// @constructor
class EventData {
  final Object sender;
  final dom.Event _causedBy;

  dom.Event get causedBy => _causedBy;
  Map<String, dynamic> detail = {};
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
  final BwuDatagrid grid;

  // TODO isn't this the sender (probably not when sent from DataView)
  // the id needs to be a valid map key
  final List<dynamic> ids;

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

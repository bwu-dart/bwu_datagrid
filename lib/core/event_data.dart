part of bwu_dart.bwu_datagrid.core;

abstract class Events {
  static const HEADER_CELL_RENDERED = const EventType<HeaderCellRendered>(
      'header-cell-rendered');
  static const HEADER_ROW_CELL_RENDERED =
      const EventType<HeaderRowCellRendered>('header-row-cell-rendered');
  static const BEFORE_HEADER_CELL_DESTROY =
      const EventType<BeforeHeaderCellDestroy>('before-header-cell-destroy');
  static const SORT = const EventType<Sort>('sort');
  static const COLUMNS_RESIZED = const EventType<ColumnsResized>(
      'columns-resized');
  static const COLUMNS_REORDERED = const EventType<ColumnsReordered>(
      'columns-reordered');
  static const SELECTED_ROWS_CHANGED = const EventType<SelectedRowsChanged>(
      'selected-rows-changed');
  static const VIEWPORT_CHANGED = const EventType<ViewportChanged>(
      'viewport-changed');
  static const CELL_CSS_STYLES_CHANGED = const EventType<CellCssStylesChanged>(
      'cell-css-styles-changed');
  static const HEADER_MOUSE_ENTER = const EventType<HeaderMouseEnter>(
      'header-mouse-enter');
  static const HEADER_MOUSE_LEAVE = const EventType<HeaderMouseLeave>(
      'header-mouse-leave');
  static const HEADER_CONTEX_MENU = const EventType<HeaderContextMenu>(
      'header-context-menu');
  static const HEADER_CLICK = const EventType<HeaderClick>('header-click');
  static const ACTIVE_CELL_CHANGED = const EventType<ActiveCellChanged>(
      'active-cell-changed');
  static const BEFORE_CELL_EDITOR_DESTROY =
      const EventType<BeforeCellEditorDestroy>('before-cell-editor-destroy');
  static const BEFORE_EDIT_CELL = const EventType<BeforeEditCell>(
      'before-edit-cell');
  static const ACTIVE_CELL_POSITION_CHANGED =
      const EventType<ActiveCellPositionChanged>('active-cell-position-changed');
  static const CELL_CHANGED = const EventType<CellChanged>('cell-changed');
  static const ADD_NEW_ROW = const EventType<AddNewRow>('add-new-row');
  static const VALIDATION_ERROR = const EventType<ValidationError>(
      'validation-error');
  static const BEFORE_DESTROY = const EventType<BeforeDestroy>(
      'before-destroy');
  static const SCROLL = const EventType<Scroll>(
      'scroll');
  static const DRAG_INIT = const EventType<DragInit>(
      'drag-init');
  static const CLICK = const EventType<Click>('click');
  static const DOUBLE_CLICK = const EventType<DoubleClick>('double-click');
  static const KEY_DOWN = const EventType<KeyDown>('key-down');
  static const MOUSE_ENTER = const EventType<MouseEnter>('mouse-enter');
  static const MOUSE_LEAVE = const EventType<MouseLeave>('mouse-leave');
}

/***
 * An event object for passing data to event handlers and letting them control propagation.
 * <p>This is pretty much identical to how W3C and jQuery implement events.</p>
 * @class EventData
 * @constructor
 */

class EventData {
  var sender;
  Map detail;

  bool _isPropagationStopped = false;
  bool _isImmediatePropagationStopped = false;

  /***
   * Returns whether stopPropagation was called on this event object.
   * @method isPropagationStopped
   * @return {Boolean}
   */
  bool get isPropagationStopped => _isPropagationStopped;

  /***
   * Stops event from propagating up the DOM tree.
   * @method stopPropagation
   */
  void stopPropagation() {
    _isPropagationStopped = true;
  }

  /***
   * Returns whether stopImmediatePropagation was called on this event object.\
   * @method isImmediatePropagationStopped
   * @return {Boolean}
   */
  bool get isImmediatePropagationStopped => _isImmediatePropagationStopped;

  /***
   * Prevents the rest of the handlers from being executed.
   * @method stopImmediatePropagation
   */
  void stopImmediatePropagation() {
    _isImmediatePropagationStopped = true;
  }

  EventData({this.sender, this.detail});
}

class BeforeHeaderCellDestroy extends EventData {
  dom.HtmlElement node;
  Column columnDef;

  BeforeHeaderCellDestroy(sender, dom.HtmlElement node, Column columnDef) :
      super(sender: sender, detail: {
        'node': node,
        'column': columnDef
      }) {
    this.node = node;
    this.columnDef = columnDef;
  }
}

class BeforeDestroy extends EventData {

  BeforeDestroy(sender) : super(sender: sender, detail: {});
}

class HeaderCellRendered extends EventData {
  dom.HtmlElement node;
  Column columnDef;

  HeaderCellRendered(sender, dom.HtmlElement node, Column columnDef) : super(
      sender: sender, detail: {
        'node': node,
        'column': columnDef
      }) {
    this.node = node;
    this.columnDef = columnDef;
  }
}

class HeaderRowCellRendered extends EventData {

  HeaderRowCellRendered(sender) : super(sender: sender, detail: {});
}

class Sort extends EventData {
  bool multiColumnSort;
  Column sortColumn;
  Map<Column,bool> sortColumns;
  bool sortAsc;
  dom.Event causedBy;

  Sort(sender, bool multiColumnSort, Column sortColumn, Map<Column,bool> sortColumns, bool sortAsc, dom.Event
      causedBy)
      : super(sender: sender, detail: {
        'multiColumnSort': multiColumnSort,
        'sortColumn': sortColumn,
        'sortAsc': sortAsc,
        'causedBy': causedBy
      }) {
    this.multiColumnSort = multiColumnSort;
    this.sortColumn = sortColumn;
    this.sortAsc = sortAsc;
    this.causedBy = causedBy;
  }
}

class ColumnsResized extends EventData {

  ColumnsResized(sender) : super(sender: sender, detail: {});
}

class ColumnsReordered extends EventData {

  ColumnsReordered(sender) : super(sender: sender, detail: {});
}

class SelectedRowsChanged extends EventData {
  List<int> rows;
  dom.CustomEvent causedBy;

  SelectedRowsChanged(sender, rows, causedBy) : super(sender: sender, detail: {'rows': rows, 'causedBy': causedBy}) {
    this.rows = rows;
    this.causedBy = causedBy;
  }
}

class ViewportChanged extends EventData {

  ViewportChanged(sender) : super(sender: sender, detail: {});
}

class CellCssStylesChanged extends EventData {
  String key;
  String hash;

  CellCssStylesChanged(sender, String key, {String hash}) : super(sender: sender, detail: {'key': key, 'hash': hash}) {
    this.key = key;
    this.hash = hash;
  }
}

class HeaderMouseEnter extends EventData {
  Column data;
  dom.MouseEvent causedBy;
  HeaderMouseEnter(sender, Column data, {dom.MouseEvent causedBy}) : super(sender: sender, detail: {'data': data, 'causedBy': causedBy}) {
    this.data = data;
    this.causedBy = causedBy;
  }
}

class HeaderMouseLeave extends EventData {
  String data;
  HeaderMouseLeave(sender, String data, {dom.MouseEvent causedBy}) : super(sender: sender, detail: {'data': data, 'causedBy': causedBy}) {
    this.data = data;
  }
}

class HeaderContextMenu extends EventData {
  Column column;
  HeaderContextMenu(sender, Column column, {dom.MouseEvent causedBy}) : super(sender: sender, detail: {'column': column, 'causedBy': causedBy}) {
    this.column = column;
  }
}

class HeaderClick extends EventData {
  Column column;
  HeaderClick(sender, Column column, {dom.MouseEvent causedBy}) : super(sender: sender, detail: {'column': column, 'causedBy': causedBy}) {
    this.column = column;
  }
}

class ActiveCellChanged extends EventData {
  Cell cell; // these members should all be final and the constructor const;

  ActiveCellChanged(sender, Cell cell) : super(sender: sender, detail: {'cell': cell}) {
    this.cell = cell;
  }
}

class BeforeCellEditorDestroy extends EventData {
  Editor editor;
  BeforeCellEditorDestroy(sender, Editor editor) : super(sender: sender, detail: {'editor': editor}) {
    this.editor = editor;
  }
}

class BeforeEditCell extends EventData {
  Cell cell;
  Item item;
  Column column;
  BeforeEditCell(sender, {Cell cell, Item item, Column column}) : super(sender: sender, detail: {'cell': cell, 'item': item, 'column':column}) {
    this.cell = cell;
    this.item = item;
    this.column = column;
  }
}

class ActiveCellPositionChanged extends EventData {

  ActiveCellPositionChanged(sender) : super(sender: sender, detail: {});
}

class CellChanged extends EventData {
  Cell cell;
  Item item;
  CellChanged(sender, Cell cell, Item item) : super(sender: sender, detail: {'cell': cell, 'item': item}) {
    this.cell = cell;
    this.item = item;
  }
}

class AddNewRow extends EventData {
  Item item;
  Column column;
  AddNewRow(sender, Item item, Column column) : super(sender: sender, detail: {'item': item, 'column': column}) {
    this.item = item;
    this.column = column;
  }
}

class ValidationError extends EventData {
  Editor editor;
  dom.HtmlElement cellNode;
  ValidationResults validationResults;
  Cell cell;
  Column column;
  ValidationError(sender, {Editor editor,
    dom.HtmlElement cellNode,
    ValidationResults validationResults,
    Cell cell,
    Column column}) : super(sender: sender, detail: {
      'editor': editor,
      'cellNode': cellNode,
      'validatoinResults': validationResults,
      'cell': cell,
      'column': column
    });
}

class Scroll extends EventData {
  int scrollLeft;
  int scrollTop;

  Scroll(sender, {int scrollLeft, int scrollTop}) : super(sender: sender, detail: {'scrollLeft': scrollLeft, 'scrollTop': scrollTop}) {
    this.scrollLeft = scrollLeft;
    this.scrollTop = scrollTop;
  }
}

class DragInit extends EventData {
  int dd;
  dom.MouseEvent causedBy;

  DragInit(sender, {int dd, dom.MouseEvent causedBy}) : super(sender: sender, detail: {'dd': dd, 'causedBy': causedBy}) {
    this.dd = dd;
    this.causedBy = causedBy;
  }
}

class Click extends EventData {
  Cell cell;
  dom.MouseEvent causedBy;

  Click(sender, Cell cell,  {dom.MouseEvent causedBy}) : super(sender: sender, detail: {'cell': cell, 'causedBy': causedBy}) {
    this.cell = cell;
    this.causedBy = causedBy;
  }
}

class DoubleClick extends EventData {
  Cell cell;
  dom.MouseEvent causedBy;

  DoubleClick(sender, Cell cell,  {dom.MouseEvent causedBy}) : super(sender: sender, detail: {'cell': cell, 'causedBy': causedBy}) {
    this.cell = cell;
    this.causedBy = causedBy;
  }
}

class KeyDown extends EventData {
  Cell cell;
  dom.KeyboardEvent causedBy;

  KeyDown(sender, Cell cell, {dom.KeyboardEvent causedBy}) : super(sender: sender, detail: {'cell': cell, 'causedBy': causedBy}) {
    this.cell = cell;
    this.causedBy = causedBy;
  }
}

class MouseEnter extends EventData {
  dom.MouseEvent causedBy;

  MouseEnter(sender,  {dom.MouseEvent causedBy}) : super(sender: sender, detail: {'causedBy': causedBy}) {
    this.causedBy = causedBy;
  }
}

class MouseLeave extends EventData {
  dom.MouseEvent causedBy;

  MouseLeave(sender,  {dom.MouseEvent causedBy}) : super(sender: sender, detail: {'causedBy': causedBy}) {
    this.causedBy = causedBy;
  }
}

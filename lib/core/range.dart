part of bwu_dart.bwu_datagrid.core;

/***
 * A structure containing a range of cells.
 * @class Range
 * @constructor
 * @param fromRow - Starting row.
 * @param fromCell -  Starting cell.
 * @param toRow - Ending row. Defaults to [_fromRow].
 * @param toCell - Ending cell. Defaults to [_fromCell].
 */
class Range {
  int _fromRow;
  int _fromCell;
  int _toRow;
  int _toCell;

  Range(this._fromRow, this._fromCell, {toRow: null, toCell: null}) {
    if (toRow != null) {
      _toRow = toRow;
    } else {
      _toRow = _fromRow;
    }
    if (toCell != null) {
      _toCell = toCell;
    } else {
      _toCell = _fromCell;
    }
  }

  int get fromRow => math.min(_fromRow, _toRow);

  int get toRow => math.max(_fromRow, _toRow);

  int get fromCell => math.min(_fromCell, _toCell);

  int get toCell => math.max(_fromCell, _toCell);

  set toCell(int cell) => _toCell = cell;
  set toRow(int row) => _toRow = row;

  /***
   * Returns whether a range represents a single row.
   */
  bool get isSingleRow => _fromRow == _toRow;

  /***
   * Returns whether a range represents a single cell.
   */
  bool get isSingleCell => _fromRow == _toRow && _fromCell == _toCell;

  /***
   * Returns whether a range contains a given cell.
   */
  bool contains(int row, int cell) {
    return row >= _fromRow && row <= _toRow && cell >= _fromCell && cell <=
        _toCell;
  }

  @override
  String toString() {
    if (isSingleCell) {
      return '($_fromRow:$_fromCell)';
    } else {
      return '($_fromRow:$_fromCell - $_toRow:$_toCell)';
    }
  }
}

abstract class ItemBase {
  Map _values = {};
  dynamic operator[](String key) {
    return _values[key];
  }
  void operator[]=(String key, value) {
    _values[key] = value;
  }
}

/***
 * A base class that all special / non-data rows (like Group and GroupTotals) derive from.
 */
abstract class NonDataItem extends ItemBase {}

/***
 * Information about a group of rows.
 */
class Group extends NonDataItem {
  /**
   * Grouping level, starting with 0.
   */
  num level = 0;

  /***
   * Number of rows in the group.
   */
  int get count => rows == null ? 0 : rows.length;

  /***
   * Grouping value.
   */
  dynamic value; // TODO should it be made generic?

  /***
   * Formatted display value of the group.
   */
  dom.Node title;

  /***
   * Whether a group is collapsed.
   */
  bool isCollapsed = false;

  /***
   * GroupTotals, if any.
   */
  GroupTotals totals;

  /**
   * Rows that are part of the group.
   */
  List<ItemBase> rows = <ItemBase>[];

  /**
   * Sub-groups that are part of the group.
   */
  List<Group> groups;

  /**
   * A unique key used to identify the group.  This key can be used in calls to DataView
   * collapseGroup() or expandGroup().
   */
  String groupingKey;

  @override
  bool operator ==(other) {
    if (other is! Group) {
      return false;
    }

    var o = other as Group;
    return count == o.count && isCollapsed == o.isCollapsed && title == o.title;
  }

  @override
  int get hashCode => quc.hash3(count, isCollapsed, title);
}

abstract class GroupTotalsFormatter extends fm.FormatterBase {
  void call(dom.Element target, GroupTotals totals, Column columnDef);
}

abstract class GroupTitleFormatter extends fm.FormatterBase {
  dom.Node call(Group totals);
}

/**
 * Information about group totals.
 * An instance of GroupTotals will be created for each totals row and passed to the aggregators
 * so that they can store arbitrary data in it.  That data can later be accessed by group totals
 * formatters during the display.
 */
class GroupTotals extends NonDataItem {
  /***
   * Parent Group.
   */
  Group group;

  /***
   * Whether the totals have been fully initialized / calculated.
   * Will be set to false for lazy-calculated group totals.
   */
  bool isInitialized = false;
}

/***
 * A locking helper to track the active edit controller and ensure that only a single controller
 * can be active at a time.  This prevents a whole class of state and validation synchronization
 * issues.  An edit controller (such as BWU Datagrid) can query if an active edit is in progress
 * and attempt a commit or cancel before proceeding.
 */

final EditorLock globalEditorLock = new EditorLock();

class EditorLock {
  EditController activeEditController;
  EditController editController;

  /***
   * Returns true if a specified edit controller is active (has the edit lock).
   * If the parameter is not specified, returns true if any edit controller is active.
   */
  bool get isActive {
    return editController != null ? activeEditController == editController : activeEditController != null;
  }

  /***
   * Sets the specified edit controller as the active edit controller (acquire edit lock).
   * If another edit controller is already active, and exception will be thrown.
   */
  void activate(EditController editController) {
    if (editController == activeEditController) { // already activated?
      return;
    }
    if (activeEditController != null) {
      throw "bwu_datagrid.EditorLock.activate: an editController is still active, can't activate another editController";
    }
    if (editController.commitCurrentEdit == null) {
      throw "bwu_datagrid.EditorLock.activate: editController must implement .commitCurrentEdit()";
    }
    if (editController.cancelCurrentEdit == null) {
      throw "bwu_datagrid.EditorLock.activate: editController must implement .cancelCurrentEdit()";
    }
    activeEditController = editController;
  }

  /***
   * Unsets the specified edit controller as the active edit controller (release edit lock).
   * If the specified edit controller is not the active one, an exception will be thrown.
   */
  void deactivate(EditController editController) {
    if (activeEditController != editController) {
      throw "bwu_datagrid.EditorLock.deactivate: specified editController is not the currently active one";
    }
    activeEditController = null;
  }

  /***
   * Attempts to commit the current edit by calling "commitCurrentEdit" method on the active edit
   * controller and returns whether the commit attempt was successful (commit may fail due to validation
   * errors, etc.).  Edit controller's "commitCurrentEdit" must return true if the commit has succeeded
   * and false otherwise.  If no edit controller is active, returns true.
   */
  bool commitCurrentEdit() {
    return (activeEditController != null ? activeEditController.commitCurrentEdit() : true);
  }

  /***
   * Attempts to cancel the current edit by calling "cancelCurrentEdit" method on the active edit
   * controller and returns whether the edit was successfully cancelled.  If no edit controller is
   * active, returns true.
   */
  bool cancelCurrentEdit() {
    return (activeEditController != null ? activeEditController.cancelCurrentEdit() : true);
  }
}

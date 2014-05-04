part of bwu_dart.bwu_datagrid.core.range;

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

/***
 * A base class that all special / non-data rows (like Group and GroupTotals) derive from.
 */
abstract class NonDataItem {}

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
  int count = 0;

  /***
   * Grouping value.
   */
  dynamic value; // TODO should it be made generic?

  /***
   * Formatted display value of the group.
   */
  String title;

  /***
   * Whether a group is collapsed.
   */
  bool isCollapsed;

  /***
   * GroupTotals, if any.
   */
  GroupTotals totals;

  /**
   * Rows that are part of the group.
   */
  List<int> rows = <int>[];

  /**
   * Sub-groups that are part of the group.
   */
  List<Group> groups;

  /**
   * A unique key used to identify the group.  This key can be used in calls to DataView
   * collapseGroup() or expandGroup().
   */
  dynamic groupingKey; // TODO should it be made generic?

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
  Group parent;

  /***
   * Whether the totals have been fully initialized / calculated.
   * Will be set to false for lazy-calculated group totals.
   */
  bool isInitialized = false;
}

/***
 * A locking helper to track the active edit controller and ensure that only a single controller
 * can be active at a time.  This prevents a whole class of state and validation synchronization
 * issues.  An edit controller (such as SlickGrid) can query if an active edit is in progress
 * and attempt a commit or cancel before proceeding.
 */
class EditorLock {
  dynamic activeEditController; // TODO type
  dynamic editController; // TODO type

  /***
   * Returns true if a specified edit controller is active (has the edit lock).
   * If the parameter is not specified, returns true if any edit controller is active.
   */
  bool get isActive {
    return editController != null ? activeEditController == editController : activeEditController =! null;
  }

  /***
   * Sets the specified edit controller as the active edit controller (acquire edit lock).
   * If another edit controller is already active, and exception will be thrown.
   */
  void activate(editController) { // TODO type
    if (editController == activeEditController) { // already activated?
      return;
    }
    if (activeEditController != null) {
      throw "bwu_datagrid.EditorLock.activate: an editController is still active, can't activate another editController";
    }
    if (!editController.commitCurrentEdit) {
      throw "bwu_datagrid.EditorLock.activate: editController must implement .commitCurrentEdit()";
    }
    if (!editController.cancelCurrentEdit) {
      throw "bwu_datagrid.EditorLock.activate: editController must implement .cancelCurrentEdit()";
    }
    activeEditController = editController;
  }

  /***
   * Unsets the specified edit controller as the active edit controller (release edit lock).
   * If the specified edit controller is not the active one, an exception will be thrown.
   */
  void deactivate(editController) { // TODO type
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
    return (activeEditController ? activeEditController.commitCurrentEdit() : true);
  }

  /***
   * Attempts to cancel the current edit by calling "cancelCurrentEdit" method on the active edit
   * controller and returns whether the edit was successfully cancelled.  If no edit controller is
   * active, returns true.
   */
  bool cancelCurrentEdit() {
    return (activeEditController ? activeEditController.cancelCurrentEdit() : true);
  }
}

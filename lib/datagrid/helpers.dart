library bwu_dart.bwu_datagrid.datagrid.helpers;

import 'dart:html' as dom;
import 'dart:collection' as coll;

import 'package:bwu_datagrid/editors/editors.dart';
import 'package:bwu_datagrid/core/core.dart';
import 'package:bwu_datagrid/formatters/formatters.dart';
//import 'package:bwu_datagrid/bwu_datagrid.dart';


typedef void SortableStartFn(dom.HtmlElement e, dom.HtmlElement ui);
typedef void SortableBeforeStopFn(dom.HtmlElement e, dom.HtmlElement ui);
typedef void SortableStopFn(dom.HtmlElement e);

class Sortable {
  String containment;
  int distance;
  String axis;
  String cursor;
  String tolerance;
  String helper;
  String placeholder;
  SortableStartFn start;
  SortableBeforeStopFn beforeStop;
  SortableStopFn stop;

  Sortable({this.containment, this.distance, this.axis, this.cursor, this.tolerance, this.helper, this.placeholder, this.start, this.beforeStop, this.stop});
  void cancel() {}
  void destroy() {}
  List toArray() { return [];}
}
class Filter {
  String selector;
  Filter(this.selector);
  Sortable sortable = new Sortable();
}

class CellPos {
  final int row;
  final int cell;
  final int posX;

  const CellPos({this.row, this.cell, this.posX});
}

class Cell {
  final int row;
  final int cell;
  const Cell(this.row, this.cell);
}

class NodeBox {
  int top;
  int left;
  int bottom;
  int right;
  int width;
  int height;
  bool visible;

  NodeBox({this.top, this.left, this.bottom, this.right, this.width, this.height, this.visible});
}

class Row {

}

class RowCache {
  coll.Queue cellRenderQueue = new coll.Queue();
  Map<int,String> cellColSpans = {};
  dom.HtmlElement rowNode;
  List<dom.HtmlElement> cellNodes = [];
  Map<int,dom.HtmlElement> cellNodesByColumnIdx = {};

  RowCache();
}

class Range {
  int fromRow;
  int toRow;
  int fromCell;
  int toCell;
  int rightPx;
  int leftPx;
  int top;
  int bottom;

  Range({this.fromRow, this.toRow, this.fromCell, this.toCell, this.rightPx, this.leftPx, this.top, this.bottom});
}

abstract class EditorFactory {
  Editor getEditor(Column column);
}

abstract class FormatterFactory {
  Formatter getFormatter(Column column);
}

class ColumnMetadata {
  String colspan;
  bool selectable;

}

class ItemMetadata {
  String cssClasses;
  bool focusable;
  bool selectable;
  final columns = <ColumnMetadata>[];
}

class RowMetadata {
  final Map<String,Column> columns = {};

}


class Item {
  String title;
  int level;
  bool collapsed;
  String operator [](int idx) {
    print('Item [] accessor is not yet implemented');
  }
}

/* temp */
class SortColumn {
  String columnId;
  bool sortAsc = true;

  SortColumn(this.columnId, this.sortAsc);
}

class EditCommand {
  int row;
  int cell;
  Editor editor;
  String serializedValue;
  String prevSerializedValue;
  Function execute;
  Function undo;
  EditCommand({this.row, this.cell, this.editor, this.serializedValue, this.prevSerializedValue, this.execute, this.undo});
}

class EditController {
  Function commitCurrentEdit;
  Function cancelCurrentEdit;

  EditController(this.commitCurrentEdit, this.cancelCurrentEdit);
}

class Column {
  String id;
  String name;
  String field;
  int width;
  int minWidth;
  int maxWidth;
  bool resizable;
  bool sortable;
  bool focusable;
  bool selectable;
  bool defaultSortAsc;
  String headerCssClass;
  bool rerenderOnResize;
  String toolTip;
  String cssClass;
  bool cannotTriggerInsert;

  Editor editor;
  Formatter formatter;
  Validator validator;

  int previousWidth;

  Column({this.id, this.field, this.minWidth : 30, this.maxWidth, this.cssClass, this.formatter, this.editor, this.validator,
    this.name: '' , this.width, this.resizable : true, this.sortable : false, this.focusable : true, this.selectable : true, this.defaultSortAsc : true, this.rerenderOnResize : false, this.cannotTriggerInsert: false}) {
  }

  Column.unititialized();

  void extend(Column c) {
    if(c.id != null) id = c.id;
    if(c.name != null) name = c.name;
    if(c.field != null) field = c.field;
    if(c.width != null) width = c.width;
    if(c.minWidth != null) minWidth = c.minWidth;
    if(c.maxWidth != null) maxWidth = c.maxWidth;
    if(c.resizable != null) resizable = c.resizable;
    if(c.sortable != null) sortable = c.sortable;
    if(c.focusable != null) focusable = c.focusable;
    if(c.selectable != null) selectable = c.selectable;
    if(c.defaultSortAsc != null) defaultSortAsc = c.defaultSortAsc;
    if(c.headerCssClass != null) headerCssClass = c.headerCssClass;
    if(c.rerenderOnResize != null) rerenderOnResize = c.rerenderOnResize;
    if(c.toolTip != null) toolTip = c.toolTip;
    if(c.cssClass != null) cssClass = c.cssClass;
    if(c.cannotTriggerInsert != null) cannotTriggerInsert = c.cannotTriggerInsert;
    if(c.editor != null) editor = c.editor;
    if(c.formatter != null) formatter = c.formatter;
    if(c.validator != null) validator = c.validator;
    if(c.previousWidth != null) previousWidth = c.previousWidth;
  }

  void asyncPostRender(dom.HtmlElement node, int row, /*Map/Item*/ rowData, Column m) {
    print('Column.asyncPostRender not yet implemented');
  }
}

class GridOptions { // defaults
  bool explicitInitialization;
  int rowHeight;
  int defaultColumnWidth;
  bool enableAddRow;
  bool leaveSpaceForNewRows;
  bool editable;
  bool autoEdit;
  bool enableCellNavigation;
  bool enableColumnReorder;
  bool asyncEditorLoading;
  Duration asyncEditorLoadDelay;
  bool forceFitColumns;
  bool enableAsyncPostRender;
  Duration asyncPostRenderDelay;
  bool autoHeight;
  EditorLock editorLock;
  bool showHeaderRow;
  int headerRowHeight;
  bool showTopPanel;
  int topPanelHeight;
  FormatterFactory formatterFactory;
  EditorFactory editorFactory;
  String cellFlashingCssClass;
  String selectedCellCssClass;
  bool multiSelect;
  bool enableTextSelectionOnCells;
  Function dataItemColumnValueExtractor; // TODO typeDef (item, columnDef)
  bool fullWidthRows;
  bool multiColumnSort;
  Formatter defaultFormatter;
  bool forceSyncScrolling;
  String addNewRowCssClass;
  bool syncColumnCellResize;
  Function editCommandHandler;

  GridOptions({
    this.explicitInitialization : false,
    this.rowHeight : 25,
    this.defaultColumnWidth : 80,
    this.enableAddRow : false,
    this.leaveSpaceForNewRows : false,
    this.editable : false,
    this.autoEdit : true,
    this.enableCellNavigation : true,
    this.enableColumnReorder : true,
    this.asyncEditorLoading : false,
    this.asyncEditorLoadDelay,
    this.forceFitColumns: false,
    this.enableAsyncPostRender: false,
    this.asyncPostRenderDelay,
    this.autoHeight : false,
    this.editorLock,
    this.showHeaderRow : false,
    this.headerRowHeight : 25,
    this.showTopPanel : false,
    this.topPanelHeight : 25,
    this.formatterFactory,
    this.editorFactory,
    this.cellFlashingCssClass : 'flashing',
    this.selectedCellCssClass : 'selected',
    this.multiSelect : true,
    this.enableTextSelectionOnCells : false,
    this.dataItemColumnValueExtractor,
    this.fullWidthRows : false,
    this.multiColumnSort : false,
    this.defaultFormatter,
    this.forceSyncScrolling: false,
    this.addNewRowCssClass : 'new-row',
    this.syncColumnCellResize : false
  }) {
    if(asyncEditorLoadDelay == null) {
      this.asyncEditorLoadDelay = const Duration(milliseconds: 100);
    }

    if(asyncPostRenderDelay == null) {
        this.asyncPostRenderDelay = const Duration(milliseconds: 50);
    }

    if(editorLock == null) {
      this.editorLock = new EditorLock();
    }

    if(defaultFormatter == null) {
      this.defaultFormatter = new DefaultFormatter();
    }
  }

  GridOptions.unitialized();

  void extend(GridOptions o) {
    //var d = new GridOptions.unitialized();
    if(o.explicitInitialization != null) explicitInitialization = o.explicitInitialization;
    if(o.rowHeight!= null) rowHeight = o.rowHeight;
    if(o.defaultColumnWidth!= null) defaultColumnWidth = o.defaultColumnWidth;
    if(o.enableAddRow!= null) enableAddRow = o.enableAddRow;
    if(o.leaveSpaceForNewRows!= null) leaveSpaceForNewRows = o.leaveSpaceForNewRows;
    if(o.editable!= null) editable = o.editable;
    if(o.autoEdit!= null) autoEdit = o.autoEdit;
    if(o.enableCellNavigation!= null) enableCellNavigation = o.enableCellNavigation;
    if(o.enableColumnReorder!= null) enableColumnReorder = o.enableColumnReorder;
    if(o.asyncEditorLoading!= null) asyncEditorLoading = o.asyncEditorLoading;
    if(o.asyncEditorLoadDelay!= null) asyncEditorLoadDelay = o.asyncEditorLoadDelay;
    if(o.forceFitColumns!= null) forceFitColumns = o.forceFitColumns;
    if(o.enableAsyncPostRender!= null) enableAsyncPostRender = o.enableAsyncPostRender;
    if(o.asyncPostRenderDelay!= null) asyncPostRenderDelay = o.asyncPostRenderDelay;
    if(o.autoHeight!= null) autoHeight = o.autoHeight;
    if(o.editorLock!= null) editorLock = o.editorLock;
    if(o.showHeaderRow!= null) showHeaderRow = o.showHeaderRow;
    if(o.headerRowHeight!= null) headerRowHeight = o.headerRowHeight;
    if(o.showTopPanel!= null) showTopPanel = o.showTopPanel;
    if(o.topPanelHeight!= null) topPanelHeight = o.topPanelHeight;
    if(o.formatterFactory!= null) formatterFactory = o.formatterFactory;
    if(o.editorFactory!= null) editorFactory = o.editorFactory;
    if(o.cellFlashingCssClass!= null) cellFlashingCssClass = o.cellFlashingCssClass;
    if(o.selectedCellCssClass!= null) selectedCellCssClass = o.selectedCellCssClass;
    if(o.multiSelect!= null) multiSelect = o.multiSelect;
    if(o.enableTextSelectionOnCells!= null) enableTextSelectionOnCells = o.enableTextSelectionOnCells;
    if(o.dataItemColumnValueExtractor!= null) dataItemColumnValueExtractor = o.dataItemColumnValueExtractor;
    if(o.fullWidthRows!= null) fullWidthRows = o.fullWidthRows;
    if(o.multiColumnSort!= null) multiColumnSort = o.multiColumnSort;
    if(o.defaultFormatter!= null) defaultFormatter = o.defaultFormatter;
    if(o.forceSyncScrolling!= null) forceSyncScrolling = o.forceSyncScrolling;
    if(o.addNewRowCssClass!= null) addNewRowCssClass = o.addNewRowCssClass;
    if(o.syncColumnCellResize!= null) syncColumnCellResize = o.syncColumnCellResize;
    if(o.editCommandHandler!= null) editCommandHandler = o.editCommandHandler;
  }
}
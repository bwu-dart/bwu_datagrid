library bwu_dart.bwu_datagrid.datagrid.helpers;

import 'dart:html' as dom;
import 'dart:collection' as coll;

import 'package:bwu_datagrid/editors/editors.dart';
import 'package:bwu_datagrid/core/core.dart';
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
  final int top;
  final int left;
  final int bottom;
  final int right;
  final int width;
  final int height;
  final bool visible;

  const NodeBox({this.top, this.left, this.bottom, this.right, this.width, this.height, this.visible});
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
  FormatterFn getFormatter(Column column);
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

//class ColumnDefinition {
//  int field;
//}

class Item {
  String title;
  int level;
  bool collapsed;
  String operator [](int idx) {

  }
}

//class Data {
//  ItemMetadata getItemMetadata(int row) {
//
//  }
//
//  bool get getLength => true;
//
//  int get length => 0;
//
//  Item getItem(int idx) {
//
//  }
//
//  Item operator [](int idx) {
//
//  }
//
//}

/* temp */
//class Headers {
//  dom.HtmlElement element;
//
//  Headers filter(String f) {
//
//  }
//
//  void sortable(String s) {
//
//  }
//}

/* temp */
class SortColumn {
  String columnId;
  bool sortAsc = true;

  SortColumn(this.columnId, this.sortAsc);
}

/* temp */
//class Column {
//  String id;
//  String name;
//  bool sortable = false;
//  int previousWidth;
//  bool resizable = false;
//  int maxWidth;
//  int minWidth;
//  String toolTip;
//  String headerCssClass;
//  int width;
//  bool defaultSortAsc = true;
//  bool rerenderOnResize = false;
//  Editor editor;
//  String cssClass;
//  int field;
//}

class ValidationResults {
  bool valid;
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
  String name = '';
  int width;
  int minWidth = 30;
  int maxWidth;
  bool resizable = true;
  bool sortable = false;
  bool focusable = true;
  bool selectable = true;
  bool defaultSortAsc = true;
  String headerCssClass;
  bool rerenderOnResize = false;
  String toolTip;
  String cssClass;

  Editor editor;
  FormatterFn formatter;
  bool cannotTriggerInsert;

  String field;
  int previousWidth;

  void asyncPostRender(dom.HtmlElement node, int row, /*Map/Item*/ rowData, Column m) {

  }

  Column({this.id, this.name, this.field});

  Column.defaults();

  void extend(Column c) {
    Column d = new Column.defaults();
    if(c.id != d.id) id = c.id;
    if(c.name != d.name) name = c.name;
    if(c.width != d.width) width = c.width;
    if(c.minWidth != d.minWidth) minWidth = c.minWidth;
    if(c.maxWidth != d.maxWidth) maxWidth = c.maxWidth;
    if(c.resizable != d.resizable) resizable = c.resizable;
    if(c.sortable != d.sortable) sortable = c.sortable;
    if(c.focusable != d.focusable) focusable = c.focusable;
    if(c.selectable != d.selectable) selectable = c.selectable;
    if(c.defaultSortAsc != d.defaultSortAsc) defaultSortAsc = c.defaultSortAsc;
    if(c.headerCssClass != d.headerCssClass) headerCssClass = c.headerCssClass;
    if(c.rerenderOnResize != d.rerenderOnResize) rerenderOnResize = c.rerenderOnResize;
    if(c.toolTip != d.toolTip) toolTip = c.toolTip;
    if(c.cssClass != d.cssClass) cssClass = c.cssClass;
    if(c.editor != d.editor) editor = c.editor;
    if(c.formatter != d.formatter) formatter = c.formatter;
    if(c.cannotTriggerInsert != d.cannotTriggerInsert) cannotTriggerInsert = c.cannotTriggerInsert;
    if(c.field != d.field) field = c.field;
    if(c.previousWidth != d.previousWidth) previousWidth = c.previousWidth;
  }
}

typedef String FormatterFn(int row, int cell, dynamic value, Column m, dataContext);

String defaultFormatterImpl(int row, int cell, dynamic value, Column columnDef, dataContext) {
  if (value == null) {
    return "";
  } else {
    return '$value'.replaceAll(r'&',"&amp;").replaceAll(r'<',"&lt;").replaceAll(r'>',"&gt;");
  }
}

class GridOptions { // defaults
  bool explicitInitialization= false;
  int rowHeight = 25;
  int defaultColumnWidth = 80;
  bool enableAddRow = false;
  bool leaveSpaceForNewRows = false;
  bool editable = false;
  bool autoEdit = true;
  bool enableCellNavigation = true;
  bool enableColumnReorder = true;
  bool asyncEditorLoading = false;
  Duration asyncEditorLoadDelay = const Duration(milliseconds: 100);
  bool forceFitColumns = false;
  bool enableAsyncPostRender = false;
  Duration asyncPostRenderDelay = const Duration(milliseconds: 50);
  bool autoHeight = false;
  EditorLock editorLock = new EditorLock();
  bool showHeaderRow = false;
  int headerRowHeight = 25;
  bool showTopPanel = false;
  int topPanelHeight = 25;
  FormatterFactory formatterFactory;
  EditorFactory editorFactory;
  String cellFlashingCssClass = 'flashing';
  String selectedCellCssClass = 'selected';
  bool multiSelect = true;
  bool enableTextSelectionOnCells = false;
  Function dataItemColumnValueExtractor; // TODO typeDef (item, columnDef)
  bool fullWidthRows = false;
  bool multiColumnSort = false;
  FormatterFn defaultFormatter;
  bool forceSyncScrolling = false;
  String addNewRowCssClass = 'new-row';
  bool syncColumnCellResize = false;
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
      this.defaultFormatter = defaultFormatterImpl;
    }
  }

  void extend(GridOptions o) {
    var d = new GridOptions();
    if(o.explicitInitialization!= d.explicitInitialization) explicitInitialization = o.explicitInitialization;
    if(o.rowHeight!= d.rowHeight) rowHeight = o.rowHeight;
    if(o.defaultColumnWidth!= d.defaultColumnWidth) defaultColumnWidth = o.defaultColumnWidth;
    if(o.enableAddRow!= d.enableAddRow) enableAddRow = o.enableAddRow;
    if(o.leaveSpaceForNewRows!= d.leaveSpaceForNewRows) leaveSpaceForNewRows = o.leaveSpaceForNewRows;
    if(o.editable!= d.editable) editable = o.editable;
    if(o.autoEdit!= d.autoEdit) autoEdit = o.autoEdit;
    if(o.enableCellNavigation!= d.enableCellNavigation) enableCellNavigation = o.enableCellNavigation;
    if(o.enableColumnReorder!= d.enableColumnReorder) enableColumnReorder = o.enableColumnReorder;
    if(o.asyncEditorLoading!= d.asyncEditorLoading) asyncEditorLoading = o.asyncEditorLoading;
    if(o.asyncEditorLoadDelay!= d.asyncEditorLoadDelay) asyncEditorLoadDelay = o.asyncEditorLoadDelay;
    if(o.forceFitColumns!= d.forceFitColumns) forceFitColumns = o.forceFitColumns;
    if(o.enableAsyncPostRender!= d.enableAsyncPostRender) enableAsyncPostRender = o.enableAsyncPostRender;
    if(o.asyncPostRenderDelay!= d.asyncPostRenderDelay) asyncPostRenderDelay = o.asyncPostRenderDelay;
    if(o.autoHeight!= d.autoHeight) autoHeight = o.autoHeight;
    if(o.editorLock!= d.editorLock) editorLock = o.editorLock;
    if(o.showHeaderRow!= d.showHeaderRow) showHeaderRow = o.showHeaderRow;
    if(o.headerRowHeight!= d.headerRowHeight) headerRowHeight = o.headerRowHeight;
    if(o.showTopPanel!= d.showTopPanel) showTopPanel = o.showTopPanel;
    if(o.topPanelHeight!= d.topPanelHeight) topPanelHeight = o.topPanelHeight;
    if(o.formatterFactory!= d.formatterFactory) formatterFactory = o.formatterFactory;
    if(o.editorFactory!= d.editorFactory) editorFactory = o.editorFactory;
    if(o.cellFlashingCssClass!= d.cellFlashingCssClass) cellFlashingCssClass = o.cellFlashingCssClass;
    if(o.selectedCellCssClass!= d.selectedCellCssClass) selectedCellCssClass = o.selectedCellCssClass;
    if(o.multiSelect!= d.multiSelect) multiSelect = o.multiSelect;
    if(o.enableTextSelectionOnCells!= d.enableTextSelectionOnCells) enableTextSelectionOnCells = o.enableTextSelectionOnCells;
    if(o.dataItemColumnValueExtractor!= d.dataItemColumnValueExtractor) dataItemColumnValueExtractor = o.dataItemColumnValueExtractor;
    if(o.fullWidthRows!= d.fullWidthRows) fullWidthRows = o.fullWidthRows;
    if(o.multiColumnSort!= d.multiColumnSort) multiColumnSort = o.multiColumnSort;
    if(o.defaultFormatter!= d.defaultFormatter) defaultFormatter = o.defaultFormatter;
    if(o.forceSyncScrolling!= d.forceSyncScrolling) forceSyncScrolling = o.forceSyncScrolling;
    if(o.addNewRowCssClass!= d.addNewRowCssClass) addNewRowCssClass = o.addNewRowCssClass;
    if(o.syncColumnCellResize!= d.syncColumnCellResize) syncColumnCellResize = o.syncColumnCellResize;
    if(o.editCommandHandler!= d.editCommandHandler) editCommandHandler = o.editCommandHandler;
  }
}
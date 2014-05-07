library bwu_dart.bwu_datagrid.datagrid.helpers;

import 'dart:html' as dom;
import 'dart:collection' as coll;

import 'package:bwu_datagrid/editors/editors.dart';

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
  List<String> cellColSpans = [];
  dom.HtmlElement rowNode;
  List<dom.HtmlElement> cellNodes = [];
  Map<int,dom.HtmlElement> cellNodesByColumnIdx = {};

  RowCache();
}

class EditorLock {
  bool commitCurrentEdit() {}
  bool cancelCurrentEdit() {}
  bool isActive = false;
  void deactivate(EditController editController) {

  }
  bool activate(EditController editController) {

  }
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

abstract class Formatter {

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

//class ColumnDefinition {
//  int field;
//}

class Item {
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
class Headers {
  dom.HtmlElement element;

  Headers filter(String f) {

  }

  void sortable(String s) {

  }
}

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

class Column { // columnDefaults
  String id;
  String name;
  int width;
  int maxWidth;
  int minWidth = 30;
  bool resizable = true;
  bool sortable = false;
  bool focusable = true;
  bool selectable = true;
  bool defaultSortAsc = true;
  String headerCssClass;
  bool rerenderOnResize = true;
  String toolTip;
  String cssClass;

  int previousWidth;
  Editor editor;
  String field;
  Formatter formatter;
  bool cannotTriggerInsert;

  void asyncPostRender(dom.HtmlElement node, int row, Item rowData, Column m) {

  }

  Column({this.id, this.name, this.field});

  Column.defaults();

  Column.fromColumn(Column c) {
    Column d = new Column.defaults();
    //TODO
    if(c.cssClass != d.cssClass) cssClass = c.cssClass;
    if(c.defaultSortAsc != d.defaultSortAsc) defaultSortAsc = c.defaultSortAsc;
    //c.editor
    if(c.headerCssClass != d.headerCssClass) headerCssClass = c.headerCssClass;
    if(c.id != d.id)  id = c.id;
    if(c.maxWidth != d.maxWidth) maxWidth = c.maxWidth;
    if(c.minWidth != d.minWidth) minWidth = c.minWidth;
    if(c.name != d.name) name = c.name;
    //c.previousWidth
    if(c.rerenderOnResize != d.rerenderOnResize) rerenderOnResize = c.rerenderOnResize;
    if(c.resizable != d.resizable) resizable = c.resizable;
    if(c.sortable != d.sortable) sortable = c.sortable;
    if(c.toolTip != d.toolTip) toolTip = c.toolTip;
    if(c.width != d.width) width = c.width;
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
  bool defaultFormatter = true;
  bool forceSyncScrolling = false;
  String addNewRowCssClass = 'new-row';
  bool syncColumnCellResize = false;
  Function editCommandHandler;

  GridOptions({
    this.explicitInitialization,
    this.rowHeight,
    this.defaultColumnWidth,
    this.enableAddRow,
    this.leaveSpaceForNewRows,
    this.editable,
    this.autoEdit,
    this.enableCellNavigation,
    this.enableColumnReorder,
    this.asyncEditorLoading,
    this.asyncEditorLoadDelay,
    this.forceFitColumns,
    this.enableAsyncPostRender,
    this.asyncPostRenderDelay,
    this.autoHeight,
    this.editorLock,
    this.showHeaderRow,
    this.headerRowHeight,
    this.showTopPanel,
    this.topPanelHeight,
    this.formatterFactory,
    this.editorFactory,
    this.cellFlashingCssClass,
    this.selectedCellCssClass,
    this.multiSelect,
    this.enableTextSelectionOnCells,
    this.dataItemColumnValueExtractor,
    this.fullWidthRows,
    this.multiColumnSort,
    this.defaultFormatter,
    this.forceSyncScrolling,
    this.addNewRowCssClass
  });

  GridOptions extendWithArgs(GridOptions args) {
    throw '"extendWithArgs" not implemented';
  }
}
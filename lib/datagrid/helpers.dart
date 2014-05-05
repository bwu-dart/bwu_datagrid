library bwu_dart.bwu_datagrid.datagrid.helpers;

import 'dart:html' as dom;

import 'package:bwu_datagrid/editors/editors.dart';

class ColumnDefinition {
  int field;
}

class Item {
  String operator [](int idx) {

  }
}

class Data {
  String getItemMetadata(int row) {

  }

  bool get getLength => true;

  int get length => 0;

  Item getItem(int idx) {

  }

  Item operator [](int idx) {

  }

}

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
class Column {
  String id;
  String name;
  bool sortable = false;
  int previousWidth;
  bool resizable = false;
  int maxWidth;
  int minWidth;
  String toolTip;
  String headerCssClass;
  int width;
  bool defaultSortAsc = true;
  bool rerenderOnResize = false;
  Editor editor;
  String cssClass;
}

class EditController {
  Function commitCurrentEdit;
  Function cancelCurrentEdit;

  EditController(this.commitCurrentEdit, this.cancelCurrentEdit);
}

class ColumnOptions { // columnDefaults
  String id;
  int width;
  int maxWidth;

  String name = '';
  bool resizable = true;
  bool sortable = false;
  int minWidth = 30;
  bool rerenderOnResize = false;
  String headerCssClass = '';
  bool defaultSortAsc = true;
  bool focusable = true;
  bool selectable = true;
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
  bool formatterFactory;
  bool editorFactory;
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
}
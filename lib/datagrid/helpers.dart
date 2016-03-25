library bwu_datagrid.datagrid.helpers;

import 'dart:html' as dom;
import 'dart:collection' as coll;

import 'package:bwu_datagrid/editors/editors.dart';
import 'package:bwu_datagrid/core/core.dart';
import 'package:bwu_datagrid/formatters/formatters.dart';
import 'package:bwu_datagrid/groupitem_metadata_providers/groupitem_metadata_providers.dart';
import 'package:collection/collection.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:polymer/polymer.dart';

abstract class DataProvider<T extends core.ItemBase<dynamic, dynamic>> {
  List<T> _items;
  List<T> get items => _items;
  void set items(List<T> items) {
    _items = items;
  }

  int get length;
  T getItem(int index);
  RowMetadata getItemMetadata(int index);

  DataProvider(List<T> items) : _items = (items == null ? <T>[] : items);
}

class MapDataItemProvider<T extends core.ItemBase<dynamic, dynamic>>
    extends DataProvider<T> {
  MapDataItemProvider([List<T> items]) : super(items);

  @override
  int get length => items.length;

  @override
  T getItem(int index) => items[index];

  @override
  RowMetadata getItemMetadata(int index) => null;
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

  NodeBox(
      {this.top,
      this.left,
      this.bottom,
      this.right,
      this.width,
      this.height,
      this.visible});

  @override
  String toString() =>
      '${super.toString()} - top: ${top}; left: ${left}; bottom: ${bottom}; right: ${right}; width: ${width}; height: ${height}; visible: ${visible}';
}

class Row {}

class RowCache {
  coll.Queue<int> cellRenderQueue = new coll.Queue<int>();
  Map<int, String> cellColSpans = <int, String>{};
  dom.Element rowNode;
  List<dom.Element> cellNodes = <dom.Element>[];
  Map<int, dom.Element> cellNodesByColumnIdx = {};

  RowCache();
}

class Range extends core.Range {
//  int fromRow;
//  int fromCell;
//  int toRow;
//  int toCell;
  int rightPx;
  int leftPx;
  int top;
  int bottom;

  Range(
      {int fromRow,
      int toRow,
      int fromCell,
      int toCell,
      this.rightPx,
      this.leftPx,
      this.top,
      this.bottom})
      : super(fromRow, fromCell, toRow: toRow, toCell: toCell);
}

typedef Editor EditorFactory(Column column);

typedef Formatter FormatterFactory(Column column);

abstract class DataItem<K, V> extends ItemBase<K, V> {
  bool collapsed;
}

class MapDataItem<K, V> extends DelegatingMap<K, V> implements DataItem<K, V> {
  bool collapsed = false;

  MapDataItem([Map<K, V> base]) : super(base != null ? base : <K, V>{});

  void extend(MapDataItem<K, V> update) {
    update.keys.forEach((K e) => this[e] = update[e]);
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

  /// [serializedValue] and [prevSerializedValue] are normally of type [String]
  /// but for example for compound values they are of type [Map]
  Object serializedValue;
  Object prevSerializedValue;
  Function execute;
  Function undo;
  EditCommand(
      {this.row,
      this.cell,
      this.editor,
      this.serializedValue,
      this.prevSerializedValue,
      this.execute,
      this.undo});
}

class EditController {
  Function commitCurrentEdit;
  Function cancelCurrentEdit;

  EditController(this.commitCurrentEdit, this.cancelCurrentEdit);
}

typedef void AsyncPostRenderFn(dom.Element target, int row,
    DataItem<dynamic, dynamic> dataContext, Column colDef);

class Column extends JsProxy {
  @reflectable
  String id;
  @reflectable
  String name;
  dom.Element nameElement;
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
  String colspan;
  List<String> behavior;
  bool isMovable; // allow column reorder
  bool isDraggable; // add attribute 'draggable

  Editor editor;
  Formatter formatter;
  GroupTotalsFormatter groupTotalsFormatter;
  Validator validator;
  AsyncPostRenderFn asyncPostRender;

  int previousWidth;

  Column(
      {this.id,
      this.field,
      this.minWidth: 30,
      this.maxWidth,
      this.cssClass,
      this.formatter,
      this.editor,
      this.validator,
      this.name: '',
      this.nameElement,
      this.width,
      this.resizable: true,
      this.sortable: false,
      this.focusable: true,
      this.selectable: true,
      this.defaultSortAsc: true,
      this.rerenderOnResize: false,
      this.cannotTriggerInsert: false,
      this.colspan,
      this.behavior,
      this.isMovable: true,
      this.isDraggable: false,
      this.asyncPostRender,
      this.toolTip,
      this.groupTotalsFormatter});

  Column.unititialized();

  void extend(Column c) {
    if (c.id != null) id = c.id;
    if (c.name != null) name = c.name;
    if (c.nameElement != null) nameElement = c.nameElement;
    if (c.field != null) field = c.field;
    if (c.width != null) width = c.width;
    if (c.minWidth != null) minWidth = c.minWidth;
    if (c.maxWidth != null) maxWidth = c.maxWidth;
    if (c.resizable != null) resizable = c.resizable;
    if (c.sortable != null) sortable = c.sortable;
    if (c.focusable != null) focusable = c.focusable;
    if (c.selectable != null) selectable = c.selectable;
    if (c.defaultSortAsc != null) defaultSortAsc = c.defaultSortAsc;
    if (c.headerCssClass != null) headerCssClass = c.headerCssClass;
    if (c.rerenderOnResize != null) rerenderOnResize = c.rerenderOnResize;
    if (c.toolTip != null) toolTip = c.toolTip;
    if (c.cssClass != null) cssClass = c.cssClass;
    if (c.cannotTriggerInsert != null)
      cannotTriggerInsert = c.cannotTriggerInsert;
    if (c.behavior != null) behavior = c.behavior;
    if (c.isMovable != null) isMovable = c.isMovable;
    if (c.isDraggable != null) isDraggable = c.isDraggable;

    if (c.editor != null) editor = c.editor;
    if (c.groupTotalsFormatter != null)
      groupTotalsFormatter = c.groupTotalsFormatter;
    if (c.formatter != null) formatter = c.formatter;
    if (c.validator != null) validator = c.validator;
    if (c.asyncPostRender != null) asyncPostRender = c.asyncPostRender;

    if (c.previousWidth != null) previousWidth = c.previousWidth;
  }
}

class GridOptions {
  // defaults
  String addNewRowCssClass;
  bool autoEdit;
  bool autoHeight;
  Duration asyncEditorLoadDelay;
  bool asyncEditorLoading;
  Duration asyncPostRenderDelay;
  String cellFlashingCssClass;
  String cellHighlightCssClass;
  Function dataItemColumnValueExtractor; // TODO typeDef (item, columnDef)
  int defaultColumnWidth;
  Formatter defaultFormatter;
  bool editable;
  Function editCommandHandler;
  EditorFactory editorFactory;
  EditorLock editorLock;
  bool enableAddRow;
  bool enableAsyncPostRender;
  bool enableCellNavigation;
  bool enableColumnReorder;
  bool enableTextSelectionOnCells;
  bool explicitInitialization;
  bool forceFitColumns;
  bool forceSyncScrolling;
  FormatterFactory formatterFactory;
  bool fullWidthRows;
  bool leaveSpaceForNewRows;
  int headerRowHeight;
  bool multiColumnSort;
  bool multiSelect;
  int rowHeight;
  String selectedCellCssClass;
  bool showHeaderRow;
  bool showTopPanel;
  bool syncColumnCellResize;
  int topPanelHeight;

  GridOptions(
      {this.addNewRowCssClass: 'new-row',
      this.asyncEditorLoadDelay,
      this.asyncEditorLoading: false,
      this.asyncPostRenderDelay,
      this.autoEdit: false,
      this.autoHeight: false,
      this.cellFlashingCssClass: 'flashing',
      this.cellHighlightCssClass: 'highlight',
      this.dataItemColumnValueExtractor,
      this.defaultColumnWidth: 80,
      this.defaultFormatter,
      this.editable: false,
      this.editCommandHandler,
      this.editorFactory,
      this.editorLock,
      this.enableAddRow: false,
      this.enableAsyncPostRender: false,
      this.enableCellNavigation: true,
      this.enableColumnReorder: true,
      this.enableTextSelectionOnCells: false,
      this.explicitInitialization: false,
      this.forceFitColumns: false,
      this.forceSyncScrolling: false,
      this.formatterFactory,
      this.fullWidthRows: false,
      this.headerRowHeight: 25,
      this.leaveSpaceForNewRows: false,
      this.multiColumnSort: false,
      this.multiSelect: true,
      this.rowHeight: 25,
      this.selectedCellCssClass: 'selected',
      this.showHeaderRow: false,
      this.showTopPanel: false,
      this.syncColumnCellResize: false,
      this.topPanelHeight: 25}) {
    if (asyncEditorLoadDelay == null) {
      this.asyncEditorLoadDelay = const Duration(milliseconds: 100);
    }

    if (asyncPostRenderDelay == null) {
      this.asyncPostRenderDelay = const Duration(milliseconds: 50);
    }

    if (editorLock == null) {
      this.editorLock = globalEditorLock;
    }

    if (defaultFormatter == null) {
      this.defaultFormatter = new DefaultFormatter();
    }
  }

  GridOptions.unitialized();

  void extend(GridOptions o) {
    //var d = new GridOptions.unitialized();
    if (o.addNewRowCssClass != null) addNewRowCssClass = o.addNewRowCssClass;
    if (o.asyncEditorLoadDelay != null)
      asyncEditorLoadDelay = o.asyncEditorLoadDelay;
    if (o.asyncEditorLoading != null) asyncEditorLoading = o.asyncEditorLoading;
    if (o.asyncPostRenderDelay != null)
      asyncPostRenderDelay = o.asyncPostRenderDelay;
    if (o.autoEdit != null) autoEdit = o.autoEdit;
    if (o.autoHeight != null) autoHeight = o.autoHeight;
    if (o.cellFlashingCssClass != null)
      cellFlashingCssClass = o.cellFlashingCssClass;
    if (o.cellHighlightCssClass != null)
      cellHighlightCssClass = o.cellHighlightCssClass;
    if (o.dataItemColumnValueExtractor != null)
      dataItemColumnValueExtractor = o.dataItemColumnValueExtractor;
    if (o.defaultColumnWidth != null) defaultColumnWidth = o.defaultColumnWidth;
    if (o.defaultFormatter != null) defaultFormatter = o.defaultFormatter;
    if (o.editable != null) editable = o.editable;
    if (o.editCommandHandler != null) editCommandHandler = o.editCommandHandler;
    if (o.editorFactory != null) editorFactory = o.editorFactory;
    if (o.editorLock != null) editorLock = o.editorLock;
    if (o.enableAddRow != null) enableAddRow = o.enableAddRow;
    if (o.enableAsyncPostRender != null)
      enableAsyncPostRender = o.enableAsyncPostRender;
    if (o.enableCellNavigation != null)
      enableCellNavigation = o.enableCellNavigation;
    if (o.enableColumnReorder != null)
      enableColumnReorder = o.enableColumnReorder;
    if (o.enableTextSelectionOnCells != null)
      enableTextSelectionOnCells = o.enableTextSelectionOnCells;
    if (o.explicitInitialization != null)
      explicitInitialization = o.explicitInitialization;
    if (o.forceFitColumns != null) forceFitColumns = o.forceFitColumns;
    if (o.forceSyncScrolling != null) forceSyncScrolling = o.forceSyncScrolling;
    if (o.formatterFactory != null) formatterFactory = o.formatterFactory;
    if (o.fullWidthRows != null) fullWidthRows = o.fullWidthRows;
    if (o.headerRowHeight != null) headerRowHeight = o.headerRowHeight;
    if (o.leaveSpaceForNewRows != null)
      leaveSpaceForNewRows = o.leaveSpaceForNewRows;
    if (o.multiColumnSort != null) multiColumnSort = o.multiColumnSort;
    if (o.multiSelect != null) multiSelect = o.multiSelect;
    if (o.rowHeight != null) rowHeight = o.rowHeight;
    if (o.selectedCellCssClass != null)
      selectedCellCssClass = o.selectedCellCssClass;
    if (o.showHeaderRow != null) showHeaderRow = o.showHeaderRow;
    if (o.showTopPanel != null) showTopPanel = o.showTopPanel;
    if (o.syncColumnCellResize != null)
      syncColumnCellResize = o.syncColumnCellResize;
    if (o.topPanelHeight != null) topPanelHeight = o.topPanelHeight;
  }
}

typedef CellPos StepFunction(int row, int cell, int posX);

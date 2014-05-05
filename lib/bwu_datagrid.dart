library bwu_dart.bwu_datagrid.datagrid;

import 'dart:async' as async;
import 'dart:math' as math;
import 'dart:html' as dom;

import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/core/core.dart';
//import 'dataview/dataview.dart';
import 'package:bwu_datagrid/plugin/plugin.dart';

import 'package:bwu_datagrid/datagrid/helpers.dart';

@CustomTag('bwu-datagrid')
class BwuDatagrid extends PolymerElement {

  BwuDatagrid.created() : super.created();

  @override
  polymerCreated() {
    super.polymerCreated();
  }

  // DataGrid(dom.HtmlElement container, String data, int columns, Options options);
  dom.HtmlElement container;
  @published Data data;
  @published List<Column> columns;
  @published GridOptions gridOptions;

  // settings
  //GridOptions gridOptions = new GridOptions();
  ColumnOptions columnOptions = new ColumnOptions();

  dom.NodeValidator nodeValidator = new dom.NodeValidatorBuilder.common();

  // scroller
  double th;   // virtual height
  double h;    // real scrollable height
  double ph;   // page height
  int n;    // number of pages
  double cj;   // "jumpiness" coefficient

  int page = 0;       // current page
  int pageOffset = 0;     // current page offset
  int vScrollDir = 1;

  // shared across all grids on the page
  math.Point scrollbarDimensions;
  double maxSupportedCssHeight;  // browser's breaking point

  // private
  bool initialized = false;
  dom.HtmlElement $container;
  String uid = "slickgrid_${(1000000 * new math.Random().nextDouble()).round()}";
  dom.HtmlElement $focusSink, $focusSink2;
  dom.HtmlElement $headerScroller;
  dom.HtmlElement $headers;
  dom.HtmlElement $headerRow, $headerRowScroller, $headerRowSpacer;
  dom.HtmlElement $topPanelScroller;
  dom.HtmlElement $topPanel;
  dom.HtmlElement $viewport;
  dom.HtmlElement $canvas;
  dom.HtmlElement $style;
  List<dom.HtmlElement> $boundAncestors;
  dom.CssCharsetRule stylesheet;
  List<dom.CssCharsetRule> columnCssRulesL, columnCssRulesR;
  double viewportH, viewportW;
  int canvasWidth;
  bool viewportHasHScroll, viewportHasVScroll;
  int headerColumnWidthDiff = 0, headerColumnHeightDiff = 0, // border+padding
      cellWidthDiff = 0, cellHeightDiff = 0;
  int absoluteColumnMinWidth;

  int tabbingDirection = 1;
  int activePosX;
  int activeRow, activeCell;
  dom.HtmlElement activeCellNode = null;
  Editor currentEditor = null;
  String serializedEditorValue;
  EditController editController;

  List<Map<String,int>> rowsCache = [];
  int renderedRows = 0;
  int numVisibleRows;
  int prevScrollTop = 0;
  int scrollTop = 0;
  int lastRenderedScrollTop = 0;
  int lastRenderedScrollLeft = 0;
  int prevScrollLeft = 0;
  int scrollLeft = 0;

  SelectionModel selectionModel;
  List<int> selectedRows = [];

  List<Plugin> plugins = [];
  List<Map<String,String>> cellCssClasses = [];

  Map<String,int> columnsById = {};
  List<SortColumn> sortColumns = [];
  List<int> columnPosLeft = [];
  List<int> columnPosRight = [];


  // async call handles
  async.Timer h_editorLoader = null;
  async.Timer h_render = null;
  async.Timer h_postrender = null;
  List<int> postProcessedRows = [];
  int postProcessToRow = null;
  int postProcessFromRow = null;

  // perf counters
  int counter_rows_rendered = 0;
  int counter_rows_removed = 0;

  // These two variables work around a bug with inertial scrolling in Webkit/Blink on Mac.
  // See http://crbug.com/312427.
  dom.HtmlElement rowNodeFromLastMouseWheelEvent;  // this node must not be deleted while inertial scrolling
  dom.HtmlElement zombieRowNodeFromLastMouseWheelEvent;  // node that was hidden instead of getting deleted

  /**
   * on before--destory
   */
  static const ON_BEFORE_DESTROY = 'before-destory';
  async.Stream<dom.CustomEvent> get onBeforeDestory =>
      BwuDatagrid._onBeforeDestory.forTarget(this);

  static const dom.EventStreamProvider<dom.CustomEvent> _onBeforeDestory =
      const dom.EventStreamProvider<dom.CustomEvent>(ON_BEFORE_DESTROY);

  /**
   * on before-header-cell-destory
   */
  static const ON_BEFORE_HEADER_CELL_DESTROY = 'before-header-cell-destory';
  async.Stream<dom.CustomEvent> get onBeforeHeaderCellDestory =>
      BwuDatagrid._onBeforeHeaderCellDestory.forTarget(this);

  static const dom.EventStreamProvider<dom.CustomEvent> _onBeforeHeaderCellDestory =
      const dom.EventStreamProvider<dom.CustomEvent>(ON_BEFORE_HEADER_CELL_DESTROY);

  /**
   * on header-cell-rendered
   */
  static const ON_HEADER_CELL_RENDERED = 'header-cell-rendered';
  async.Stream<dom.CustomEvent> get onHeaderCellRendered =>
      BwuDatagrid._onHeaderCellRendered.forTarget(this);

  static const dom.EventStreamProvider<dom.CustomEvent> _onHeaderCellRendered =
      const dom.EventStreamProvider<dom.CustomEvent>(ON_HEADER_CELL_RENDERED);

  /**
   * on header-row-cell-rendered
   */
  static const ON_HEADER_ROW_CELL_RENDERED = 'header-row-cell-rendered';
  async.Stream<dom.CustomEvent> get onHeaderRowCellRendered =>
      BwuDatagrid._onHeaderRowCellRendered.forTarget(this);

  static const dom.EventStreamProvider<dom.CustomEvent> _onHeaderRowCellRendered =
      const dom.EventStreamProvider<dom.CustomEvent>(ON_HEADER_ROW_CELL_RENDERED);


  /**
   * on sort
   */
  static const ON_SORT = 'sort';
  async.Stream<dom.CustomEvent> get onSort =>
      BwuDatagrid._onSort.forTarget(this);

  static const dom.EventStreamProvider<dom.CustomEvent> _onSort =
      const dom.EventStreamProvider<dom.CustomEvent>(ON_SORT);

  /**
   * on columns-resized
   */
  static const ON_COLUMNS_RESIZED = 'columns-resized';
  async.Stream<dom.CustomEvent> get onColumnsResized =>
      BwuDatagrid._onColumnsResized.forTarget(this);

  static const dom.EventStreamProvider<dom.CustomEvent> _onColumnsResized =
      const dom.EventStreamProvider<dom.CustomEvent>(ON_COLUMNS_RESIZED);

  /**
   * on columns-reordered
   */
  static const ON_COLUMNS_REORDERED = 'columns-reordered';
  async.Stream<dom.CustomEvent> get onColumnsReordered =>
      BwuDatagrid._onColumnsReordered.forTarget(this);

  static const dom.EventStreamProvider<dom.CustomEvent> _onColumnsReordered =
      const dom.EventStreamProvider<dom.CustomEvent>(ON_COLUMNS_REORDERED);

  /**
   * on selected-rows-changed
   */
  static const ON_SELECTED_ROWS_CHANGED = 'selected-rows-changed';
  async.Stream<dom.CustomEvent> get onSelectedRowsChanged =>
      BwuDatagrid._onSelectedRowsChanged.forTarget(this);

  static const dom.EventStreamProvider<dom.CustomEvent> _onSelectedRowsChanged =
      const dom.EventStreamProvider<dom.CustomEvent>(ON_SELECTED_ROWS_CHANGED);

  /**
   * on viewport-changed
   */
  static const ON_VIEWPORT_CHANGED = 'viewport-changed';
  async.Stream<dom.CustomEvent> get onViewportChanged =>
      BwuDatagrid._onViewportChanged.forTarget(this);

  static const dom.EventStreamProvider<dom.CustomEvent> _onViewportChanged =
      const dom.EventStreamProvider<dom.CustomEvent>(ON_VIEWPORT_CHANGED);

  //////////////////////////////////////////////////////////////////////////////////////////////
  // Initialization

  void init() {
    if (container.children.length < 1) {
      throw "DataGrid requires a valid container, ${container} does not exist in the DOM.";
    }

    // calculate these only once and share between grid instances
    maxSupportedCssHeight = maxSupportedCssHeight != null ? maxSupportedCssHeight : getMaxSupportedCssHeight();
    scrollbarDimensions = scrollbarDimensions != null ? scrollbarDimensions : measureScrollbar();

    //options = $.extend({}, defaults, options);
    validateAndEnforceOptions();
    columnOptions.width = gridOptions.defaultColumnWidth;

    columnsById = {};
    for (int i = 0; i < columns.length; i++) {
      ColumnOptions m = columnOptions;//columns[i] = $.extend({}, columnDefaults, columns[i]); // TODO extend
      columnsById[m.id] = i;
      if (m.minWidth && m.width < m.minWidth) {
        m.width = m.minWidth;
      }
      if (m.maxWidth && m.width > m.maxWidth) {
        m.width = m.maxWidth;
      }
    }

// TODO port jQuery UI sortable
//    // validate loaded JavaScript modules against requested options
//    if (gridOptions.enableColumnReorder && !$.fn.sortable) {
//      throw "DataGrid's 'enableColumnReorder = true' option requires jquery-ui.sortable module to be loaded";
//    }

    editController = new EditController(commitCurrentEdit, cancelCurrentEdit);

    $container
        ..children.clear() // TODO empty()
        ..style.overflow = 'hidden'
        ..style.outline = '0'
        ..classes.add(uid)
        ..classes.add("ui-widget");

    // set up a positioning container if needed
//      if (!/relative|absolute|fixed/.test($container.css("position"))) {
//        $container.css("position", "relative");
//      }
    if(!$container.style.position.contains(new RegExp('relative|absolute|fixed'))) {
      $container.style.position = 'relative';
    }

    $focusSink = new dom.Element.html("<div tabIndex='0' hideFocus style='position:fixed;width:0;height:0;top:0;left:0;outline:0;'></div>", validator: nodeValidator);
    $container.append($focusSink);

    $headerScroller = new dom.Element.html("<div class='slick-header ui-state-default' style='overflow:hidden;position:relative;' />", validator: nodeValidator);
    $container.append($headerScroller);

    $headers = new dom.Element.html("<div class='slick-header-columns' style='left:-1000px' />", validator: nodeValidator);
    $headerScroller.append($headers);
    $headers.style.width = "${getHeadersWidth()}px";

    $headerRowScroller = new dom.Element.html("<div class='slick-headerrow ui-state-default' style='overflow:hidden;position:relative;' />", validator: nodeValidator);
    $container.append($headerRowScroller);

    $headerRow = new dom.Element.html("<div class='slick-headerrow-columns' />", validator: nodeValidator);
    $headerRowScroller.append($headerRow);

    $headerRowSpacer = new dom.Element.html("<div style='display:block;height:1px;position:absolute;top:0;left:0;'></div>", validator: nodeValidator)
        ..style.width = '${getCanvasWidth() + scrollbarDimensions.x}px';
        $headerRowScroller.append($headerRowSpacer);

    $topPanelScroller = new dom.Element.html("<div class='bwu-datagrid-top-panel-scroller ui-state-default' style='overflow:hidden;position:relative;' />", validator: nodeValidator);
    $container.append($topPanelScroller);
    $topPanel = new dom.Element.html("<div class='bwu-datagrid-top-panel' style='width:10000px' />", validator: nodeValidator);
    $topPanelScroller.append($topPanel);

    if (!gridOptions.showTopPanel) {
      $topPanelScroller.style.visibility = 'none'; //hide();
    }

    if (!gridOptions.showHeaderRow) {
      $headerRowScroller.style.visibility = 'none'; // hide();
    }

    $viewport = new dom.Element.html("<div class='slick-viewport' style='width:100%;overflow:auto;outline:0;position:relative;;'>", validator: nodeValidator);
    $container.append($viewport);
    $viewport.style.overflowY = gridOptions.autoHeight ? "hidden" : "auto";

    $canvas = new dom.Element.html("<div class='grid-canvas' />", validator: nodeValidator);
    $viewport.append($canvas);

    $focusSink2 = $focusSink.clone(true);
    $container.append($focusSink2);

    if (!gridOptions.explicitInitialization) {
      finishInitialization();
    }
  }

  void finishInitialization() {
    if (!initialized) {
      initialized = true;

      viewportW = double.parse($container.children[0].style.width);

      // header columns and cells may have different padding/border skewing width calculations (box-sizing, hello?)
      // calculate the diff so we can set consistent sizes
      measureCellPaddingAndBorder();

      // for usability reasons, all text selection in SlickGrid is disabled
      // with the exception of input and textarea elements (selection must
      // be enabled there so that editors work as expected); note that
      // selection in grid cells (grid body) is already unavailable in
      // all browsers except IE
      disableSelection($headers); // disable all text selection in header (including input and textarea)

      if (!gridOptions.enableTextSelectionOnCells) {
        // disable text selection in grid cells except in input and textarea elements
        // (this is IE-specific, because selectstart event will only fire in IE)
        $viewport.onSelectStart.listen((event) {  //  bind("selectstart.ui",
          return event.target is dom.InputElement || (event.target as dom.HtmlElement) is dom.TextAreaElement;
        });
      }

      updateColumnCaches();
      createColumnHeaders();
      setupColumnSort();
      createCssRules();
      resizeCanvas();
      bindAncestorScrollEvents();

      $container.on["resize.bwu-datagrid"].listen(resizeCanvas);
      //$viewport
          //.bind("click", handleClick)
      $viewport.onScroll.listen(handleScroll);
      $headerScroller..onContextMenu.listen(handleHeaderContextMenu)
          ..onClick.listen(handleHeaderClick)
          ..querySelectorAll(".bwu-datagrid-header-column").forEach((e) {
            (e as dom.HtmlElement)
            ..onMouseEnter.listen(handleHeaderMouseEnter)
            ..onMouseLeave.listen(handleHeaderMouseLeave);
      });
      $headerRowScroller
          .onScroll.listen(handleHeaderRowScroll);
      $focusSink
          ..append($focusSink2)
          ..onKeyDown.listen(handleKeyDown);
      $canvas
          ..onKeyDown.listen(handleKeyDown)
          ..onClick.listen(handleClick)
          ..onDoubleClick.listen(handleDblClick)
          ..onContextMenu.listen(handleContextMenu)
          //..bind("draginit", handleDragInit) // TODO
          ..onDragStart.listen((e) {/*{distance: 3}*/; handleDragStart(e, {'distance': 3});}) // TODO what is distance?
          ..onDrag.listen(handleDrag)
          ..onDragEnd.listen(handleDragEnd)
          ..querySelectorAll(".bwu-datagrid--cell").forEach((e) {
            (e as dom.HtmlElement)
              ..onMouseEnter.listen(handleMouseEnter)
              ..onMouseLeave.listen(handleMouseLeave);
          });

      // Work around http://crbug.com/312427.
      if (dom.window.navigator.userAgent.toLowerCase().contains('webkit') &&
          dom.window.navigator.userAgent.toLowerCase().contains('macintosh')) {
        $canvas.onMouseWheel.listen(handleMouseWheel);
      }
    }
  }

  void registerPlugin(Plugin plugin) {
    plugins.insert(0, plugin);
    plugin.init(this);
  }

  void unregisterPlugin(Plugin plugin) {
    for (var i = plugins.length; i >= 0; i--) {
      if (plugins[i] == plugin) {
        plugins[i].destroy();
        plugins.removeAt(i);
        break;
      }
    }
  }

  async.StreamSubscription onSelectedRangesChanged;
  void setSelectionModel(SelectionModel model) {
    if (selectionModel != null) {
      if(onSelectedRangesChanged != null) {
        onSelectedRangesChanged.cancel(); //selectionModel.onSelectedRangesChanged.unsubscribe(handleSelectedRangesChanged);
      }
      selectionModel.destroy();
    }

    selectionModel = model;
    if (selectionModel != null) {
      selectionModel.init(this);
      onSelectedRangesChanged = selectionModel.onSelectedRangesChanged.listen(handleSelectedRangesChanged);
    }
  }

  SelectionModel get getSelectionModel => selectionModel;

  dom.HtmlElement get getCanvasNode => $canvas.children[0];

  math.Point measureScrollbar() {
    dom.HtmlElement $c = new dom.Element.html("<div style='position:absolute; top:-10000px; left:-10000px; width:100px; height:100px; overflow:scroll;'></div>", validator: nodeValidator);
    dom.document.body.append($c);
    var dim = new math.Point(int.parse($c.style.width) - $c.children[0].clientWidth, int.parse($c.style.height) - $c.children[0].clientHeight);
    $c.remove();
    return dim;
  }

  int getHeadersWidth() {
    var headersWidth = 0;
    int ii = columns.length;
    for (int i = 0;  i < ii; i++) {
      int width = columns[i].width;
      headersWidth += width;
    }
    headersWidth += scrollbarDimensions.x;
    return math.max(headersWidth, viewportW) + 1000;
  }

  int getCanvasWidth() {
    double availableWidth = viewportHasVScroll ? viewportW - scrollbarDimensions.x : viewportW;
    int rowWidth = 0;
    int i = columns.length;
    while (i-- > 0) {
      rowWidth += columns[i].width;
    }
    return gridOptions.fullWidthRows ? math.max(rowWidth, availableWidth) : rowWidth;
  }

  void updateCanvasWidth(forceColumnWidthsUpdate) {
    int oldCanvasWidth = canvasWidth;
    canvasWidth = getCanvasWidth();

    if (canvasWidth != oldCanvasWidth) {
      $canvas.style.width = "$canvasWidth";
      $headerRow.style.width = "$canvasWidth";
      $headers.style.width = "${getHeadersWidth()}";
      viewportHasHScroll = (canvasWidth > viewportW - scrollbarDimensions.x);
    }

    $headerRowSpacer.style.width = "${(canvasWidth + (viewportHasVScroll ? scrollbarDimensions.x : 0))}";

    if (canvasWidth != oldCanvasWidth || forceColumnWidthsUpdate) {
      applyColumnWidths();
    }
  }

  void disableSelection(dom.HtmlElement $target) {
    if ($target != null) {
      $target
        ..attributes["unselectable"] = "on"
        ..style.userSelect= "none"
        ..onSelectStart.listen((e) {
          e
           ..stopPropagation()
           ..stopImmediatePropagation();
        }); // bind("selectstart.ui", function () {
    }
  }

  int getMaxSupportedCssHeight() {
    int supportedHeight = 1000000;
    // FF reports the height back but still renders blank after ~6M px
    int testUpTo = dom.window.navigator.userAgent.toLowerCase().contains('firefox') ? 6000000 : 1000000000; // TODO check match
    var div = new dom.Element.html("<div style='display:none' />", validator: nodeValidator);
    dom.document.body.append(div);

    while (true) {
      int test = supportedHeight * 2;
      div.style.height = test;
      if (test > testUpTo || div.style.height != test) { // parse height
        break;
      } else {
        supportedHeight = test;
      }
    }

    div.remove();
    return supportedHeight;
  }

  // TODO:  this is static.  need to handle page mutation.
  void bindAncestorScrollEvents() {
    var elem = $canvas.children[0];
    while ((elem = elem.parentNode) != dom.document.body && elem != null) {
      // bind to scroll containers only
      if (elem == $viewport.children[0] || elem.scrollWidth != elem.clientWidth || elem.scrollHeight != elem.clientHeight) {
        var $elem = elem;
        if ($boundAncestors == null) {
          $boundAncestors = $elem;
        } else {
          $boundAncestors.add($elem);
        }
        $elem.bind("scroll.${uid}", handleActiveCellPositionChange);
      }
    }
  }

  void unbindAncestorScrollEvents() {
    if ($boundAncestors == null) {
      return;
    }
    $boundAncestors.unbind("scroll." + uid);
    $boundAncestors = null;
  }

  void updateColumnHeader(String columnId, String title, String toolTip) {
    if (!initialized) { return; }
    var idx = getColumnIndex(columnId);
    if (idx == null) {
      return;
    }

    Column columnDef = columns[idx];
    dom.HtmlElement $header = $headers.children.firstWhere((e) => e.id == idx); //().eq(idx); // TODO check
    if ($header != null) {
      if (title != null) {
        columns[idx].name = title;
      }
      if (toolTip != null) {
        columns[idx].toolTip = toolTip;
      }

      fire(ON_BEFORE_HEADER_CELL_DESTROY, detail: {
        "node": $header.children[0],
        "column": columnDef
      });

      $header
          ..attributes["title"] = toolTip != null ? toolTip : ""
          ..children.where((e) => e.id == 0).forEach((e) => e.innerHtml = title); //().eq(0).html(title); // TODO check

      fire(ON_HEADER_CELL_RENDERED, detail: {
        "node": $header.children[0],
        "column": columnDef
      });
    }
  }

  dom.HtmlElement getHeaderRow() {
    return $headerRow.children[0];
  }

  dom.HtmlElement getHeaderRowColumn(columnId) {
    var idx = getColumnIndex(columnId);
    dom.HtmlElement $header = $headerRow.children.firstWhere((e) => e == idx); //.eq(idx); // TODO check
    if($header != null && $header.children.length > 0) {
      return $header.children[0];
    }
    return null;
  }

  void createColumnHeaders() {
    var onMouseEnter = (dom.MouseEvent e) {
      classes.add("ui-state-hover");
    };

    var onMouseLeave = (dom.MouseEvent e) {
      classes.remove("ui-state-hover");
    };

    $headers.querySelectorAll(".bwu-datagrid-header-column")
      .forEach((dom.HtmlElement e) { // TODO check self/this
        var columnDef = e.dataset["column"];
        if (columnDef != null) {
          fire(ON_BEFORE_HEADER_CELL_DESTROY, detail: {
            "node": e,
            "column": columnDef
          });
        }
      });
    $headers.children.clear();
    $headers.style.width = "${getHeadersWidth()}";

    $headerRow.querySelectorAll(".bwu-datagrid-headerrow-column")
      .forEach((dom.HtmlElement e) { // TODO check self/this
        var columnDef = e.dataset["column"];
        if (columnDef) {
          fire(ON_BEFORE_HEADER_CELL_DESTROY, detail: {
            "node": e,
            "column": columnDef
          });
        }
      });
    $headerRow.children.clear();

    for (int i = 0; i < columns.length; i++) {
      Column m = columns[i];

      var header = new dom.Element.html("<div class='ui-state-default slick-header-column' />", validator: nodeValidator)
          ..append(new dom.Element.html("<span class='slick-column-name'>" + m.name + "</span>", validator: nodeValidator))
          ..style.width = "${m.width - headerColumnWidthDiff}"
          ..attributes["id"] ='${uid}${m.id}'
          ..attributes["title"] = m.toolTip != null ? m.toolTip : ""
          ..dataset["column"] = m // TODO
          ..classes.add(m.headerCssClass != null ? m.headerCssClass : "");
      $headers.append(header);

      if (gridOptions.enableColumnReorder || m.sortable) {
        header
          ..onMouseEnter.listen(onMouseEnter)
          ..onMouseLeave.listen(onMouseLeave);
      }

      if (m.sortable) {
        header.classes.add("bwu-datagrid-header-sortable");
        header.append(new dom.Element.html("<span class='slick-sort-indicator' />", validator: nodeValidator));
      }

      fire(ON_HEADER_CELL_RENDERED, detail: {
        "node": header.children[0],
        "column": m
      });

      if (gridOptions.showHeaderRow) {
        var headerRowCell = new dom.Element.html("<div class='ui-state-default slick-headerrow-column l${i} r${i}'></div>", validator: nodeValidator)
            ..dataset["column"] =  m;
            $headerRow.append(headerRowCell);

        fire(ON_HEADER_ROW_CELL_RENDERED, detail: {
          "node": headerRowCell.children[0],
          "column": m
        });
      }
    }

    setSortColumns(sortColumns);
    setupColumnResize();
    if (gridOptions.enableColumnReorder) {
      setupColumnReorder();
    }
  }

  void setupColumnSort() {
    $headers.onClick.listen((e) {
      // temporary workaround for a bug in jQuery 1.7.1 (http://bugs.jquery.com/ticket/11328)
      e.metaKey = e.metaKey || e.ctrlKey;

      if ((e.target as dom.HtmlElement).classes.contains("bwu-datagrid-resizable-handle")) {
        return;
      }

      dom.HtmlElement $col = (e.target as dom.HtmlElement).querySelector(".slick-header-column"); // TODO check var $col = $(e.target).closest(".slick-header-column");
      if ($col.children.length > 0) {
        return;
      }

      Column column = $col.dataset["column"];
      if (column.sortable) {
        if (!getEditorLock.commitCurrentEdit()) {
          return;
        }

        SortColumn sortOpts = null;
        var i = 0;
        for (; i < sortColumns.length; i++) {
          if (sortColumns[i].columnId == column.id) {
            sortOpts = sortColumns[i];
            sortOpts.sortAsc = !sortOpts.sortAsc;
            break;
          }
        }

        if (e.metaKey && gridOptions.multiColumnSort) {
          if (sortOpts != null) {
            sortColumns.removeAt(i);
          }
        }
        else {
          if ((!e.shiftKey && !e.metaKey) || !gridOptions.multiColumnSort) {
            sortColumns = [];
          }

          if (sortOpts == null) {
            sortOpts = new SortColumn(column.id,column.defaultSortAsc);
            sortColumns.add(sortOpts);
          } else if (sortColumns.length == 0) {
            sortColumns.add(sortOpts);
          }
        }

        setSortColumns(sortColumns);

        if (!gridOptions.multiColumnSort) {
          fire(ON_SORT, detail: {
            'multiColumnSort': false,
            'sortCol': column,
            'sortAsc': sortOpts.sortAsc,
            'caused_by': e});
        } else {
          fire(ON_SORT, detail: {
            'multiColumnSort': true,
            'sortCols': $.map(sortColumns, (col) { // TODO map
              return {'sortCol': columns[getColumnIndex(col.columnId)], 'sortAsc': col.sortAsc };
            }),
            'caused_by': e});
        }
      }
    });
  }

  void setupColumnReorder() {
    $headers.filter(":ui-sortable").sortable("destroy");
    $headers.sortable({
      'containment': "parent",
      'distance': 3,
      'axis': "x",
      'cursor': "default",
      'tolerance': "intersection",
      'helper': "clone",
      'placeholder': "slick-sortable-placeholder ui-state-default slick-header-column",
      'start': (e, ui) {
        ui.placeholder.width(ui.helper.outerWidth() - headerColumnWidthDiff);
        (ui.helper as dom.HtmlElement).classes.add("beu-datagrid-header-column-active");
      },
      'beforeStop': (e, ui) {
        (ui.helper as dom.HtmlElement).classes.remove("bwu-datagrid-header-column-active");
      },
      'stop': (e) {
        if (!getEditorLock.commitCurrentEdit()) {
          $(this).sortable("cancel"); // TODO
          return;
        }

        var reorderedIds = $headers.sortable("toArray");
        var reorderedColumns = [];
        for (var i = 0; i < reorderedIds.length; i++) {
          reorderedColumns.push(columns[getColumnIndex(reorderedIds[i].replace(uid, ""))]);
        }
        setColumns(reorderedColumns);

        fire(ON_COLUMNS_REORDERED, detail: {});
        e.stopPropagation();
        setupColumnResize();
      }
    });
  }

  void setupColumnResize() {
    dom.HtmlElement $col;
    int j;
    Column c;
    int pageX;
    List<dom.HtmlElement> columnElements;
    int minPageX, maxPageX;
    int firstResizable, lastResizable;
    columnElements = $headers.children;
    $headers.querySelectorAll(".bwu-datagrid-resizable-handle").forEach((dom.HtmlElement e) {
      e.remove();
    });
    int i = 0;
    columnElements.forEach((e) {
      if (columns[i].resizable) {
        if (firstResizable == null) {
          firstResizable = i;
        }
        lastResizable = i;
      }
      i++;
    });
    if (firstResizable == null) {
      return;
    }
    i = 0;
    columnElements.forEach((e) {
      if (i < firstResizable || (gridOptions.forceFitColumns && i >= lastResizable)) {
        return;
      }
      $col = (e as dom.HtmlElement);
      var div = new dom.Element.html("<div class='bwu-datagrid-resizable-handle' />", validator: nodeValidator);
      e.append(div);
          div..onDragStart.listen((dom.MouseEvent e) {
            // TODO dd = e.detail ??
            if (!getEditorLock.commitCurrentEdit()) {
              return false;
            }
            pageX = e.pageX;
            (e as dom.HtmlElement).parent.classes.add("bwu-datagrid-header-column-active");
            int shrinkLeewayOnRight = null, stretchLeewayOnRight = null;
            // lock each column's width option to current width
            int i = 0;
            columnElements.forEach((e) {
              var cs = (e as dom.HtmlElement).getComputedStyle();
              columns[i].previousWidth = int.parse(cs.width) + int.parse(cs.borderLeft) + int.parse(cs.borderRight);
              i++;
            });
            if (gridOptions.forceFitColumns) {
              shrinkLeewayOnRight = 0;
              stretchLeewayOnRight = 0;
              // colums on right affect maxPageX/minPageX
              for (j = i + 1; j < columnElements.length; j++) {
                c = columns[j];
                if (c.resizable) {
                  if (stretchLeewayOnRight != null) {
                    if (c.maxWidth > 0) {
                      stretchLeewayOnRight += c.maxWidth - c.previousWidth;
                    } else {
                      stretchLeewayOnRight = null;
                    }
                  }
                  shrinkLeewayOnRight += c.previousWidth - math.max(c.minWidth != null ? c.minWidth : 0, absoluteColumnMinWidth);
                }
              }
            }
            int shrinkLeewayOnLeft = 0, stretchLeewayOnLeft = 0;
            for (j = 0; j <= i; j++) {
              // columns on left only affect minPageX
              c = columns[j];
              if (c.resizable) {
                if (stretchLeewayOnLeft != null) {
                  if (c.maxWidth > 0) {
                    stretchLeewayOnLeft += c.maxWidth - c.previousWidth;
                  } else {
                    stretchLeewayOnLeft = null;
                  }
                }
                shrinkLeewayOnLeft += c.previousWidth - math.max(c.minWidth != null ? c.minWidth : 0, absoluteColumnMinWidth);
              }
            }
            if (shrinkLeewayOnRight == null) {
              shrinkLeewayOnRight = 100000;
            }
            if (shrinkLeewayOnLeft == null) {
              shrinkLeewayOnLeft = 100000;
            }
            if (stretchLeewayOnRight == null) {
              stretchLeewayOnRight = 100000;
            }
            if (stretchLeewayOnLeft == null) {
              stretchLeewayOnLeft = 100000;
            }
            maxPageX = pageX + math.min(shrinkLeewayOnRight, stretchLeewayOnLeft);
            minPageX = pageX - math.min(shrinkLeewayOnLeft, stretchLeewayOnRight);
          })
          ..onDrag.listen((e) {
            // TODO dd = e.detail ??
            var actualMinWidth, d = math.min(maxPageX, math.max(minPageX, e.pageX)) - pageX, x;
            if (d < 0) { // shrink column
              x = d;
              for (j = i; j >= 0; j--) {
                c = columns[j];
                if (c.resizable) {
                  actualMinWidth = math.max(c.minWidth != null ? c.minWidth : 0, absoluteColumnMinWidth);
                  if (x && c.previousWidth + x < actualMinWidth) {
                    x += c.previousWidth - actualMinWidth;
                    c.width = actualMinWidth;
                  } else {
                    c.width = c.previousWidth + x;
                    x = 0;
                  }
                }
              }

              if (gridOptions.forceFitColumns) {
                x = -d;
                for (j = i + 1; j < columnElements.length; j++) {
                  c = columns[j];
                  if (c.resizable) {
                    if (x && c.maxWidth && (c.maxWidth - c.previousWidth < x)) {
                      x -= c.maxWidth - c.previousWidth;
                      c.width = c.maxWidth;
                    } else {
                      c.width = c.previousWidth + x;
                      x = 0;
                    }
                  }
                }
              }
            } else { // stretch column
              x = d;
              for (j = i; j >= 0; j--) {
                c = columns[j];
                if (c.resizable) {
                  if (x && c.maxWidth && (c.maxWidth - c.previousWidth < x)) {
                    x -= c.maxWidth - c.previousWidth;
                    c.width = c.maxWidth;
                  } else {
                    c.width = c.previousWidth + x;
                    x = 0;
                  }
                }
              }

              if (gridOptions.forceFitColumns) {
                x = -d;
                for (j = i + 1; j < columnElements.length; j++) {
                  c = columns[j];
                  if (c.resizable) {
                    actualMinWidth = math.max(c.minWidth != 0 ? c.minWidth : 0, absoluteColumnMinWidth);
                    if (x && c.previousWidth + x < actualMinWidth) {
                      x += c.previousWidth - actualMinWidth;
                      c.width = actualMinWidth;
                    } else {
                      c.width = c.previousWidth + x;
                      x = 0;
                    }
                  }
                }
              }
            }
            applyColumnHeaderWidths();
            if (gridOptions.syncColumnCellResize) {
              applyColumnWidths();
            }
          })
          ..onDragEnd.listen((e) {
            // TODO dd = e.detail ??
            var newWidth;
            (e as dom.HtmlElement).parent.classes.add("bwu-datagrid-header-column-active");
            for (j = 0; j < columnElements.length; j++) {
              c = columns[j];
              var cs = columnElements[j].getComputedStyle();
              newWidth = cs.width + cs.borderLeft + cs.borderRight;

              if (c.previousWidth != newWidth && c.rerenderOnResize) {
                invalidateAllRows();
              }
            }
            updateCanvasWidth(true);
            render();
            fire(ON_COLUMNS_RESIZED, detail: {});
          });
        i++;
    });
  }

  int getVBoxDelta(dom.HtmlElement $el) {
    var p = ["borderTopWidth", "borderBottomWidth", "paddingTop", "paddingBottom"];
    var delta = 0;
    p.forEach((prop) {

      delta += double.parse($el.style.getPropertyValue(prop)); // || 0; // TODO
    });
    return delta;
  }

  void measureCellPaddingAndBorder() {
    var el;
    var h = ["borderLeftWidth", "borderRightWidth", "paddingLeft", "paddingRight"];
    var v = ["borderTopWidth", "borderBottomWidth", "paddingTop", "paddingBottom"];

    el = new dom.Element.html("<div class='ui-state-default slick-header-column' style='visibility:hidden'>-</div>", validator: nodeValidator);
    $headers.append(el);
    headerColumnWidthDiff = headerColumnHeightDiff = 0;
    if (el.style.boxSizing != "border-box") {
      h.forEach((prop) {
        headerColumnWidthDiff += double.parse(el.style.getPropertyValue(prop)); // || 0; // TODO
      });
      v.forEach((prop) {
        headerColumnHeightDiff += double.parse(el.style.getPropertyValue(prop)); //; || 0; // TODO
      });
    }
    el.remove();

    var r = new dom.Element.html("<div class='slick-row' />", validator: nodeValidator);
    $canvas.append(r);
    el = new dom.Element.html("<div class='slick-cell' id='' style='visibility:hidden'>-</div>", validator: nodeValidator);
    r.append(el);
    cellWidthDiff = cellHeightDiff = 0;
    if (el.style.boxSizing != "border-box") {
      h.forEach((prop) {
        var val = double.parse(el.style.getPropertyValue(prop));
        cellWidthDiff += val != null ? val : 0; // TODO
      });
      v.forEach((prop) {
        var val = double.parse(el.style.getPropertyValue(prop));
        cellHeightDiff += val != null ? val : 0; // TODO
      });
    }
    r.remove();

    absoluteColumnMinWidth = math.max(headerColumnWidthDiff, cellWidthDiff);
  }

  void createCssRules() {
    $style = new dom.Element.html("<style type='text/css' rel='stylesheet' />", validator: nodeValidator);
    dom.document.head.append($style);
    var rowHeight = (gridOptions.rowHeight - cellHeightDiff);
    var rules = [
      ".${uid} .bwu-datagrid-header-column { left: 1000px; }",
      ".${uid} .bwu-datagrid-top-panel { height:${gridOptions.topPanelHeight}px; }",
      ".${uid} .bwu-datagrid-headerrow-columns { height:${gridOptions.headerRowHeight}px; }",
      ".${uid} .bwu-datagrid-cell { height:${rowHeight}px; }",
      ".${uid} .bwu-datagrid-row { height:${gridOptions.rowHeight}px; }"
    ];

    for (int i = 0; i < columns.length; i++) {
      rules.add(".${uid} .l${i} { }");
      rules.add(".${uid} .r${i} { }");
    }

    $style.children[0].appendText(rules.join(" "));
  }

  Map<String,dom.CssStyleRule> getColumnCssRules(int idx) {
    if (stylesheet == null) {
      var sheets = dom.document.styleSheets;
      for (int i = 0; i < sheets.length; i++) {
        if ((sheets[i].ownerNode || sheets[i].ownerNode) == $style.children[0]) {
          stylesheet = sheets[i];
          break;
        }
      }

      if (stylesheet == null) {
        throw "Cannot find stylesheet.";
      }

      // find and cache column CSS rules
      columnCssRulesL = [];
      columnCssRulesR = [];
      var cssRules = (stylesheet.cssRules || stylesheet.rules);
      var matches, columnIdx;
      for (var i = 0; i < cssRules.length; i++) {
        var selector = cssRules[i].selectorText;
        matches = new RegExp(r'\.l\d+').allMatches(selector);
        if (matches.length > 0) {
          columnIdx = int.parse(matches[0].substr(2, matches[0].length - 2), radix: 10);
          columnCssRulesL[columnIdx] = cssRules[i];
        } else {
          matches = new RegExp(r'\.r\d+').allMatches(selector);
          if (matches.length > 0) {
            columnIdx = int.parse(matches[0].substr(2, matches[0].length - 2), radix: 10);
            columnCssRulesR[columnIdx] = cssRules[i];
          }
        }
      }
    }

    return {
      "left": columnCssRulesL[idx],
      "right": columnCssRulesR[idx]
    };
  }

  void removeCssRules() {
    $style.remove();
    stylesheet = null;
  }

  void destroy() {
    getEditorLock.cancelCurrentEdit();

    fire(ON_BEFORE_DESTROY, detail: {});

    var i = plugins.length;
    while(i--) {
      unregisterPlugin(plugins[i]);
    }

    if (gridOptions.enableColumnReorder) {
        $headers.filter(":ui-sortable").sortable("destroy"); // TODO
    }

    unbindAncestorScrollEvents();
    // $container.unbind(".bwu-datagrid"); // TODO
    removeCssRules();

    // $canvas.unbind("draginit dragstart dragend drag"); // TODO
    $container
        ..children.clear()
        ..classes.remove(uid);
  }


  //////////////////////////////////////////////////////////////////////////////////////////////
  // General

//  function trigger(evt, args, e) {
//    e = e || new Slick.EventData();
//    args = args || {};
//    args.grid = self;
//    return evt.notify(args, e, self);
//  }

  EditorLock get getEditorLock => gridOptions.editorLock;

  EditController get getEditController => editController;

  int getColumnIndex(id) => columnsById[id];

  void autosizeColumns() {
    int i;
    Column c;
    List<int> widths = [];
    int shrinkLeeway = 0;
    int total = 0;
    int prevTotal;
    double availWidth = viewportHasVScroll ? viewportW - scrollbarDimensions.x : viewportW;

    for (i = 0; i < columns.length; i++) {
      c = columns[i];
      widths.add(c.width);
      total += c.width;
      if (c.resizable) {
        shrinkLeeway += c.width - math.max(c.minWidth, absoluteColumnMinWidth);
      }
    }

    // shrink
    prevTotal = total;
    while (total > availWidth && shrinkLeeway) {
      double shrinkProportion = (total - availWidth) / shrinkLeeway;
      for (i = 0; i < columns.length && total > availWidth; i++) {
        c = columns[i];
        var width = widths[i];
        if (!c.resizable || width <= c.minWidth || width <= absoluteColumnMinWidth) {
          continue;
        }
        var absMinWidth = math.max(c.minWidth, absoluteColumnMinWidth);
        var shrinkSize = (shrinkProportion * (width - absMinWidth)).floor();
        if(shrinkSize == 0) {
          shrinkSize = 1;
        }
        shrinkSize = math.min(shrinkSize, width - absMinWidth);
        total -= shrinkSize;
        shrinkLeeway -= shrinkSize;
        widths[i] -= shrinkSize;
      }
      if (prevTotal <= total) {  // avoid infinite loop
        break;
      }
      prevTotal = total;
    }

    // grow
    prevTotal = total;
    while (total < availWidth) {
      var growProportion = availWidth / total;
      for (i = 0; i < columns.length && total < availWidth; i++) {
        c = columns[i];
        var currentWidth = widths[i];
        var growSize;

        if (!c.resizable || c.maxWidth <= currentWidth) {
          growSize = 0;
        } else {
          var tmp = (c.maxWidth - currentWidth > 0 ? c.maxWidth - currentWidth : 1000000);
          growSize = math.min((growProportion * currentWidth).floor() - currentWidth, tmp);
          if(growSize == 0) {
            growSize = 1;
          }
        }
        total += growSize;
        widths[i] += growSize;
      }
      if (prevTotal >= total) {  // avoid infinite loop
        break;
      }
      prevTotal = total;
    }

    var reRender = false;
    for (i = 0; i < columns.length; i++) {
      if (columns[i].rerenderOnResize && columns[i].width != widths[i]) {
        reRender = true;
      }
      columns[i].width = widths[i];
    }

    applyColumnHeaderWidths();
    updateCanvasWidth(true);
    if (reRender) {
      invalidateAllRows();
      render();
    }
  }

  void applyColumnHeaderWidths() {
    if (!initialized) { return; }
    var h;
    for (int i = 0; i < $headers.children.length; i++) {
      h = $headers.children[i];
      if (h.style.width != columns[i].width - headerColumnWidthDiff) {
        h.style.width = columns[i].width - headerColumnWidthDiff;
      }
    }

    updateColumnCaches();
  }

  void applyColumnWidths() {
    int x = 0;
    int w;
    Map<String,dom.CssStyleRule> rule;
    for (var i = 0; i < columns.length; i++) {
      w = columns[i].width;

      rule = getColumnCssRules(i);
      rule['left'].style.left = '${x}px';
      rule['right'].style.right = '${(canvasWidth - x - w)}px';

      x += columns[i].width;
    }
  }

  void setSortColumn(int columnId, bool ascending) {
    setSortColumns([{ 'columnId': columnId, 'sortAsc': ascending}]);
  }

  void setSortColumns(List<SortColumn> cols) {
    sortColumns = cols;

    var headerColumnEls = $headers.children;
    headerColumnEls
        ..classes.remove("bwu-datagrid-header-column-sorted")
        .querySelectorAll(".bwu-datagrid-sort-indicator").forEach((dom.HtmlElement e) =>
            e.classes
            ..remove('bwu-datagrid-sort-indicator-asc')
            ..remove('bwu-datagrid-sort-indicator-desc'));

    sortColumns.forEach((col) {
      if (col.sortAsc == null) {
        col.sortAsc = true;
      }
      var columnIndex = getColumnIndex(col.columnId);
      if (columnIndex != null) {
        headerColumnEls.eq(columnIndex) // TODO
            .addClass("slick-header-column-sorted")
            .find(".slick-sort-indicator")
                .addClass(col.sortAsc ? "slick-sort-indicator-asc" : "slick-sort-indicator-desc");
      }
    });
  }

  List<SortColumn> get getSortColumns => sortColumns;

  void handleSelectedRangesChanged(dom.CustomEvent e, List<Range> ranges) {
    selectedRows = [];
    List<Map<String,String>> hash = [];
    for (var i = 0; i < ranges.length; i++) {
      for (var j = ranges[i].fromRow; j <= ranges[i].toRow; j++) {
        if (hash[j] == null) {  // prevent duplicates
          selectedRows.add(j);
          hash[j] = {};
        }
        for (var k = ranges[i].fromCell; k <= ranges[i].toCell; k++) {
          if (canCellBeSelected(j, k)) {
            hash[j][columns[k].id] = gridOptions.selectedCellCssClass;
          }
        }
      }
    }

    setCellCssStyles(gridOptions.selectedCellCssClass, hash);

    fire(ON_SELECTED_ROWS_CHANGED , detail:{'rows': getSelectedRows(), 'caused_by': e});
  }

  List<Column> get getColumns => columns;

  void updateColumnCaches() {
    // Pre-calculate cell boundaries.
    columnPosLeft = [];
    columnPosRight = [];
    var x = 0;
    for (var i = 0; i < columns.length; i++) {
      columnPosLeft[i] = x;
      columnPosRight[i] = x + columns[i].width;
      x += columns[i].width;
    }
  }

  void setColumns(List<Column> columnDefinitions) {
    columns = columnDefinitions;

    columnsById = {};
    for (var i = 0; i < columns.length; i++) {
      var m = columns[i] = $.extend({}, columnDefaults, columns[i]);
      columnsById[m.id] = i;
      if (m.minWidth && m.width < m.minWidth) {
        m.width = m.minWidth;
      }
      if (m.maxWidth && m.width > m.maxWidth) {
        m.width = m.maxWidth;
      }
    }

    updateColumnCaches();

    if (initialized) {
      invalidateAllRows();
      createColumnHeaders();
      removeCssRules();
      createCssRules();
      resizeCanvas();
      applyColumnWidths();
      handleScroll();
    }
  }

  GridOptions get getOptions => gridOptions;

  void set setOptions(GridOptions args) {
    if (!getEditorLock.commitCurrentEdit()) {
      return;
    }

    makeActiveCellNormal();

    if (gridOptions.enableAddRow != args.enableAddRow) {
      invalidateRow(getDataLength);
    }

    gridOptions = $.extend(gridOptions, args); // TODO
    validateAndEnforceOptions();

    $viewport.style.overflowY = gridOptions.autoHeight != "" ? "hidden" : "auto";
    render();
  }

  void validateAndEnforceOptions() {
    if (gridOptions.autoHeight) {
      gridOptions.leaveSpaceForNewRows = false;
    }
  }

  void setData(Data newData, bool scrollToTop) {
    data = newData;
    invalidateAllRows();
    updateRowCount();
    if (scrollToTop) {
      scrollTo(0);
    }
  }

  Data get getData => data;

  int get getDataLength {
    if (data.getLength) {
      return data.length;
    } else {
      return data.length;
    }
  }

  int getDataLengthIncludingAddNew() {
    return getDataLength + (gridOptions.enableAddRow ? 1 : 0);
  }

  Item getDataItem(int i) => data[i];

  dom.HtmlElement get getTopPanel => $topPanel.children[0];

  void set setTopPanelVisibility(visible) {
    if (gridOptions.showTopPanel != visible) {
      gridOptions.showTopPanel = visible;
      if (visible) {
        $topPanelScroller.slideDown("fast", resizeCanvas);
      } else {
        $topPanelScroller.slideUp("fast", resizeCanvas);
      }
    }
  }

  void set setHeaderRowVisibility(bool visible) {
    if (gridOptions.showHeaderRow != visible) {
      gridOptions.showHeaderRow = visible;
      if (visible) {
        $headerRowScroller.slideDown("fast", resizeCanvas);
      } else {
        $headerRowScroller.slideUp("fast", resizeCanvas);
      }
    }
  }

  dom.HtmlElement get getContainerNode => $container.children[0];

  //////////////////////////////////////////////////////////////////////////////////////////////
  // Rendering / Scrolling

  int getRowTop(int row) {
    return gridOptions.rowHeight * row - pageOffset;
  }

  int getRowFromPosition(int y) {
    return ((y + pageOffset) / gridOptions.rowHeight).floor();
  }

  void scrollTo(int y) {
    y = math.max(y, 0);
    y = math.min(y, th - viewportH + (viewportHasHScroll ? scrollbarDimensions.y : 0));

    var oldOffset = pageOffset;

    page = math.min(n - 1, (y / ph).floor());
    pageOffset = (page * cj).round();
    int newScrollTop = y - pageOffset;

    if (pageOffset != oldOffset) {
      var range = getVisibleRange(newScrollTop);
      cleanupRows(range);
      updateRowPositions();
    }

    if (prevScrollTop != newScrollTop) {
      vScrollDir = (prevScrollTop + oldOffset < newScrollTop + pageOffset) ? 1 : -1;
      $viewport.children[0].scrollTop = (lastRenderedScrollTop = scrollTop = prevScrollTop = newScrollTop);

      this.fire(BwuDatagrid.ON_VIEWPORT_CHANGED, detail: {});
      //trigger(self.onViewportChanged, {});
    }
  }

  String defaultFormatter(int row, int cell, int value, int columnDef, int dataContext) {
    if (value == null) {
      return "";
    } else {
      return '$value'.replaceAll(r'&',"&amp;").replaceAll(r'<',"&lt;").replaceAll(r'>',"&gt;");
    }
  }

  Function getFormatter(row, column) {
    var rowMetadata = data.getItemMetadata != null && data.getItemMetadata(row);

    // look up by id, then index
    var columnOverrides = rowMetadata &&
        rowMetadata.columns &&
        (rowMetadata.columns[column.id] || rowMetadata.columns[getColumnIndex(column.id)]);

    var result = (columnOverrides != null && columnOverrides.formatter != null) ? columnOverrides.formatter :
        (rowMetadata != null && rowMetadata.formatter != null ? rowMetadata.formatter :
        column.formatter); // TODO check
    if(result == null) {
      if(gridOptions.formatterFactory) {
        result = gridOptions.formatterFactory.getFormatter(column);
      }
    }
    if(result == null) {
        result = gridOptions.defaultFormatter;
    }
    return result;
  }

  int getEditor(int row, int cell) {
    var column = columns[cell];
    var rowMetadata = data.getItemMetadata && data.getItemMetadata(row);
    var columnMetadata = rowMetadata != null ? rowMetadata.columns : null;

    if (columnMetadata && columnMetadata[column.id] && columnMetadata[column.id].editor != null) {
      return columnMetadata[column.id].editor;
    }
    if (columnMetadata && columnMetadata[cell] && columnMetadata[cell].editor != null) {
      return columnMetadata[cell].editor;
    }

    return column.editor != null ? column.editor : (gridOptions.editorFactory && gridOptions.editorFactory.getEditor(column));
  }

  String getDataItemValueForColumn(Item item, ColumnDefinition columnDef) {
    if (gridOptions.dataItemColumnValueExtractor != null) {
      return gridOptions.dataItemColumnValueExtractor(item, columnDef);
    }
    return item[columnDef.field];
  }

  void appendRowHtml(List<String> stringArray, int row, Map<String,int> range, int dataLength) {
    var d = getDataItem(row);
    var dataLoading = row < dataLength && !d;
    var rowCss = "bwu-datagrid-row" +
        (dataLoading ? " loading" : "") +
        (row == activeRow ? " active" : "") +
        (row % 2 == 1 ? " odd" : " even");

    if (!d) {
      "${rowCss} ${gridOptions.addNewRowCssClass}";
    }

    var metadata = data.getItemMetadata && data.getItemMetadata(row);

    if (metadata != null && metadata.cssClasses != null) {
      "${rowCss} ${metadata.cssClasses}";
    }

    stringArray.add("<div class='ui-widget-content ${rowCss}' style='top:${getRowTop(row)}px'>");

    var colspan, m;
    for (var i = 0, ii = columns.length; i < ii; i++) {
      m = columns[i];
      colspan = 1;
      if (metadata && metadata.columns) {
        var columnData = metadata.columns[m.id] || metadata.columns[i];
        colspan = (columnData && columnData.colspan) || 1;
        if (colspan == "*") {
          colspan = ii - i;
        }
      }

      // Do not render cells outside of the viewport.
      if (columnPosRight[math.min(ii - 1, i + colspan - 1)] > range['leftPx']) {
        if (columnPosLeft[i] > range['rightPx']) {
          // All columns to the right are outside the range.
          break;
        }

        appendCellHtml(stringArray, row, i, colspan, d);
      }

      if (colspan > 1) {
        i += (colspan - 1);
      }
    }

    stringArray.add("</div>");
  }

  void appendCellHtml(List<String>stringArray, int row, int cell, int colspan, Item item) {
    var m = columns[cell];
    var cellCss = "slick-cell l${cell} r${math.min(columns.length - 1, cell + colspan - 1) +
        (m.cssClass != null ? m.cssClass : '')}";
    if (row == activeRow && cell == activeCell) {
      cellCss = "${cellCss} active";
    }

    // TODO:  merge them together in the setter
    for (var key in cellCssClasses) {
      if (cellCssClasses[key][row] && cellCssClasses[key][row][m.id]) {
        cellCss += (" " + cellCssClasses[key][row][m.id]);
      }
    }

    stringArray.add("<div class='${cellCss}'>");

    // if there is a corresponding row (if not, this is the Add New row or this data hasn't been loaded yet)
    if (item != null) {
      var value = getDataItemValueForColumn(item, m);
      stringArray.add(getFormatter(row, m)(row, cell, value, m, item));
    }

    stringArray.add("</div>");

    rowsCache[row].cellRenderQueue.add(cell);
    rowsCache[row].cellColSpans[cell] = colspan;
  }


  void cleanupRows(Map<String,int> rangeToKeep) {
    for (var i in rowsCache) {
      if (((i = int.parse(i, radix:10)) != activeRow) && (i < rangeToKeep['top'] || i > rangeToKeep['bottom'])) {
        removeRowFromCache(i);
      }
    }
  }

  void invalidate() {
    updateRowCount();
    invalidateAllRows();
    render();
  }

  void invalidateAllRows() {
    if (currentEditor != null) {
      makeActiveCellNormal();
    }
    for (var row in rowsCache) {
      removeRowFromCache(row);
    }
  }

  void removeRowFromCache(row) {
    var cacheEntry = rowsCache[row];
    if (!cacheEntry) {
      return;
    }

    if (rowNodeFromLastMouseWheelEvent == cacheEntry.rowNode) {
      cacheEntry.rowNode.style.display = 'none';
      zombieRowNodeFromLastMouseWheelEvent = rowNodeFromLastMouseWheelEvent;
    } else {
      $canvas.children[0].remove(cacheEntry.rowNode);
    }

    rowsCache.remove(row);
    postProcessedRows.remove(row);
    renderedRows--;
    counter_rows_removed++;
  }

  void invalidateRows(rows) {
    var i, rl;
    if (!rows || !rows.length) {
      return;
    }
    vScrollDir = 0;
    for (i = 0; i < rows.length; i++) {
      if (currentEditor && activeRow == rows[i]) {
        makeActiveCellNormal();
      }
      if (rowsCache[rows[i]] != null) {
        removeRowFromCache(rows[i]);
      }
    }
  }

  void invalidateRow(int row) {
    invalidateRows(row);
  }

  void updateCell(int row, int cell) {
    var cellNode = getCellNode(row, cell);
    if (!cellNode) {
      return;
    }

    var m = columns[cell], d = getDataItem(row);
    if (currentEditor && activeRow == row && activeCell == cell) {
      currentEditor.loadValue(d);
    } else {
      cellNode.innerHtml = d ? getFormatter(row, m)(row, cell, getDataItemValueForColumn(d, m), m, d) : "";
      invalidatePostProcessingResults(row);
    }
  }

  void updateRow(int row) {
    var cacheEntry = rowsCache[row];
    if (!cacheEntry) {
      return;
    }

    ensureCellNodesInRowsCache(row);

    var d = getDataItem(row);

    for (var columnIdx in cacheEntry.cellNodesByColumnIdx) {
      if (!cacheEntry.cellNodesByColumnIdx.hasOwnProperty(columnIdx)) {
        continue;
      }

      columnIdx = columnIdx | 0;
      var m = columns[columnIdx],
          node = cacheEntry.cellNodesByColumnIdx[columnIdx];

      if (row == activeRow && columnIdx == activeCell && currentEditor) {
        currentEditor.loadValue(d);
      } else if (d) {
        node.innerHTML = getFormatter(row, m)(row, columnIdx, getDataItemValueForColumn(d, m), m, d);
      } else {
        node.innerHTML = "";
      }
    }

    invalidatePostProcessingResults(row);
  }

  double getViewportHeight() {
    return double.parse($container.children[0].style.height) -
        double.parse($container.children[0].style.paddingTop) -
        double.parse($container.children[0].style.paddingBottom) -
        double.parse($headerScroller.children[0].style.height) - getVBoxDelta($headerScroller) -
        (gridOptions.showTopPanel ? gridOptions.topPanelHeight + getVBoxDelta($topPanelScroller) : 0) -
        (gridOptions.showHeaderRow ? gridOptions.headerRowHeight + getVBoxDelta($headerRowScroller) : 0);
  }

  void resizeCanvas([int e]) {
    if (!initialized) { return; }
    if (gridOptions.autoHeight) {
      viewportH = gridOptions.rowHeight * getDataLengthIncludingAddNew().toDouble();
    } else {
      viewportH = getViewportHeight();
    }

    numVisibleRows = (viewportH / gridOptions.rowHeight).ceil();
    viewportW = double.parse($container.children[0].style.width);
    if (!gridOptions.autoHeight) {
      $viewport.style.height = "${viewportH}";
    }

    if (gridOptions.forceFitColumns) {
      autosizeColumns();
    }

    updateRowCount();
    handleScroll();
    // Since the width has changed, force the render() to reevaluate virtually rendered cells.
    lastRenderedScrollLeft = -1;
    render();
  }

  void updateRowCount() {
    if (!initialized) { return; }

    var dataLengthIncludingAddNew = getDataLengthIncludingAddNew();
    var numberOfRows = dataLengthIncludingAddNew +
        (gridOptions.leaveSpaceForNewRows ? numVisibleRows - 1 : 0);

    var oldViewportHasVScroll = viewportHasVScroll;
    // with autoHeight, we do not need to accommodate the vertical scroll bar
    viewportHasVScroll = !gridOptions.autoHeight && (numberOfRows * gridOptions.rowHeight > viewportH);

    makeActiveCellNormal();

    // remove the rows that are now outside of the data range
    // this helps avoid redundant calls to .removeRow() when the size of the data decreased by thousands of rows
    var l = dataLengthIncludingAddNew - 1;
    for (var i in rowsCache) {
      if (i >= l) {
        removeRowFromCache(i);
      }
    }

    if (activeCellNode && activeRow > l) {
      resetActiveCell();
    }

    var oldH = h;
    th = math.max(gridOptions.rowHeight * numberOfRows, viewportH - scrollbarDimensions.y);
    if (th < maxSupportedCssHeight) {
      // just one page
      h = ph = th;
      n = 1;
      cj = 0.0;
    } else {
      // break into pages
      h = maxSupportedCssHeight;
      ph = h / 100;
      n = (th / ph).floor();
      cj = (th - h) / (n - 1);
    }

    if (h != oldH) {
      $canvas.style.height = "${h}";
      scrollTop = $viewport.children[0].scrollTop;
    }

    var oldScrollTopInRange = (scrollTop + pageOffset <= th - viewportH);

    if (th == 0 || scrollTop == 0) {
      page = pageOffset = 0;
    } else if (oldScrollTopInRange) {
      // maintain virtual position
      scrollTo(scrollTop + pageOffset);
    } else {
      // scroll to bottom
      scrollTo((th - viewportH).round());
    }

    if (h != oldH && gridOptions.autoHeight) {
      resizeCanvas();
    }

    if (gridOptions.forceFitColumns && oldViewportHasVScroll != viewportHasVScroll) {
      autosizeColumns();
    }
    updateCanvasWidth(false);
  }

  Map<String, int> getVisibleRange([viewportTop, viewportLeft]) {
    if (viewportTop == null) {
      viewportTop = scrollTop;
    }
    if (viewportLeft == null) {
      viewportLeft = scrollLeft;
    }

    return {
      'top': getRowFromPosition(viewportTop),
      'bottom': getRowFromPosition(viewportTop + viewportH) + 1,
      'leftPx': viewportLeft,
      'rightPx': viewportLeft + viewportW
    };
  }

  Map<String, int> getRenderedRange([int viewportTop, int viewportLeft]) {
    Map<String,int> range = getVisibleRange(viewportTop, viewportLeft);
    int buffer = (viewportH / gridOptions.rowHeight).round();
    int minBuffer = 3;

    if (vScrollDir == -1) {
      range['top'] -= buffer;
      range['bottom'] += minBuffer;
    } else if (vScrollDir == 1) {
      range['top'] -= minBuffer;
      range['bottom'] += buffer;
    } else {
      range['top'] -= minBuffer;
      range['bottom'] += minBuffer;
    }

    range['top'] = math.max(0, range['top']);
    range['bottom'] = math.min(getDataLengthIncludingAddNew() - 1, range['bottom']);

    range['leftPx'] -= viewportW;
    range['rightPx'] += viewportW;

    range['leftPx'] = math.max(0, range['leftPx']);
    range['rightPx'] = math.min(canvasWidth, range['rightPx']);

    return range;
  }

  void ensureCellNodesInRowsCache(int row) {
    var cacheEntry = rowsCache[row];
    if (cacheEntry) {
      if (cacheEntry.cellRenderQueue.length) {
        var lastChild = cacheEntry.rowNode.lastChild;
        while (cacheEntry.cellRenderQueue.length) {
          var columnIdx = cacheEntry.cellRenderQueue.pop();
          cacheEntry.cellNodesByColumnIdx[columnIdx] = lastChild;
          lastChild = lastChild.previousSibling;
        }
      }
    }
  }

  void cleanUpCells(Map<String,int> range, int row) {
    var totalCellsRemoved = 0;
    var cacheEntry = rowsCache[row];

    // Remove cells outside the range.
    var cellsToRemove = [];
    for (var i in cacheEntry.cellNodesByColumnIdx) {
      // I really hate it when people mess with Array.prototype.
      if (!cacheEntry.cellNodesByColumnIdx.hasOwnProperty(i)) {
        continue;
      }

      // This is a string, so it needs to be cast back to a number.
      i = i | 0;

      var colspan = cacheEntry.cellColSpans[i];
      if (columnPosLeft[i] > range['rightPx'] ||
        columnPosRight[math.min(columns.length - 1, i + colspan - 1)] < range['leftPx']) {
        if (!(row == activeRow && i == activeCell)) {
          cellsToRemove.add(i);
        }
      }
    }

    var cellToRemove;
    while ((cellToRemove = cellsToRemove.pop()) != null) {
      cacheEntry.rowNode.removeChild(cacheEntry.cellNodesByColumnIdx[cellToRemove]);
      cacheEntry.cellColSpans.remove(cellToRemove);
      cacheEntry.cellNodesByColumnIdx.remove(cellToRemove);
      if (postProcessedRows[row] != null) {
        postProcessedRows[row].remove(cellToRemove);
      }
      totalCellsRemoved++;
    }
  }

  void cleanUpAndRenderCells(Map<String,int> range) {
    var cacheEntry;
    var stringArray = [];
    var processedRows = [];
    var cellsAdded;
    var totalCellsAdded = 0;
    var colspan;

    for (var row = range['top']; row <= range['bottom']; row++) {
      cacheEntry = rowsCache[row];
      if (cacheEntry == null) {
        continue;
      }

      // cellRenderQueue populated in renderRows() needs to be cleared first
      ensureCellNodesInRowsCache(row);

      cleanUpCells(range, row);

      // Render missing cells.
      cellsAdded = 0;

      var metadata = data.getItemMetadata && data.getItemMetadata(row);
      metadata = metadata && metadata.columns;

      var d = getDataItem(row);

      // TODO:  shorten this loop (index? heuristics? binary search?)
      for (var i = 0, ii = columns.length; i < ii; i++) {
        // Cells to the right are outside the range.
        if (columnPosLeft[i] > range['rightPx']) {
          break;
        }

        // Already rendered.
        if ((colspan = cacheEntry.cellColSpans[i]) != null) {
          i += (colspan > 1 ? colspan - 1 : 0);
          continue;
        }

        colspan = 1;
        if (metadata) {
          var columnData = metadata[columns[i].id] || metadata[i];
          colspan = (columnData && columnData.colspan) || 1;
          if (colspan == "*") {
            colspan = ii - i;
          }
        }

        if (columnPosRight[math.min(ii - 1, i + colspan - 1)] > range['leftPx']) {
          appendCellHtml(stringArray, row, i, colspan, d);
          cellsAdded++;
        }

        i += (colspan > 1 ? colspan - 1 : 0);
      }

      if (cellsAdded) {
        totalCellsAdded += cellsAdded;
        processedRows.add(row);
      }
    }

    if (!stringArray.length) {
      return;
    }

    var x = new dom.DivElement();
    x.innerHtml = stringArray.join("");

    var processedRow;
    var node;
    while ((processedRow = processedRows.pop()) != null) {
      cacheEntry = rowsCache[processedRow];
      var columnIdx;
      while ((columnIdx = cacheEntry.cellRenderQueue.pop()) != null) {
        node = x.lastChild;
        cacheEntry.rowNode.appendChild(node);
        cacheEntry.cellNodesByColumnIdx[columnIdx] = node;
      }
    }
  }

  void renderRows(Map<String,int> range) {
    var parentNode = $canvas.children[0],
        stringArray = [],
        rows = [],
        needToReselectCell = false,
        dataLength = getDataLength;

    for (var i = range['top']; i <= range['bottom']; i++) {
      if (rowsCache[i] != null) {
        continue;
      }
      renderedRows++;
      rows.add(i);

      // Create an entry right away so that appendRowHtml() can
      // start populatating it.
      rowsCache[i] = {
        "rowNode": null,

        // ColSpans of rendered cells (by column idx).
        // Can also be used for checking whether a cell has been rendered.
        "cellColSpans": [],

        // Cell nodes (by column idx).  Lazy-populated by ensureCellNodesInRowsCache().
        "cellNodesByColumnIdx": [],

        // Column indices of cell nodes that have been rendered, but not yet indexed in
        // cellNodesByColumnIdx.  These are in the same order as cell nodes added at the
        // end of the row.
        "cellRenderQueue": []
      };

      appendRowHtml(stringArray, i, range, dataLength);
      if (activeCellNode && activeRow == i) {
        needToReselectCell = true;
      }
      counter_rows_rendered++;
    }

    if (!rows.length) { return; }

    var x = new dom.DivElement();
    x.innerHtml = stringArray.join("");

    for (var i = 0; i < rows.length; i++) {
      rowsCache[rows[i]].rowNode = parentNode.append(x.firstChild);
    }

    if (needToReselectCell) {
      activeCellNode = getCellNode(activeRow, activeCell);
    }
  }

  void startPostProcessing() {
    if (!gridOptions.enableAsyncPostRender) {
      return;
    }
    if(h_postrender != null) {
      h_postrender.cancel() ;
      h_postrender = null;
    }
    h_postrender = new async.Timer(gridOptions.asyncPostRenderDelay, asyncPostProcessRows);
  }

  void invalidatePostProcessingResults(int row) {
    postProcessedRows.remove(row);
    postProcessFromRow = math.min(postProcessFromRow, row);
    postProcessToRow = math.max(postProcessToRow, row);
    startPostProcessing();
  }

  void updateRowPositions() {
    for (final int row in rowsCache) {
      rowsCache[row].rowNode.style.top = "${getRowTop(row)}px";
    }
  }

  void render() {
    if (!initialized) { return; }
    var visible = getVisibleRange();
    var rendered = getRenderedRange();

    // remove rows no longer in the viewport
    cleanupRows(rendered);

    // add new rows & missing cells in existing rows
    if (lastRenderedScrollLeft != scrollLeft) {
      cleanUpAndRenderCells(rendered);
    }

    // render missing rows
    renderRows(rendered);

    postProcessFromRow = visible['top'];
    postProcessToRow = math.min(getDataLengthIncludingAddNew() - 1, visible['bottom']);
    startPostProcessing();

    lastRenderedScrollTop = scrollTop;
    lastRenderedScrollLeft = scrollLeft;
    h_render = null;
  }

  void handleHeaderRowScroll([dom.Event e]) {
    var scrollLeft = $headerRowScroller.children[0].scrollLeft;
    if (scrollLeft != $viewport.children[0].scrollLeft) {
      $viewport.children[0].scrollLeft = scrollLeft;
    }
  }

  void handleScroll([dom.Event e]) {
    scrollTop = $viewport.children[0].scrollTop;
    scrollLeft = $viewport.children[0].scrollLeft;
    int vScrollDist = (scrollTop - prevScrollTop).abs();
    int hScrollDist = (scrollLeft - prevScrollLeft).abs();

    if (hScrollDist != 0) {
      prevScrollLeft = scrollLeft;
      $headerScroller.children[0].scrollLeft = scrollLeft;
      $topPanelScroller.children[0].scrollLeft = scrollLeft;
      $headerRowScroller.children[0].scrollLeft = scrollLeft;
    }

    if (vScrollDist != 0) {
      vScrollDir = prevScrollTop < scrollTop ? 1 : -1;
      prevScrollTop = scrollTop;

      // switch virtual pages if needed
      if (vScrollDist < viewportH) {
        scrollTo(scrollTop + pageOffset);
      } else {
        var oldOffset = pageOffset;
        if (h == viewportH) {
          page = 0;
        } else {
          page = math.min(n - 1, (scrollTop * ((th - viewportH) / (h - viewportH)) * (1 / ph)).floor());
        }
        pageOffset = (page * cj).round();
        if (oldOffset != pageOffset) {
          invalidateAllRows();
        }
      }
    }

    if (hScrollDist || vScrollDist) {
      if (h_render != null) {
        h_render.cancel();
      }

      if ((lastRenderedScrollTop - scrollTop).abs() > 20 ||
          (lastRenderedScrollLeft - scrollLeft).abs() > 20) {
        if (gridOptions.forceSyncScrolling || (
            (lastRenderedScrollTop - scrollTop).abs() < viewportH &&
            (lastRenderedScrollLeft - scrollLeft).abs() < viewportW)) {
          render();
        } else {
          h_render = new async.Timer(new Duration(milliseconds: 50), render);
        }

        fire(BwuDatagrid.ON_VIEWPORT_CHANGED, detail: {});
        //trigger(self.onViewportChanged, {});
      }
    }

    fire('scroll', detail: {'scrollLeft': scrollLeft, 'scrollTop': scrollTop});
    //trigger(self.onScroll, {scrollLeft: scrollLeft, scrollTop: scrollTop});
  }

  void asyncPostProcessRows() {
    var dataLength = getDataLength;
    while (postProcessFromRow <= postProcessToRow) {
      var row = (vScrollDir >= 0) ? postProcessFromRow++ : postProcessToRow--;
      var cacheEntry = rowsCache[row];
      if (!cacheEntry || row >= dataLength) {
        continue;
      }

      if (postProcessedRows[row] == null) {
        postProcessedRows[row] = {};
      }

      ensureCellNodesInRowsCache(row);
      for (var columnIdx in cacheEntry.cellNodesByColumnIdx) {
        if (!cacheEntry.cellNodesByColumnIdx.hasOwnProperty(columnIdx)) {
          continue;
        }

        columnIdx = columnIdx | 0;

        var m = columns[columnIdx];
        if (m.asyncPostRender && !postProcessedRows[row][columnIdx]) {
          var node = cacheEntry.cellNodesByColumnIdx[columnIdx];
          if (node) {
            m.asyncPostRender(node, row, getDataItem(row), m);
          }
          postProcessedRows[row][columnIdx] = true;
        }
      }

      h_postrender = new async.Timer(gridOptions.asyncPostRenderDelay, asyncPostProcessRows);
      return;
    }
  }

  void updateCellCssStylesOnRenderedRows(int addedHash, int removedHash) {
    dom.HtmlElement node;
    int columnId;
    bool addedRowHash;
    bool removedRowHash;
    for (var row in rowsCache) {
      removedRowHash = removedHash != null && removedHash[row] != null;
      addedRowHash = addedHash != null && addedHash[row] != null;

      if (removedRowHash) {
        for (columnId in removedRowHash) {
          if (!addedRowHash || removedRowHash[columnId] != addedRowHash[columnId]) {
            node = getCellNode(row, getColumnIndex(columnId));
            if (node != null) {
              node.classes.remove(removedRowHash[columnId]);
            }
          }
        }
      }

      if (addedRowHash) {
        for (columnId in addedRowHash) {
          if (!removedRowHash || removedRowHash[columnId] != addedRowHash[columnId]) {
            node = getCellNode(row, getColumnIndex(columnId));
            if (node != null) {
              node.classes.add(addedRowHash[columnId]);
            }
          }
        }
      }
    }
  }

  void addCellCssStyles(key, hash) {
    if (cellCssClasses[key] != null) {
      throw "addCellCssStyles: cell CSS hash with key '" + key + "' already exists.";
    }

    cellCssClasses[key] = hash;
    updateCellCssStylesOnRenderedRows(hash, null);

    fire('cell-css-style-changed', detail: { "key": key, "hash": hash });
    //trigger(self.onCellCssStylesChanged, { "key": key, "hash": hash });
  }

  void removeCellCssStyles(int key) {
    if (cellCssClasses[key] == null) {
      return;
    }

    updateCellCssStylesOnRenderedRows(null, cellCssClasses[key]);
    cellCssClasses.remove(key);

    trigger(self.onCellCssStylesChanged, { "key": key, "hash": null });
  }

  void setCellCssStyles(String key, List<Map<String,String>> hash) {
    var prevHash = cellCssClasses[key];

    cellCssClasses[key] = hash;
    updateCellCssStylesOnRenderedRows(hash, prevHash);

    trigger(self.onCellCssStylesChanged, { "key": key, "hash": hash });
  }

  String getCellCssStyles(int key) {
    return cellCssClasses[key];
  }

  void flashCell(int row, int cell, int speed) {
    speed = speed != null ? speed : 100;
    if (rowsCache[row] != null) {
      var $cell = getCellNode(row, cell);

      Function toggleCellClass;
      toggleCellClass = (times) {
        if (!times) {
          return;
        }
        new async.Future.delayed(new Duration(milliseconds: speed),() {
              $cell.queue(() {
                $cell.classes.toggle(gridOptions.cellFlashingCssClass).dequeue();
                toggleCellClass(times - 1);
              });
            });
      };

      toggleCellClass(4);
    }
  }

  //////////////////////////////////////////////////////////////////////////////////////////////
  // Interactivity

  void handleMouseWheel(dom.MouseEvent e) {
    var rowNode = e.target.closest(".slick-row")[0];
    if (rowNode != rowNodeFromLastMouseWheelEvent) {
      if (zombieRowNodeFromLastMouseWheelEvent && zombieRowNodeFromLastMouseWheelEvent != rowNode) {
        //$canvas.children[0].remove(zombieRowNodeFromLastMouseWheelEvent);
        if(zombieRowNodeFromLastMouseWheelEvent != null) { // TODO check
          zombieRowNodeFromLastMouseWheelEvent.remove();
        }
        zombieRowNodeFromLastMouseWheelEvent = null;
      }
      rowNodeFromLastMouseWheelEvent = rowNode;
    }
  }

  bool handleDragInit(dom.MouseEvent e, int dd) {
    var cell = getCellFromEvent(e);
    if (!cell || !cellExists(cell.row, cell.cell)) {
      return false;
    }

    var retval = trigger(self.onDragInit, dd, e);
    if (e.isImmediatePropagationStopped()) {
      return retval;
    }

    // if nobody claims to be handling drag'n'drop by stopping immediate propagation,
    // cancel out of it
    return false;
  }

  bool handleDragStart(dom.MouseEvent e, Map<String,int> dd) {
    var cell = getCellFromEvent(e);
    if (!cell || !cellExists(cell.row, cell.cell)) {
      return false;
    }

    var retval = trigger(self.onDragStart, dd, e);
    if (e.isImmediatePropagationStopped()) {
      return retval;
    }

    return false;
  }

  dom.HtmlElement handleDrag(dom.MouseEvent e, [int dd]) {
    return trigger(self.onDrag, dd, e);
  }

  dom.HtmlElement handleDragEnd(dom.MouseEvent e, [int dd]) {
    trigger(self.onDragEnd, dd, e);
  }

  void handleKeyDown(dom.KeyboardEvent e) {
    trigger(self.onKeyDown, {'row': activeRow, 'cell': activeCell}, e);
    var handled = e.isImmediatePropagationStopped();

    if (!handled) {
      if (!e.shiftKey && !e.altKey && !e.ctrlKey) {
        if (e.which == 27) {
          if (!getEditorLock.isActive) {
            return; // no editing mode to cancel, allow bubbling and default processing (exit without cancelling the event)
          }
          cancelEditAndSetFocus();
        } else if (e.which == 34) {
          navigatePageDown();
          handled = true;
        } else if (e.which == 33) {
          navigatePageUp();
          handled = true;
        } else if (e.which == 37) {
          handled = navigateLeft();
        } else if (e.which == 39) {
          handled = navigateRight();
        } else if (e.which == 38) {
          handled = navigateUp();
        } else if (e.which == 40) {
          handled = navigateDown();
        } else if (e.which == 9) {
          handled = navigateNext();
        } else if (e.which == 13) {
          if (gridOptions.editable) {
            if (currentEditor != null) {
              // adding new row
              if (activeRow == getDataLength) {
                navigateDown();
              } else {
                commitEditAndSetFocus();
              }
            } else {
              if (getEditorLock.commitCurrentEdit()) {
                makeActiveCellEditable();
              }
            }
          }
          handled = true;
        }
      } else if (e.which == 9 && e.shiftKey && !e.ctrlKey && !e.altKey) {
        handled = navigatePrev();
      }
    }

    if (handled) {
      // the event has been handled so don't let parent element (bubbling/propagation) or browser (default) handle it
      e.stopPropagation();
      e.preventDefault();
      try {
        e.originalEvent.keyCode = 0; // prevent default behaviour for special keys in IE browsers (F3, F5, etc.)
      }
      // ignore exceptions - setting the original event's keycode throws access denied exception for "Ctrl"
      // (hitting control key only, nothing else), "Shift" (maybe others)
      catch (error) {
      }
    }
  }

  void handleClick(dom.MouseEvent e) {
    if (currentEditor == 0) {
      // if this click resulted in some cell child node getting focus,
      // don't steal it back - keyboard events will still bubble up
      // IE9+ seems to default DIVs to tabIndex=0 instead of -1, so check for cell clicks directly.
      if (e.target != dom.document.activeElement || (e.target as dom.HtmlElement).classes.contains("slick-cell")) {
        setFocus();
      }
    }

    var cell = getCellFromEvent(e);
    if (cell == null || (currentEditor != null && activeRow == cell['row'] && activeCell == cell['cell'])) {
      return;
    }

    trigger(self.onClick, {'row': cell['row'], 'cell': cell['cell']}, e);
    if (e.isImmediatePropagationStopped()) {
      return;
    }

    if ((activeCell != cell['cell'] || activeRow != cell['row']) && canCellBeActive(cell['row'], cell['cell'])) {
      if (!getEditorLock.isActive || getEditorLock.commitCurrentEdit()) {
        scrollRowIntoView(cell['row'], false);
        setActiveCellInternal(getCellNode(cell['row'], cell['cell']));
      }
    }
  }

  void handleContextMenu(dom.MouseEvent e) {
    var $cell = (e.target as dom.HtmlElement).closest(".slick-cell", $canvas);
    if ($cell.length == 0) {
      return;
    }

    // are we editing this cell?
    if (activeCellNode == $cell.children[0] && currentEditor != null) {
      return;
    }

    trigger(self.onContextMenu, {}, e);
  }

  void handleDblClick(dom.MouseEvent e) {
    var cell = getCellFromEvent(e);
    if (!cell || (currentEditor != null && activeRow == cell['row'] && activeCell == cell['cell'])) {
      return;
    }

    trigger(self.onDblClick, {'row': cell['row'], 'cell': cell['cell']}, e);
    if (e.isImmediatePropagationStopped()) {
      return;
    }

    if (gridOptions.editable) {
      gotoCell(cell.row, cell.cell, true);
    }
  }

  void handleHeaderMouseEnter(dom.MouseEvent e) {
    trigger(self.onHeaderMouseEnter, {
      "column": dataset["column"]
    }, e);
  }

  void handleHeaderMouseLeave(dom.MouseEvent e) {
    trigger(self.onHeaderMouseLeave, {
      "column": dataset["column"]
    }, e);
  }

  void handleHeaderContextMenu(dom.MouseEvent e) {
    var $header = e.target.closest(".slick-header-column", ".slick-header-columns");
    var column = $header && $header.dataset["column"];
    trigger(self.onHeaderContextMenu, {column: column}, e);
  }

  void handleHeaderClick(dom.MouseEvent e) {
    var $header = e.target.closest(".slick-header-column", ".slick-header-columns");
    var column = $header && $header.dataset["column"];
    if (column) {
      trigger(self.onHeaderClick, {column: column}, e);
    }
  }

  void handleMouseEnter(dom.MouseEvent e) {
    trigger(self.onMouseEnter, {}, e);
  }

  void handleMouseLeave(dom.MouseEvent e) {
    trigger(self.onMouseLeave, {}, e);
  }

  bool cellExists(int row, int cell) {
    return !(row < 0 || row >= getDataLength || cell < 0 || cell >= columns.length);
  }

  Map<String,int> getCellFromPoint(int x, int y) {
    var row = getRowFromPosition(y);
    var cell = 0;

    var w = 0;
    for (var i = 0; i < columns.length && w < x; i++) {
      w += columns[i].width;
      cell++;
    }

    if (cell < 0) {
      cell = 0;
    }

    return {'row': row, 'cell': cell - 1};
  }

  int getCellFromNode(dom.HtmlElement cellNode) {
    // read column number from .l<columnNumber> CSS class
    var cls = new RegExp(r'l\d+').allMatches(cellNode.className);
    if (cls == null) {
      throw "getCellFromNode: cannot get cell - ${cellNode.className}";
    }
    return int.parse(cls[0].substr(1, cls[0].length - 1), radix: 10);
  }

  int getRowFromNode(dom.HtmlElement rowNode) {
    for (var row in rowsCache) {
      if (rowsCache[row].rowNode == rowNode) {
        return row | 0;
      }
    }

    return null;
  }

  Map<String, int> getCellFromEvent(dom.Event e) {
    var $cell = e.target.closest(".slick-cell", $canvas);
    if (!$cell.length) {
      return null;
    }

    var row = getRowFromNode($cell[0].parentNode);
    var cell = getCellFromNode($cell[0]);

    if (row == null || cell == null) {
      return null;
    } else {
      return {
        "row": row,
        "cell": cell
      };
    }
  }

  Map<String,int> getCellNodeBox(int row, int cell) {
    if (!cellExists(row, cell)) {
      return null;
    }

    var y1 = getRowTop(row);
    var y2 = y1 + gridOptions.rowHeight - 1;
    var x1 = 0;
    for (var i = 0; i < cell; i++) {
      x1 += columns[i].width;
    }
    var x2 = x1 + columns[cell].width;

    // TODO shouldn't this be a rectangle?
    return {
      'top': y1,
      'left': x1,
      'bottom': y2,
      'right': x2
    };
  }

  //////////////////////////////////////////////////////////////////////////////////////////////
  // Cell switching

  void resetActiveCell() {
    setActiveCellInternal(null, false);
  }

  void setFocus() {
    if (tabbingDirection == -1) {
      $focusSink.children[0].focus();
    } else {
      $focusSink2.children[0].focus();
    }
  }

  void scrollCellIntoView(int row, int cell, bool doPaging) {
    scrollRowIntoView(row, doPaging);

    var colspan = getColspan(row, cell);
    var left = columnPosLeft[cell],
      right = columnPosRight[cell + (colspan > 1 ? colspan - 1 : 0)],
      scrollRight = scrollLeft + viewportW;

    if (left < scrollLeft) {
      $viewport.scrollLeft = left;
      handleScroll();
      render();
    } else if (right > scrollRight) {
      $viewport.scrollLeft = math.min(left, right - $viewport.children[0].clientWidth);
      handleScroll();
      render();
    }
  }

  void setActiveCellInternal(dom.HtmlElement newCell, [bool opt_editMode]) {
    if (activeCellNode != null) {
      makeActiveCellNormal();
      activeCellNode.classes.remove("active");
      if (rowsCache[activeRow] != null) {
        rowsCache[activeRow].rowNode.classes.remove("active");
      }
    }

    var activeCellChanged = (activeCellNode != newCell);
    activeCellNode = newCell;

    if (activeCellNode != null) {
      activeRow = getRowFromNode(activeCellNode.parentNode);
      activeCell = activePosX = getCellFromNode(activeCellNode);

      if (opt_editMode == null) {
        opt_editMode = (activeRow == getDataLength) || gridOptions.autoEdit;
      }

      activeCellNode.classes.add("active");
      rowsCache[activeRow].rowNode.classes.add("active");

      if (gridOptions.editable && opt_editMode && isCellPotentiallyEditable(activeRow, activeCell)) {
        if(h_editorLoader != null) {
          h_editorLoader.cancel();
        }
        if (gridOptions.asyncEditorLoading) {
          h_editorLoader = new async.Timer(gridOptions.asyncEditorLoadDelay, () {
            makeActiveCellEditable();
          });
        } else {
          makeActiveCellEditable();
        }
      }
    } else {
      activeRow = activeCell = null;
    }

    if (activeCellChanged) {
      trigger(self.onActiveCellChanged, getActiveCell());
    }
  }

  void clearTextSelection() {
    if (dom.document.selection && dom.document.selection.empty) {
      try {
        //IE fails here if selected element is not in dom
        dom.document.selection.empty();
      } catch (e) { }
    } else if (dom.window.getSelection) {
      var sel = dom.window.getSelection();
      if (sel && sel.removeAllRanges) {
        sel.removeAllRanges();
      }
    }
  }

  bool isCellPotentiallyEditable(int row, int cell) {
    var dataLength = getDataLength;
    // is the data for this row loaded?
    if (row < dataLength && getDataItem(row) == null) {
      return false;
    }

    // are we in the Add New row?  can we create new from this cell?
    if (columns[cell].cannotTriggerInsert && row >= dataLength) {
      return false;
    }

    // does this cell have an editor?
    if (getEditor(row, cell) == null) {
      return false;
    }

    return true;
  }

  void makeActiveCellNormal() {
    if (currentEditor == null) {
      return;
    }
    trigger(self.onBeforeCellEditorDestroy, {'editor': currentEditor});
    currentEditor.destroy();
    currentEditor = null;

    if (activeCellNode != null) {
      var d = getDataItem(activeRow);
      activeCellNode.classes..remove("editable")..remove("invalid");
      if (d) {
        var column = columns[activeCell];
        var formatter = getFormatter(activeRow, column);
        activeCellNode.innerHtml = formatter(activeRow, activeCell, getDataItemValueForColumn(d, column), column, d);
        invalidatePostProcessingResults(activeRow);
      }
    }

    // if there previously was text selected on a page (such as selected text in the edit cell just removed),
    // IE can't set focus to anything else correctly
    if (dom.window.navigator.userAgent.toLowerCase().contains('msie')) {
      clearTextSelection();
    }

    getEditorLock.deactivate(editController);
  }

  void makeActiveCellEditable([Editor editor]) {
    if (activeCellNode == null) {
      return;
    }
    if (!gridOptions.editable) {
      throw "Grid : makeActiveCellEditable : should never get called when options.editable is false";
    }

    // cancel pending async call if there is one
    if(h_editorLoader != null) {
      h_editorLoader.cancel();
    }

    if (!isCellPotentiallyEditable(activeRow, activeCell)) {
      return;
    }

    var columnDef = columns[activeCell];
    var item = getDataItem(activeRow);

    if (trigger(self.onBeforeEditCell, {'row': activeRow, 'cell': activeCell, 'item': item, 'column': columnDef}) == false) { // TODO == false
      setFocus();
      return;
    }

    getEditorLock.activate(editController);
    activeCellNode.classes.add("editable");

    // don't clear the cell if a custom editor is passed through
    if (editor == null) {
      activeCellNode.innerHtml = "";
    }

    currentEditor = new (editor || getEditor(activeRow, activeCell))({
      'grid': this,
      'gridPosition': absBox($container.children[0]),
      'position': absBox(activeCellNode),
      'container': activeCellNode,
      'column': columnDef,
      'item': item || {},
      'commitChanges': commitEditAndSetFocus,
      'cancelChanges': cancelEditAndSetFocus
    });

    if (item != null) {
      currentEditor.loadValue(item);
    }

    serializedEditorValue = currentEditor.serializeValue();

    if (currentEditor.position != null) {
      handleActiveCellPositionChange();
    }
  }

  void commitEditAndSetFocus() {
    // if the commit fails, it would do so due to a validation error
    // if so, do not steal the focus from the editor
    if (getEditorLock.commitCurrentEdit()) {
      setFocus();
      if (gridOptions.autoEdit) {
        navigateDown();
      }
    }
  }

  void cancelEditAndSetFocus() {
    if (getEditorLock.cancelCurrentEdit()) {
      setFocus();
    }
  }

  Map absBox(dom.HtmlElement elem) {
    var cs = elem.getComputedStyle();
    var box = {
      'top': elem.offsetTop,
      'left': elem.offsetLeft,
      'bottom': 0,
      'right': 0,
      'width': cs.width + cs.paddingLeft + cs.paddingRight + cs.borderLeft + cs.borderRight, //elem.outerWidth(),
      'height': cs.height + cs.paddingTop + cs.paddingBottom + cs.borderTop + cs.borderBottom, //elem.outerHeight(), // TODO check all other outerWidth/outherHeight if they include border
      'visible': true};
    box['bottom'] = box['top'] + box['height'];
    box['right'] = box['left'] + box['width'];

    // walk up the tree
    var offsetParent = elem.offsetParent;
    while ((elem = elem.parentNode) != dom.document.body) {
      if (box['visible'] && elem.scrollHeight != elem.offsetHeight && elem.style.overflowY != "visible") {
        box['visible'] = box['bottom'] > elem.scrollTop && box['top'] < elem.scrollTop + elem.clientHeight;
      }

      if (box['visible'] && elem.scrollWidth != elem.offsetWidth && elem.style.overflowX != "visible") {
        box['visible'] = box['right'] > elem.scrollLeft && box['left'] < elem.scrollLeft + elem.clientWidth;
      }

      box['left'] -= elem.scrollLeft;
      box['top'] -= elem.scrollTop;

      if (elem == offsetParent) {
        box['left'] += elem.offsetLeft;
        box['top'] += elem.offsetTop;
        offsetParent = elem.offsetParent;
      }

      box['bottom'] = box['top'] + box['height'];
      box['right'] = box['left'] + box['width'];
    }

    return box;
  }

  Map getActiveCellPosition() {
    return absBox(activeCellNode);
  }

  Map getGridPosition() {
    return absBox($container.children[0]);
  }

  void handleActiveCellPositionChange() {
    if (activeCellNode == null) {
      return;
    }

    trigger(self.onActiveCellPositionChanged, {});

    if (currentEditor != null) {
      var cellBox = getActiveCellPosition();
      if (currentEditor.show && currentEditor.hide) {
        if (!cellBox['visible']) {
          currentEditor.hide();
        } else {
          currentEditor.show();
        }
      }

      currentEditor.position(cellBox);
    }
  }

  Editor getCellEditor() {
    return currentEditor;
  }

  Map<String,dom.HtmlElement> getActiveCell() {
    if (activeCellNode == null) {
      return null;
    } else {
      return {'row': activeRow, 'cell': activeCell};
    }
  }

  dom.HtmlElement getActiveCellNode() {
    return activeCellNode;
  }

  void scrollRowIntoView(int row, bool doPaging) {
    var rowAtTop = row * gridOptions.rowHeight;
    var rowAtBottom = (row + 1) * gridOptions.rowHeight - viewportH + (viewportHasHScroll ? scrollbarDimensions.y : 0);

    // need to page down?
    if ((row + 1) * gridOptions.rowHeight > scrollTop + viewportH + pageOffset) {
      scrollTo(doPaging ? rowAtTop : rowAtBottom);
      render();
    }
    // or page up?
    else if (row * gridOptions.rowHeight < scrollTop + pageOffset) {
      scrollTo(doPaging ? rowAtBottom : rowAtTop);
      render();
    }
  }

  void scrollRowToTop(int row) {
    scrollTo(row * gridOptions.rowHeight);
    render();
  }

  void scrollPage(int dir) {
    var deltaRows = dir * numVisibleRows;
    scrollTo((getRowFromPosition(scrollTop) + deltaRows) * gridOptions.rowHeight);
    render();

    if (gridOptions.enableCellNavigation && activeRow != null) {
      var row = activeRow + deltaRows;
      var dataLengthIncludingAddNew = getDataLengthIncludingAddNew();
      if (row >= dataLengthIncludingAddNew) {
        row = dataLengthIncludingAddNew - 1;
      }
      if (row < 0) {
        row = 0;
      }

      var cell = 0, prevCell = null;
      var prevActivePosX = activePosX;
      while (cell <= activePosX) {
        if (canCellBeActive(row, cell)) {
          prevCell = cell;
        }
        cell += getColspan(row, cell);
      }

      if (prevCell != null) {
        setActiveCellInternal(getCellNode(row, prevCell));
        activePosX = prevActivePosX;
      } else {
        resetActiveCell();
      }
    }
  }

  void navigatePageDown() => scrollPage(1);

  void navigatePageUp() {
    scrollPage(-1);
  }

  int getColspan(int row, int cell) {
    var metadata = data.getItemMetadata && data.getItemMetadata(row);
    if (!metadata || !metadata.columns) {
      return 1;
    }

    var columnData = metadata.columns[columns[cell].id] || metadata.columns[cell];
    var colspan = (columnData && columnData.colspan);
    if (colspan == "*") {
      colspan = columns.length - cell;
    } else {
      colspan = colspan || 1;
    }

    return colspan;
  }

  dom.HtmlElement findFirstFocusableCell(int row) {
    var cell = 0;
    while (cell < columns.length) {
      if (canCellBeActive(row, cell)) {
        return cell;
      }
      cell += getColspan(row, cell);
    }
    return null;
  }

  dom.HtmlElement findLastFocusableCell(int row) {
    var cell = 0;
    var lastFocusableCell = null;
    while (cell < columns.length) {
      if (canCellBeActive(row, cell)) {
        lastFocusableCell = cell;
      }
      cell += getColspan(row, cell);
    }
    return lastFocusableCell;
  }

  Map gotoRight(int row, int cell, int posX) {
    if (cell >= columns.length) {
      return null;
    }

    do {
      cell += getColspan(row, cell);
    }
    while (cell < columns.length && !canCellBeActive(row, cell));

    if (cell < columns.length) {
      return {
        "row": row,
        "cell": cell,
        "posX": cell
      };
    }
    return null;
  }

  Map<String,int> gotoLeft(int row, int cell, int posX) {
    if (cell <= 0) {
      return null;
    }

    var firstFocusableCell = findFirstFocusableCell(row);
    if (firstFocusableCell == null || firstFocusableCell >= cell) {
      return null;
    }

    var prev = {
      "row": row,
      "cell": firstFocusableCell,
      "posX": firstFocusableCell
    };
    var pos;
    while (true) {
      pos = gotoRight(prev['row'], prev['cell'], prev['posX']);
      if (pos == null) {
        return null;
      }
      if (pos['cell'] >= cell) {
        return prev;
      }
      prev = pos;
    }
  }

  Map<String,int> gotoDown(int row, int cell, int posX) {
    var prevCell;
    var dataLengthIncludingAddNew = getDataLengthIncludingAddNew();
    while (true) {
      if (++row >= dataLengthIncludingAddNew) {
        return null;
      }

      prevCell = cell = 0;
      while (cell <= posX) {
        prevCell = cell;
        cell += getColspan(row, cell);
      }

      if (canCellBeActive(row, prevCell)) {
        return {
          "row": row,
          "cell": prevCell,
          "posX": posX
        };
      }
    }
  }

  Map<String,int> gotoUp(int row, int cell, int posX) {
    var prevCell;
    while (true) {
      if (--row < 0) {
        return null;
      }

      prevCell = cell = 0;
      while (cell <= posX) {
        prevCell = cell;
        cell += getColspan(row, cell);
      }

      if (canCellBeActive(row, prevCell)) {
        return {
          "row": row,
          "cell": prevCell,
          "posX": posX
        };
      }
    }
  }

  Map<String,int> gotoNext(int row, int cell, int posX) {
    if (row == null && cell == null) {
      row = cell = posX = 0;
      if (canCellBeActive(row, cell)) {
        return {
          "row": row,
          "cell": cell,
          "posX": cell
        };
      }
    }

    var pos = gotoRight(row, cell, posX);
    if (pos) {
      return pos;
    }

    var firstFocusableCell = null;
    var dataLengthIncludingAddNew = getDataLengthIncludingAddNew();
    while (++row < dataLengthIncludingAddNew) {
      firstFocusableCell = findFirstFocusableCell(row);
      if (firstFocusableCell != null) {
        return {
          "row": row,
          "cell": firstFocusableCell,
          "posX": firstFocusableCell
        };
      }
    }
    return null;
  }

  Map<String,int> gotoPrev(int row, int cell, int posX) {
    if (row == null && cell == null) {
      row = getDataLengthIncludingAddNew() - 1;
      cell = posX = columns.length - 1;
      if (canCellBeActive(row, cell)) {
        return {
          "row": row,
          "cell": cell,
          "posX": cell
        };
      }
    }

    var pos;
    var lastSelectableCell;
    while (!pos) {
      pos = gotoLeft(row, cell, posX);
      if (pos) {
        break;
      }
      if (--row < 0) {
        return null;
      }

      cell = 0;
      lastSelectableCell = findLastFocusableCell(row);
      if (lastSelectableCell != null) {
        pos = {
          "row": row,
          "cell": lastSelectableCell,
          "posX": lastSelectableCell
        };
      }
    }
    return pos;
  }

  bool navigateRight() {
    return navigate("right");
  }

  bool navigateLeft() {
    return navigate("left");
  }

  bool navigateDown() {
    return navigate("down");
  }

  bool navigateUp() {
    return navigate("up");
  }

  bool navigateNext() {
    return navigate("next");
  }

  bool navigatePrev() {
    return navigate("prev");
  }

  /**
   * @param {string} dir Navigation direction.
   * @return {boolean} Whether navigation resulted in a change of active cell.
   */
  bool navigate(String dir) {
    if (!gridOptions.enableCellNavigation) {
      return false;
    }

    if (activeCellNode == null&& dir != "prev" && dir != "next") {
      return false;
    }

    if (!getEditorLock.commitCurrentEdit()) {
      return true;
    }
    setFocus();

    var tabbingDirections = {
      "up": -1,
      "down": 1,
      "left": -1,
      "right": 1,
      "prev": -1,
      "next": 1
    };
    tabbingDirection = tabbingDirections[dir];

    var stepFunctions = {
      "up": gotoUp,
      "down": gotoDown,
      "left": gotoLeft,
      "right": gotoRight,
      "prev": gotoPrev,
      "next": gotoNext
    };
    var stepFn = stepFunctions[dir];
    var pos = stepFn(activeRow, activeCell, activePosX);
    if (pos) {
      var isAddNewRow = (pos.row == getDataLength);
      scrollCellIntoView(pos.row, pos.cell, !isAddNewRow);
      setActiveCellInternal(getCellNode(pos.row, pos.cell));
      activePosX = pos.posX;
      return true;
    } else {
      setActiveCellInternal(getCellNode(activeRow, activeCell));
      return false;
    }
  }

  dom.HtmlElement getCellNode(int row, int cell) {
    if (rowsCache[row] != null) {
      ensureCellNodesInRowsCache(row);
      return rowsCache[row].cellNodesByColumnIdx[cell];
    }
    return null;
  }

  void setActiveCell(int row, int cell) {
    if (!initialized) { return; }
    if (row > getDataLength || row < 0 || cell >= columns.length || cell < 0) {
      return;
    }

    if (!gridOptions.enableCellNavigation) {
      return;
    }

    scrollCellIntoView(row, cell, false);
    setActiveCellInternal(getCellNode(row, cell), false);
  }

  bool canCellBeActive(row, cell) {
    if (!gridOptions.enableCellNavigation || row >= getDataLengthIncludingAddNew() ||
        row < 0 || cell >= columns.length || cell < 0) {
      return false;
    }

    var rowMetadata = data.getItemMetadata && data.getItemMetadata(row);
    if (rowMetadata && rowMetadata.focusable is bool) {
      return rowMetadata.focusable;
    }

    var columnMetadata = rowMetadata && rowMetadata.columns;
    if (columnMetadata && columnMetadata[columns[cell].id] && columnMetadata[columns[cell].id].focusable is bool) {
      return columnMetadata[columns[cell].id].focusable;
    }
    if (columnMetadata && columnMetadata[cell] && columnMetadata[cell].focusable is bool) {
      return columnMetadata[cell].focusable;
    }

    return columns[cell].focusable;
  }

  bool canCellBeSelected(row, cell) {
    if (row >= getDataLength || row < 0 || cell >= columns.length || cell < 0) {
      return false;
    }

    var rowMetadata = data.getItemMetadata && data.getItemMetadata(row);
    if (rowMetadata && rowMetadata.selectable is bool) {
      return rowMetadata.selectable;
    }

    var columnMetadata = rowMetadata && rowMetadata.columns && (rowMetadata.columns[columns[cell].id] || rowMetadata.columns[cell]);
    if (columnMetadata && columnMetadata.selectable is bool) {
      return columnMetadata.selectable;
    }

    return columns[cell].selectable;
  }

  void gotoCell(int row, int cell, bool forceEdit) {
    if (!initialized) { return; }
    if (!canCellBeActive(row, cell)) {
      return;
    }

    if (!getEditorLock.commitCurrentEdit()) {
      return;
    }

    scrollCellIntoView(row, cell, false);

    var newCell = getCellNode(row, cell);

    // if selecting the 'add new' row, start editing right away
    setActiveCellInternal(newCell, forceEdit || (row == getDataLength) || gridOptions.autoEdit);

    // if no editor was created, set the focus back on the grid
    if (currentEditor == null) {
      setFocus();
    }
  }


  //////////////////////////////////////////////////////////////////////////////////////////////
  // IEditor implementation for the editor lock

  bool commitCurrentEdit() {
    var item = getDataItem(activeRow);
    var column = columns[activeCell];

    if (currentEditor != null) {
      if (currentEditor.isValueChanged) {
        var validationResults = currentEditor.validate();

        if (validationResults.valid) {
          if (activeRow < getDataLength) {
            var editCommand = {
              'row': activeRow,
              'cell': activeCell,
              'editor': currentEditor,
              'serializedValue': currentEditor.serializeValue(),
              'prevSerializedValue': serializedEditorValue,
              'execute': () {
                this.editor.applyValue(item, this.serializedValue);
                updateRow(this.row);
                trigger(self.onCellChange, {
                  'row': activeRow,
                  'cell': activeCell,
                  'item': item
                });
              },
              'undo': () {
                this.editor.applyValue(item, this.prevSerializedValue);
                updateRow(this.row);
                trigger(self.onCellChange, {
                  'row': activeRow,
                  'cell': activeCell,
                  'item': item
                });
              }
            };

            if (gridOptions.editCommandHandler != null) {
              makeActiveCellNormal();
              gridOptions.editCommandHandler(item, column, editCommand);
            } else {
              editCommand['execute']();
              makeActiveCellNormal();
            }

          } else {
            var newItem = {};
            currentEditor.applyValue(newItem, currentEditor.serializeValue());
            makeActiveCellNormal();
            trigger(self.onAddNewRow, {item: newItem, column: column});
          }

          // check whether the lock has been re-acquired by event handlers
          return !getEditorLock.isActive;
        } else {
          // Re-add the CSS class to trigger transitions, if any.
          activeCellNode.classes.remove("invalid");
          activeCellNode.style.width;  // force layout // TODO ob das in Dart so funktioniert
          activeCellNode.classes.add("invalid");

          trigger(self.onValidationError, {
            'editor': currentEditor,
            'cellNode': activeCellNode,
            'validationResults': validationResults,
            'row': activeRow,
            'cell': activeCell,
            'column': column
          });

          currentEditor.focus();
          return false;
        }
      }

      makeActiveCellNormal();
    }
    return true;
  }

  bool cancelCurrentEdit() {
    makeActiveCellNormal();
    return true;
  }

  List<int> rowsToRanges(List<int> rows) {
    var ranges = [];
    var lastCell = columns.length - 1;
    for (var i = 0; i < rows.length; i++) {
      ranges.add(new Range(rows[i], 0, toRow: rows[i], toCell: lastCell));
    }
    return ranges;
  }

  List<int> getSelectedRows() {
    if (selectionModel == null) {
      throw "Selection model is not set";
    }
    return selectedRows;
  }

  void setSelectedRows(List<int> rows) {
    if (selectionModel == null) {
      throw "Selection model is not set";
    }
    selectionModel.setSelectedRanges(rowsToRanges(rows));
  }


  //////////////////////////////////////////////////////////////////////////////////////////////
  // Debug

  void debug () {
    var s =
    "counter_rows_rendered:  ${counter_rows_rendered}"
    "counter_rows_removed:  ${counter_rows_removed}"
    "renderedRows:  ${renderedRows}"
    "numVisibleRows:  ${numVisibleRows}"
    "maxSupportedCssHeight:  ${maxSupportedCssHeight}"
    "n(umber of pages):  ${n}"
    "(current) page:  ${page}"
    "page height (ph):  ${ph}";
    "vScrollDir:  ${vScrollDir}";

    dom.window.alert(s);
  }

  // a debug helper to be able to access private members
//    this.eval = function (expr) {
//      return eval(expr);
//    };

  //////////////////////////////////////////////////////////////////////////////////////////////
  // Public API

//    $.extend(this, {
//      "slickGridVersion": "2.1",

    // Events
//      "onScroll": new Slick.Event(),
//      "onSort": new Slick.Event(),
//      "onHeaderMouseEnter": new Slick.Event(),
//      "onHeaderMouseLeave": new Slick.Event(),
//      "onHeaderContextMenu": new Slick.Event(),
//      "onHeaderClick": new Slick.Event(),
//      "onHeaderCellRendered": new Slick.Event(),
//      "onBeforeHeaderCellDestroy": new Slick.Event(),
//      "onHeaderRowCellRendered": new Slick.Event(),
//      "onBeforeHeaderRowCellDestroy": new Slick.Event(),
//      "onMouseEnter": new Slick.Event(),
//      "onMouseLeave": new Slick.Event(),
//      "onClick": new Slick.Event(),
//      "onDblClick": new Slick.Event(),
//      "onContextMenu": new Slick.Event(),
//      "onKeyDown": new Slick.Event(),
//      "onAddNewRow": new Slick.Event(),
//      "onValidationError": new Slick.Event(),
//      "onViewportChanged": new Slick.Event(),
//      "onColumnsReordered": new Slick.Event(),
//      "onColumnsResized": new Slick.Event(),
//      "onCellChange": new Slick.Event(),
//      "onBeforeEditCell": new Slick.Event(),
//      "onBeforeCellEditorDestroy": new Slick.Event(),
//      "onBeforeDestroy": new Slick.Event(),
//      "onActiveCellChanged": new Slick.Event(),
//      "onActiveCellPositionChanged": new Slick.Event(),
//      "onDragInit": new Slick.Event(),
//      "onDragStart": new Slick.Event(),
//      "onDrag": new Slick.Event(),
//      "onDragEnd": new Slick.Event(),
//      "onSelectedRowsChanged": new Slick.Event(),
//      "onCellCssStylesChanged": new Slick.Event(),

    // Methods
//      "registerPlugin": registerPlugin,
//      "unregisterPlugin": unregisterPlugin,
//      "getColumns": getColumns,
//      "setColumns": setColumns,
//      "getColumnIndex": getColumnIndex,
//      "updateColumnHeader": updateColumnHeader,
//      "setSortColumn": setSortColumn,
//      "setSortColumns": setSortColumns,
//      "getSortColumns": getSortColumns,
//      "autosizeColumns": autosizeColumns,
//      "getOptions": getOptions,
//      "setOptions": setOptions,
//      "getData": getData,
//      "getDataLength": getDataLength,
//      "getDataItem": getDataItem,
//      "setData": setData,
//      "getSelectionModel": getSelectionModel,
//      "setSelectionModel": setSelectionModel,
//      "getSelectedRows": getSelectedRows,
//      "setSelectedRows": setSelectedRows,
//      "getContainerNode": getContainerNode,
//
//      "render": render,
//      "invalidate": invalidate,
//      "invalidateRow": invalidateRow,
//      "invalidateRows": invalidateRows,
//      "invalidateAllRows": invalidateAllRows,
//      "updateCell": updateCell,
//      "updateRow": updateRow,
//      "getViewport": getVisibleRange,
//      "getRenderedRange": getRenderedRange,
//      "resizeCanvas": resizeCanvas,
//      "updateRowCount": updateRowCount,
//      "scrollRowIntoView": scrollRowIntoView,
//      "scrollRowToTop": scrollRowToTop,
//      "scrollCellIntoView": scrollCellIntoView,
//      "getCanvasNode": getCanvasNode,
//      "focus": setFocus,
//
//      "getCellFromPoint": getCellFromPoint,
//      "getCellFromEvent": getCellFromEvent,
//      "getActiveCell": getActiveCell,
//      "setActiveCell": setActiveCell,
//      "getActiveCellNode": getActiveCellNode,
//      "getActiveCellPosition": getActiveCellPosition,
//      "resetActiveCell": resetActiveCell,
//      "editActiveCell": makeActiveCellEditable,
//      "getCellEditor": getCellEditor,
//      "getCellNode": getCellNode,
//      "getCellNodeBox": getCellNodeBox,
//      "canCellBeSelected": canCellBeSelected,
//      "canCellBeActive": canCellBeActive,
//      "navigatePrev": navigatePrev,
//      "navigateNext": navigateNext,
//      "navigateUp": navigateUp,
//      "navigateDown": navigateDown,
//      "navigateLeft": navigateLeft,
//      "navigateRight": navigateRight,
//      "navigatePageUp": navigatePageUp,
//      "navigatePageDown": navigatePageDown,
//      "gotoCell": gotoCell,
//      "getTopPanel": getTopPanel,
//      "setTopPanelVisibility": setTopPanelVisibility,
//      "setHeaderRowVisibility": setHeaderRowVisibility,
//      "getHeaderRow": getHeaderRow,
//      "getHeaderRowColumn": getHeaderRowColumn,
//      "getGridPosition": getGridPosition,
//      "flashCell": flashCell,
//      "addCellCssStyles": addCellCssStyles,
//      "setCellCssStyles": setCellCssStyles,
//      "removeCellCssStyles": removeCellCssStyles,
//      "getCellCssStyles": getCellCssStyles,
//
//      "init": finishInitialization,
//      "destroy": destroy,
//
//      // IEditor implementation
//      "getEditorLock": getEditorLock,
//      "getEditController": getEditController
//  });
//}

}

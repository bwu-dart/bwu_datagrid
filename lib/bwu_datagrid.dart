library bwu_dart.bwu_datagrid.datagrid;

import 'dart:async' as async;
import 'dart:math' as math;
import 'dart:html' as dom;

import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/core/core.dart' as core;
//import 'dataview/dataview.dart';
import 'package:bwu_datagrid/plugins/plugin.dart';

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/editors/editors.dart';
import 'package:bwu_datagrid/datagrid/bwu_datagrid_headerrow_column.dart';
import 'package:bwu_datagrid/datagrid/bwu_datagrid_header_column.dart';
import 'package:bwu_datagrid/datagrid/bwu_datagrid_headers.dart';
import 'package:bwu_datagrid/dataview/dataview.dart';
import 'package:bwu_datagrid/tools/html.dart' as tools;
import 'package:bwu_datagrid/formatters/formatters.dart';



@CustomTag('bwu-datagrid')
class BwuDatagrid extends PolymerElement {

  BwuDatagrid.created() : super.created();

  @override
  void enteredView() {
    try {
    super.enteredView();
    new async.Future(() {
      init();
      render();
    });
    }catch(e) {
      print('BwuDataGrid.enteredView(): $e');
    }
  }

  // DataGrid(dom.HtmlElement container, String data, int columns, Options options);
  @published List<Map> data;
  @published DataView dataView;
  @published List<Column> columns;
  @published GridOptions gridOptions = new GridOptions();

  // settings
  Column columnOptions = new Column();

  dom.NodeValidator nodeValidator = new dom.NodeValidatorBuilder.common();

  // scroller
  int th;   // virtual height
  double h;    // real scrollable height
  double ph;   // page height
  int n;    // number of pages
  double cj;   // "jumpiness" coefficient

  int page = 0;       // current page
  int pageOffset = 0;     // current page offset
  int vScrollDir = 1;

  // shared across all grids on the page
  math.Point scrollbarDimensions;
  int maxSupportedCssHeight;  // browser's breaking point

  // private
  bool initialized = false;
  dom.ShadowRoot $container;
  //String uid = "bwu_datagrid_${(1000000 * new math.Random().nextDouble()).round()}";
  dom.HtmlElement $focusSink, $focusSink2;
  dom.HtmlElement $headerScroller;
  BwuDatagridHeaders $headers;
  dom.HtmlElement $headerRow, $headerRowScroller, $headerRowSpacer;
  dom.HtmlElement $topPanelScroller;
  dom.HtmlElement $topPanel;
  dom.HtmlElement $viewport;
  dom.HtmlElement $canvas;
  dom.StyleElement $style;
  dom.HtmlElement $boundAncestors;
  dom.CssStyleSheet stylesheet;
  Map<int,dom.CssStyleRule> columnCssRulesL, columnCssRulesR;
  int viewportH = 0;
  int viewportW = 0;
  int canvasWidth;
  bool viewportHasHScroll = false, viewportHasVScroll = false;
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

  Map<int,RowCache> rowsCache = {};
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
  Map<String,Map<int,String>> cellCssClasses = {};

  Map<String,int> columnsById = {};
  List<SortColumn> sortColumns = [];
  List<int> columnPosLeft = [];
  List<int> columnPosRight = [];


  // async call handles
  async.Timer h_editorLoader = null;
  async.Timer h_render = null;
  async.Timer h_postrender = null;
  List<List<int>> postProcessedRows = [];
  int postProcessToRow = null;
  int postProcessFromRow = null;

  // perf counters
  int counter_rows_rendered = 0;
  int counter_rows_removed = 0;

  // These two variables work around a bug with inertial scrolling in Webkit/Blink on Mac.
  // See http://crbug.com/312427.
  dom.HtmlElement rowNodeFromLastMouseWheelEvent;  // this node must not be deleted while inertial scrolling
  dom.HtmlElement zombieRowNodeFromLastMouseWheelEvent;  // node that was hidden instead of getting deleted

  final core.EventBus eventBus = new core.EventBus();


  //////////////////////////////////////////////////////////////////////////////////////////////
  // Initialization

  void init() {
    $container = this.shadowRoot;

    // calculate these only once and share between grid instances
    maxSupportedCssHeight = maxSupportedCssHeight != null ? maxSupportedCssHeight : getMaxSupportedCssHeight();
    scrollbarDimensions = scrollbarDimensions != null ? scrollbarDimensions : measureScrollbar();

    //options = $.extend({}, defaults, options);
    validateAndEnforceOptions();
    columnOptions.width = gridOptions.defaultColumnWidth;

    columnsById = {};
    if(columns != null) {
      for (int i = 0; i < columns.length; i++) {
        Column m = new Column()..extend(columnOptions)..extend(columns[i]); // TODO extend
        columns[i] = m;
        columnsById[m.id] = i;
        if (m.minWidth != null && m.width < m.minWidth) {
          m.width = m.minWidth;
        }
        if (m.maxWidth != null && m.width > m.maxWidth) {
          m.width = m.maxWidth;
        }
        //dom.document.head.append(new dom.StyleElement());
      }
    }

// TODO port jQuery UI sortable
//    // validate loaded JavaScript modules against requested options
//    if (gridOptions.enableColumnReorder && !$.fn.sortable) {
//      throw "DataGrid's 'enableColumnReorder = true' option requires jquery-ui.sortable module to be loaded";
//    }

    editController = new EditController(commitCurrentEdit, cancelCurrentEdit);

    //$container
        //..children.clear(); // TODO empty()
    this
        ..style.overflow = 'hidden'
        ..style.outline = '0'
        ..style.display = 'block' // TODO should be inside the style tag
        //..classes.add(uid)
        ..classes.add("ui-widget");

    // set up a positioning container if needed
//      if (!/relative|absolute|fixed/.test($container.css("position"))) {
//        $container.css("position", "relative");
//      }
    if(!this.style.position.contains(new RegExp('relative|absolute|fixed'))) {
      this.style.position = 'relative';
    }

    $focusSink = new dom.DivElement()
      ..tabIndex=0
      //..hideFocus=true // IE
      ..style.position = 'fixed'
      ..style.width='0'
      ..style.height='0'
      ..style.top='0'
      ..style.left='0'
      ..style.outline='0';
    $container.append($focusSink);

    $headerScroller = new dom.DivElement()
      ..classes.add('bwu-datagrid-header')
      ..classes.add('ui-state-default')
      ..style.overflow ='hidden'
      ..style.position='relative';
    $container.append($headerScroller);

    $headers = (new dom.Element.tag('bwu-datagrid-headers') as BwuDatagridHeaders)
      ..classes.add('bwu-datagrid-header-columns')
      ..style.left = '-1000px';
    $headerScroller.append($headers);
    $headers.style.width = "${getHeadersWidth()}px";

    $headerRowScroller = new dom.DivElement()
      ..classes.add('bwu-datagrid-headerrow')
      ..classes.add('ui-state-default')
      ..style.overflow = 'hidden'
      ..style.position='relative';
    $container.append($headerRowScroller);

    $headerRow = new dom.DivElement()
      ..classes.add('bwu-datagrid-headerrow-columns');
    $headerRowScroller.append($headerRow);

    $headerRowSpacer = new dom.DivElement()
      ..style.display = 'block'
      ..style.height ='1px'
      ..style.position ='absolute'
      ..style.top ='0'
      ..style.left='0'
        ..style.width = '${getCanvasWidth() + scrollbarDimensions.x}px';
    $headerRowScroller.append($headerRowSpacer);

    $topPanelScroller = new dom.DivElement()
      ..classes.add('bwu-datagrid-top-panel-scroller')
      ..classes.add('ui-state-default')
      ..style.overflow ='hidden'
      ..style.position='relative';
    $container.append($topPanelScroller);
    $topPanel = new dom.DivElement()
      ..classes.add('bwu-datagrid-top-panel')
      ..style.width='10000px';
    $topPanelScroller.append($topPanel);

    if (!gridOptions.showTopPanel) {
      $topPanelScroller.style.display = 'none'; //hide();
    }

    if (!gridOptions.showHeaderRow) {
      $headerRowScroller.style.display = 'none'; // hide();
    }

    $viewport = new dom.DivElement()
      ..classes.add('bwu-datagrid-viewport')
      ..style.width='100%'
      ..style.overflow ='auto'
      ..style.outline='0'
      ..style.position='relative';
    $container.append($viewport);
    $viewport.style.overflowY = gridOptions.autoHeight ? "hidden" : "auto";

    $canvas = new dom.DivElement()..classes.add('grid-canvas');
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

      viewportW = this.offsetWidth; //tools.parseInt(this.getComputedStyle().width);

      // header columns and cells may have different padding/border skewing width calculations (box-sizing, hello?)
      // calculate the diff so we can set consistent sizes
      measureCellPaddingAndBorder();

      // for usability reasons, all text selection in BwuDatagrid is disabled
      // with the exception of input and textarea elements (selection must
      // be enabled there so that editors work as expected); note that
      // selection in grid cells (grid body) is already unavailable in
      // all browsers except IE
      disableSelection($headers); // disable all text selection in header (including input and textarea)

      if (!gridOptions.enableTextSelectionOnCells) {
        // disable text selection in grid cells except in input and textarea elements
        // (this is IE-specific, because selectstart event will only fire in IE)
        $viewport.onSelectStart.listen((event) {  //  bind("selectstart.ui",
          return event.target is dom.InputElement || event.target is dom.TextAreaElement;
        });
      }

      updateColumnCaches();
      createColumnHeaders();
      setupColumnSort();
      createCssRules();
      resizeCanvas();
      bindAncestorScrollEvents();

      $container.on["resize.bwu-datagrid"].listen(resizeCanvas); // TODO event name seems wrong
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
          ..onDrag.listen(handleDrag)
          //..bind("draginit", handleDragInit) // TODO special jQuery event before DragStart (click)
          ..onDragStart.listen((e) {/*{distance: 3}*/; handleDragStart(e, {'distance': 3});}) // TODO what is distance?
          ..onDragOver.listen(handleDrag)
          ..onDragEnd.listen(handleDragEnd);
//          ..querySelectorAll(".bwu-datagrid-cell").forEach((e) {
//            (e as dom.HtmlElement)
//              ..onMouseEnter.listen(handleMouseEnter)
//              ..onMouseLeave.listen(handleMouseLeave);
//          });

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
      onSelectedRangesChanged = selectionModel.onSelectedRangesChanged.listen(selectedRangesChangedHandler);
    }
  }

  SelectionModel get getSelectionModel => selectionModel;

  dom.HtmlElement get getCanvasNode => $canvas;



  math.Point measureScrollbar() {
    dom.HtmlElement $c = new dom.DivElement()
      ..style.position = 'absolute'
      ..style.top ='-10000px'
      ..style.left = '10000px'
      ..style.width = '100px'
      ..style.height ='100px'
      ..style.overflow = 'scroll';
    dom.document.body.append($c);
    var cCs = $c.getComputedStyle();
    var dim = new math.Point(tools.parseInt(cCs.width) - $c.clientWidth, tools.parseInt(cCs.height) - $c.clientHeight);
    $c.remove();
    return dim;
  }

  int getHeadersWidth() {
    var headersWidth = 0;
    int ii = columns != null ? columns.length : 0;
    for (int i = 0;  i < ii; i++) {
      int width = columns[i].width;
      headersWidth += width;
    }
    headersWidth += scrollbarDimensions.x;
    return math.max(headersWidth, viewportW) + 1000;
  }

  int getCanvasWidth() {
    int availableWidth = viewportHasVScroll ? viewportW - scrollbarDimensions.x : viewportW;
    int rowWidth = 0;
    int i = columns != null ? columns.length : 0;
    while (i-- > 0) {
      rowWidth += columns[i].width;
    }
    return gridOptions.fullWidthRows ? math.max(rowWidth, availableWidth) : rowWidth;
  }

  void updateCanvasWidth(forceColumnWidthsUpdate) {
    int oldCanvasWidth = canvasWidth;
    canvasWidth = getCanvasWidth();

    if (canvasWidth != oldCanvasWidth) {
      $canvas.style.width = "${canvasWidth}px";
      $headerRow.style.width = "${canvasWidth}px";
      $headers.style.width = "${getHeadersWidth()}px";
      viewportHasHScroll = (canvasWidth > viewportW - scrollbarDimensions.x);
    }

    $headerRowSpacer.style.width = "${(canvasWidth + (viewportHasVScroll ? scrollbarDimensions.x : 0))}px";

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
    var div = new dom.DivElement()..style.display='none';
    dom.document.body.append(div);

    while (true) {
      int test = supportedHeight * 2;
      div.style.height = "${test}px";
      if (test > testUpTo || div.getComputedStyle().height != "${test}px") {
        break;
      } else {
        supportedHeight = test;
      }
    }

    div.remove();
    return supportedHeight;
  }

  List<async.StreamSubscription> scrollSubscription = [];

  // TODO:  this is static.  need to handle page mutation.
  void bindAncestorScrollEvents() {
    var $elem = $canvas;

    if($elem.parentNode is dom.ShadowRoot) {
      $elem = ($elem.parentNode as dom.ShadowRoot).host;
    } else {
      $elem = $elem.parent;
    }

    while ($elem != this && $elem != null) {
      // bind to scroll containers only
      if ($elem == $viewport || $elem.scrollWidth != $elem.clientWidth || $elem.scrollHeight != $elem.clientHeight) {
        if ($boundAncestors == null) {
          $boundAncestors = $elem;
        } else {
          try {
            $boundAncestors.append($elem);
          } catch (e) {
            print(e);
          }
        }
        scrollSubscription.add($elem.onScroll.listen(handleActiveCellPositionChange));
      }
      if($elem.parentNode is dom.ShadowRoot) {
        $elem = ($elem.parentNode as dom.ShadowRoot).host;
      } else {
        $elem = $elem.parent;
      }
    }
  }

  void unbindAncestorScrollEvents() {
    if ($boundAncestors == null) {
      return;
    }
    scrollSubscription.forEach((e) => e.cancel());
    scrollSubscription.clear();
    //$boundAncestors.unbind("scroll." + uid);
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

      eventBus.fire(core.Events.BEFORE_HEADER_CELL_DESTROY, new core.BeforeHeaderCellDestroy(this, $header, columnDef));

//      fire(ON_BEFORE_HEADER_CELL_DESTROY, detail: {
//        "node": $header.children[0],
//        "column": columnDef
//      });

      $header
          ..attributes["title"] = toolTip != null ? toolTip : ""
          ..children.where((e) => e.id == 0).forEach((e) => e.innerHtml = title); //().eq(0).html(title); // TODO check

      eventBus.fire(core.Events.HEADER_CELL_RENDERED, new core.HeaderCellRendered(this, $header, columnDef));

//      fire(ON_HEADER_CELL_RENDERED, detail: {
//        "node": $header.children[0],
//        "column": columnDef
//      });
    }
  }

  dom.HtmlElement getHeaderRow() {
    return $headerRow;
  }

  dom.HtmlElement getHeaderRowColumn(columnId) {
    var idx = getColumnIndex(columnId);
    dom.HtmlElement $header = $headerRow.children.firstWhere((e) => e == idx); //.eq(idx); // TODO check
    if($header != null && $header.children.length > 0) {
      return $header;
    }
    return null;
  }

  void createColumnHeaders() {
    var onMouseEnter = (dom.MouseEvent e) {
      (e.target as dom.HtmlElement).classes.add("ui-state-hover");
    };

    var onMouseLeave = (dom.MouseEvent e) {
      (e.target as dom.HtmlElement).classes.remove("ui-state-hover");
    };

    $headers.querySelectorAll(".bwu-datagrid-header-column")
      .forEach((BwuDatagridHeaderColumn e) { // TODO check self/this
        Column columnDef = e.column;
        if (columnDef != null) {
          eventBus.fire(core.Events.BEFORE_HEADER_CELL_DESTROY, new core.BeforeHeaderCellDestroy(this, e, columnDef));
//          fire(ON_BEFORE_HEADER_CELL_DESTROY, detail: {
//            "node": e,
//            "column": columnDef
//          });
        }
      });
    $headers.children.clear();
    $headers.style.width = "${getHeadersWidth()}px";

    $headerRow.querySelectorAll(".bwu-datagrid-headerrow-column")
      .forEach((BwuDatagridHeaderrowColumn e) { // TODO check self/this
        Column columnDef = e.column;
        if (columnDef != null) {
          eventBus.fire(core.Events.BEFORE_HEADER_CELL_DESTROY, new core.BeforeHeaderCellDestroy(this, e, columnDef));
//          fire(ON_BEFORE_HEADER_CELL_DESTROY, detail: {
//            "node": e,
//            "column": columnDef
//          });
        }
      });
    $headerRow.children.clear();

    if(columns != null) {
      for (int i = 0; i < columns.length; i++) {
        Column m = columns[i];

        var header = (new dom.Element.tag('bwu-datagrid-header-column') as BwuDatagridHeaderColumn)
            ..classes.add('ui-state-default')
            ..classes.add('bwu-datagrid-header-column')
            ..append(new dom.Element.html("<span class='bwu-datagrid-column-name'>" + m.name + "</span>", validator: nodeValidator))
            ..style.width = "${m.width - headerColumnWidthDiff}px"
            //..attributes["id"] ='${uid}${m.id}'
            ..attributes["id"] ='${m.id}'
            ..attributes["title"] = m.toolTip != null ? m.toolTip : ""
            ..column = m
            ..classes.add(m.headerCssClass != null ? m.headerCssClass : "");
        $headers.append(header);

        if (gridOptions.enableColumnReorder || m.sortable) {
          header
            ..onMouseEnter.listen(onMouseEnter)
            ..onMouseLeave.listen(onMouseLeave);
        }

        if (m.sortable) {
          header.classes.add("bwu-datagrid-header-sortable");
          header.append(new dom.Element.html("<span class='bwu-datagrid-sort-indicator' />", validator: nodeValidator));
        }

        eventBus.fire(core.Events.HEADER_CELL_RENDERED, new core.HeaderCellRendered(this, header, m));

  //      fire(ON_HEADER_CELL_RENDERED, detail: {
  //        "node": header.children[0],
  //        "column": m
  //      });

        if (gridOptions.showHeaderRow) {
          var headerRowCell = (new dom.Element.tag('bwu-datagrid-headerrow-column') as BwuDatagridHeaderrowColumn)
              ..classes.add('ui-state-default')
              ..classes.add('bwu-datagrid-headerrow-column')
              ..classes.add('l${i}')
              ..classes.add('r${i}')
              ..column =  m;
              $headerRow.append(headerRowCell);

              eventBus.fire(core.Events.HEADER_CELL_RENDERED, new core.HeaderCellRendered(this, headerRowCell, m));

  //        fire(ON_HEADER_ROW_CELL_RENDERED, detail: {
  //          "node": headerRowCell.children[0],
  //          "column": m
  //        });
        }
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
      // e.metaKey = e.metaKey || e.ctrlKey; // TODO process Ctrl-key

      if ((e.target as dom.HtmlElement).classes.contains("bwu-datagrid-resizable-handle")) {
        return;
      }

      var $col = tools.closest((e.target as dom.HtmlElement), '.bwu-datagrid-header-column') as BwuDatagridHeaderColumn;
      if ($col.children.length > 0) {
        return;
      }

      Column column = $col.column;
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
          eventBus.fire(core.Events.SORT, new core.Sort(this, false, column, null, sortOpts.sortAsc, e));

//          fire(ON_SORT, detail: {
//            'multiColumnSort': false,
//            'sortCol': column,
//            'sortAsc': sortOpts.sortAsc,
//            'caused_by': e});
        } else {
          var sortCols = new Map.fromIterable(sortColumns, key: (k) => columns[getColumnIndex(k.columnId)], value: (k) => k.sortAsc);
          eventBus.fire(core.Events.SORT, new core.Sort(this, true, null, sortCols, null, e));
//          fire(ON_SORT, detail: {
//            'multiColumnSort': true,
//            'sortCols': $.map(sortColumns, (col) { // TODO map
//              return {'sortCol': columns[getColumnIndex(col.columnId)], 'sortAsc': col.sortAsc };
//            }),
//            'caused_by': e});
        }
      }
    });
  }

  void setupColumnReorder() {
    $headers.filter = new Filter(":ui-sortable")..sortable.destroy(); //("destroy");
    $headers.sortable = new Sortable(
      containment: 'parent',
      distance: 3,
      axis: 'x',
      cursor: 'default',
      tolerance: 'intersection',
      helper: 'clone',
      placeholder: 'bwu-datagrid-sortable-placeholder ui-state-default bwu-datagrid-header-column',
      start: (e, ui) {
        ui.placeholder.width(tools.outerWidth(ui) - headerColumnWidthDiff);
        (ui.helper as dom.HtmlElement).classes.add('bwu-datagrid-header-column-active');
      },
      beforeStop: (e, ui) {
        (ui.helper as dom.HtmlElement).classes.remove('bwu-datagrid-header-column-active');
      });
    $headers.sortable.stop =
      (e) {
        if (!getEditorLock.commitCurrentEdit()) {
          $headers.sortable.cancel(); //('cancel'); // TODO
          return;
        }

        var reorderedIds = $headers.sortable.toArray(); //("toArray");
        var reorderedColumns = [];
        for (var i = 0; i < reorderedIds.length; i++) {
          reorderedColumns.add(columns[getColumnIndex(reorderedIds[i].replace(uid, ""))]); // TODO what is uid for here?
        }
        setColumns = reorderedColumns;

        eventBus.fire(core.Events.COLUMNS_REORDERED, new core.ColumnsReordered(this));
        //fire(ON_COLUMNS_REORDERED, detail: {});
        e.stopPropagation();
        setupColumnResize();
      };
  }

  void setupColumnResize() {
    Column c;
    int pageX;
    List<BwuDatagridHeaderColumn> columnElements;
    int minPageX, maxPageX;
    int firstResizable, lastResizable;
    columnElements = new List<BwuDatagridHeaderColumn>.from($headers.children);
    $headers.querySelectorAll(".bwu-datagrid-resizable-handle").forEach((dom.HtmlElement e) {
      e.remove();
    });
    for(int i = 0; i < columnElements.length; i++) {
      if (columns[i].resizable) {
        if (firstResizable == null) {
          firstResizable = i;
        }
        lastResizable = i;
      }
    }
    if (firstResizable == null) {
      return;
    }
    for(int i = 0; i < columnElements.length; i++) {
      var header_col = columnElements[i];
      if (i < firstResizable || (gridOptions.forceFitColumns && i >= lastResizable)) {
        return;
      }

      var div = new dom.DivElement()
        ..classes.add('bwu-datagrid-resizable-handle')
        ..draggable = true;
      header_col.append(div);

      div
          ..onDragStart.listen((dom.MouseEvent e) {
            if (!getEditorLock.commitCurrentEdit()) {
              return false;
            }
            pageX = e.page.x;
            (e.target as dom.HtmlElement).parent.classes.add("bwu-datagrid-header-column-active");
            int shrinkLeewayOnRight = null, stretchLeewayOnRight = null;
            // lock each column's width option to current width
            for(int i = 0; i < columnElements.length; i++) {
              columns[i].previousWidth = tools.outerWidth(columnElements[i]);
            }
            if (gridOptions.forceFitColumns) {
              shrinkLeewayOnRight = 0;
              stretchLeewayOnRight = 0;
              // colums on right affect maxPageX/minPageX
              for (int j = i + 1; j < columnElements.length; j++) {
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
            for (int j = 0; j <= i; j++) {
              // columns on left only affect minPageX
              c = columns[j];
              if (c.resizable) {
                if (stretchLeewayOnLeft != null) {
                  if (c.maxWidth != null) {
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

          ..onDrag.listen((dom.MouseEvent e) {
            int actualMinWidth;
            if(e.page.x == 0) {
              return;
            }
            int d = math.min(maxPageX, math.max(minPageX, e.page.x)) - pageX;
            int x;
            if (d < 0) { // shrink column
              x = d;
              for (int j = i; j >= 0; j--) {
                c = columns[j];
                if (c.resizable) {
                  actualMinWidth = math.max(c.minWidth != null ? c.minWidth : 0, absoluteColumnMinWidth);
                  if (x != null && c.previousWidth + x < actualMinWidth) {
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
                for (int j = i + 1; j < columnElements.length; j++) {
                  c = columns[j];
                  if (c.resizable) {
                    if (x && c.maxWidth != null && (c.maxWidth - c.previousWidth < x)) {
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
              for (int j = i; j >= 0; j--) {
                c = columns[j];
                if (c.resizable) {
                  if (x > 0 && c.maxWidth != null && (c.maxWidth - c.previousWidth < x)) {
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
                for (int j = i + 1; j < columnElements.length; j++) {
                  c = columns[j];
                  if (c.resizable) {
                    actualMinWidth = math.max(c.minWidth != null ? c.minWidth : 0, absoluteColumnMinWidth);
                    if (x > 0 && c.previousWidth + x < actualMinWidth) {
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

          ..onDragEnd.listen((dom.MouseEvent e) {
            var newWidth;
            (e.target as dom.HtmlElement).parent.classes.remove("bwu-datagrid-header-column-active");
            for (int j = 0; j < columnElements.length; j++) {
              c = columns[j];
              newWidth = tools.outerWidth(columnElements[j]);

              if (c.previousWidth != newWidth && c.rerenderOnResize) {
                invalidateAllRows();
              }
            }
            updateCanvasWidth(true);
            render();
            eventBus.fire(core.Events.COLUMNS_RESIZED, new core.ColumnsResized(this));
            //fire(ON_COLUMNS_RESIZED, detail: {});
          });
    }
  }

  int getVBoxDelta(dom.HtmlElement $el) {
    var p = ["borderTopWidth", "borderBottomWidth", "paddingTop", "paddingBottom"];
    var delta = 0;
    var gcs = $el.getComputedStyle();
    delta += tools.parseInt(gcs.borderTopWidth)
        + tools.parseInt(gcs.borderBottomWidth)
        + tools.parseInt(gcs.paddingTop)
        + tools.parseInt(gcs.paddingBottom);

//    p.forEach((prop) {
//      delta += tools.parseInt($el.style.getPropertyValue(prop)); // || 0; // TODO
//    });
    return delta;
  }

  void measureCellPaddingAndBorder() {
    var el;
    // changed to direct property access due to https://code.google.com/p/dart/issues/detail?id=18765
//    var h = ["borderLeftWidth", "borderRightWidth", "paddingLeft", "paddingRight"];
//    var v = ["borderTopWidth", "borderBottomWidth", "paddingTop", "paddingBottom"];

    el = (new dom.Element.tag('bwu-datagrid-header-column') as BwuDatagridHeaderColumn)
      ..classes.add('ui-state-default')
      ..classes.add('bwu-datagrid-header-column')
      ..style.visibility = 'hidden';
    $headers.append(el);
    headerColumnWidthDiff = headerColumnHeightDiff = 0;
    var gcs = el.getComputedStyle();
    if (el.style.boxSizing != "border-box") {
      //h.forEach((prop) {
        headerColumnWidthDiff = tools.parseInt(gcs.borderLeftWidth)
        + tools.parseInt(gcs.borderRightWidth)
        + tools.parseInt(gcs.paddingLeft)
        + tools.parseInt(gcs.paddingRight);
             // || 0; // TODO
      //});
      //v.forEach((prop) {
      //  headerColumnHeightDiff += tools.parseInt(gcs.getPropertyValue(prop)); //; || 0; // TODO
      //});
        headerColumnHeightDiff = tools.parseInt(gcs.borderTopWidth)
            + tools.parseInt(gcs.borderBottomWidth)
            + tools.parseInt(gcs.paddingTop)
            + tools.parseInt(gcs.paddingBottom);
    }
    el.remove();

    var r = new dom.Element.html("<div class='bwu-datagrid-row' />", validator: nodeValidator);
    $canvas.append(r);
    el = new dom.DivElement()
      ..id=''
      ..classes.add('bwu-datagrid-cell')
      ..style.visibility='hidden'
      ..appendText('-');

    r.append(el);
    gcs = el.getComputedStyle();
    cellWidthDiff = cellHeightDiff = 0;
    if (el.style.boxSizing != "border-box") {
//      h.forEach((prop) {
//        var val = tools.parseInt(el.getComputedStyle().getPropertyValue(prop));
//        cellWidthDiff += val != null ? val : 0; // TODO
//      });
      cellWidthDiff = tools.parseInt(gcs.borderLeftWidth)
              + tools.parseInt(gcs.borderRightWidth)
              + tools.parseInt(gcs.paddingLeft)
              + tools.parseInt(gcs.paddingRight);
//      v.forEach((prop) {
//        var val = tools.parseInt(el.getComputedStyle().getPropertyValue(prop));
//        cellHeightDiff += val != null ? val : 0; // TODO
//      });
      cellHeightDiff = tools.parseInt(gcs.borderTopWidth)
          + tools.parseInt(gcs.borderBottomWidth)
          + tools.parseInt(gcs.paddingTop)
          + tools.parseInt(gcs.paddingBottom);

    }
    //var x = r.getComputedStyle();
    r.remove();

    absoluteColumnMinWidth = math.max(headerColumnWidthDiff, cellWidthDiff);
  }

  void createCssRules() {
    $style = new dom.StyleElement();//.html("<style type='text/css' rel='stylesheet' />", validator: nodeValidator);
    //dom.document.head.append($style);
    this.shadowRoot.append($style);
    var rowHeight = (gridOptions.rowHeight - cellHeightDiff);
    var rules = [
      ".bwu-datagrid-header-column { left: 1000px; }",
      ".bwu-datagrid-top-panel { height:${gridOptions.topPanelHeight}px; }",
      ".bwu-datagrid-headerrow-columns { height:${gridOptions.headerRowHeight}px; }",
      ".bwu-datagrid-cell { height:${rowHeight}px; }",
      ".bwu-datagrid-row { height:${gridOptions.rowHeight}px; }"
    ];

    if(columns != null) {
      for (int i = 0; i < columns.length; i++) {
        rules.add(".l${i} { }");
        rules.add(".r${i} { }");
      }
    }

//    for(int i = 0; i < rules.length; i++) {
//      ($style.sheet as dom.CssStyleSheet).insertRule(rules[i], i);
//    }
    $style.appendText(rules.join(" "));
  }

  // TODO keep the rules in a collection to avoid parsing them
  Map<String,dom.CssStyleRule> getColumnCssRules(int idx) {
    if (stylesheet == null) {
//      var sheets = this.shadowRoot.styleSheets;
//      for (int i = 0; i < sheets.length; i++) {
//        if (sheets[i].ownerNode != null && sheets[i].ownerNode == $style) {
//          stylesheet = sheets[i];
//          break;
//        }
//      }
//
//      if (stylesheet == null) {
//        throw "Cannot find stylesheet.";
//      }

      stylesheet = $style.sheet;

      // find and cache column CSS rules
      columnCssRulesL = {};
      columnCssRulesR = {};
      var cssRules = stylesheet.cssRules;
      Match matches;
      int columnIdx;
      for (var i = 0; i < cssRules.length; i++) {
        var selector = cssRules[i].selectorText;
        matches = new RegExp(r'(?:\.l)(\d+)').firstMatch(selector);
        if (matches != null) {
          columnIdx = tools.parseInt(matches.group(1)); // first.substr(2, matches.first.length - 2));
          columnCssRulesL[columnIdx] = cssRules[i];
        } else {
          matches = new RegExp(r'(?:\.r)(\d+)').firstMatch(selector);
          if (matches != null) {
            columnIdx = tools.parseInt(matches.group(1)); //first.substr(2, matches.first.length - 2));
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

    eventBus.fire(core.Events.BEFORE_DESTROY, new core.BeforeDestroy(this));
    //fire(ON_BEFORE_DESTROY, detail: {});

    var i = plugins.length;
    while(i--) {
      unregisterPlugin(plugins[i]);
    }

    if (gridOptions.enableColumnReorder) {
        $headers.filter = new Filter(":ui-sortable")..sortable.destroy(); //("destroy"); // TODO
    }

    unbindAncestorScrollEvents();
    // $container.unbind(".bwu-datagrid"); // TODO
    removeCssRules();

    // $canvas.unbind("draginit dragstart dragend drag"); // TODO
    //$container
    //    ..children.clear();
    //this.classes.remove(uid);
  }


  //////////////////////////////////////////////////////////////////////////////////////////////
  // General

//  function trigger(evt, args, e) {
//    e = e || new EventData();
//    args = args || {};
//    args.grid = self;
//    return evt.notify(args, e, self);
//  }

  core.EditorLock get getEditorLock => gridOptions.editorLock;

  EditController get getEditController => editController;

  int getColumnIndex(id) => columnsById[id];

  void autosizeColumns() {
    int i;
    Column c;
    List<int> widths = [];
    int shrinkLeeway = 0;
    int total = 0;
    int prevTotal;
    int availWidth = viewportHasVScroll ? viewportW - scrollbarDimensions.x : viewportW;

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
      if (h.style.width != columns[i].width - headerColumnWidthDiff) { // TODO comparsion
        h.style.width = '${columns[i].width - headerColumnWidthDiff}px';
      }
    }

    updateColumnCaches();
  }

  void applyColumnWidths() {
    int x = 0;
    int w;
    Map<String,dom.CssStyleRule> rule;
    if(columns != null) {
      for (var i = 0; i < columns.length; i++) {
        w = columns[i].width;

        rule = getColumnCssRules(i);
        rule['left'].style.left = '${x}px';
        rule['right'].style.right = '${(canvasWidth - x - w)}px';

        x += columns[i].width;
      }
    }

//    String s = '';
//    stylesheet.rules.forEach((e) => s += "${e.cssText} ");
//    print(s);
//    $style.text = s;

   // $style.text = stylesheet.rules.join(' '); // TODO does this what it is intended for?
  }

  void setSortColumn(String columnId, bool ascending) {
    setSortColumns([new SortColumn(columnId, ascending)]);
  }

  void setSortColumns(List<SortColumn> cols) {
    sortColumns = cols;

    List<BwuDatagridHeaderColumn> headerColumnEls = new List<BwuDatagridHeaderColumn>.from($headers.children);
    headerColumnEls.forEach((hc) {
        hc..classes.remove("bwu-datagrid-header-column-sorted")
        ..querySelectorAll(".bwu-datagrid-sort-indicator").forEach((dom.HtmlElement e) =>
            e.classes
            ..remove('bwu-datagrid-sort-indicator-asc')
            ..remove('bwu-datagrid-sort-indicator-desc'));
    });

    sortColumns.forEach((col) {
      if (col.sortAsc == null) {
        col.sortAsc = true;
      }
      var columnIndex = getColumnIndex(col.columnId);
      if (columnIndex != null) {
        headerColumnEls[columnIndex] // TODO verify
            ..classes.add("bwu-datagrid-header-column-sorted")
            ..querySelector(".bwu-datagrid-sort-indicator")
                .classes.add(col.sortAsc ? "bwu-datagrid-sort-indicator-asc" : "bwu-datagrid-sort-indicator-desc");
      }
    });
  }

  List<SortColumn> get getSortColumns => sortColumns;

  void selectedRangesChangedHandler(dom.CustomEvent e, [List<Range> ranges]) {
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

    eventBus.fire(core.Events.SELECTED_ROWS_CHANGED, new core.SelectedRowsChanged(this, getSelectedRows, e));
    //fire(ON_SELECTED_ROWS_CHANGED , detail:{'rows': getSelectedRows(), 'caused_by': e});
  }

  List<Column> get getColumns => columns;

  void updateColumnCaches() {
    // Pre-calculate cell boundaries.
    columnPosLeft = new List(columns != null ? columns.length : 0);
    columnPosRight = new List(columns != null ? columns.length : 0);
    var x = 0;
    if(columns != null) {
      for (var i = 0; i < columns.length; i++) {
        columnPosLeft[i] = x;
        columnPosRight[i] = x + columns[i].width;
        x += columns[i].width;
      }
    }
  }

  void set setColumns(List<Column> columnDefinitions) {
    columns = columnDefinitions;

    columnsById = {};
    for (var i = 0; i < columns.length; i++) {
      Column m = columns[i] = new Column()..extend(columnDefinitions[i])..extend(columns[i]);
      columnsById[m.id] = i;
      if (m.minWidth != null && (m.width == null || m.width < m.minWidth)) {
        m.width = m.minWidth;
      }
      if (m.maxWidth != null && m.width != null && m.width > m.maxWidth) {
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

      this.shadowRoot.append($style);
      handleScroll();
    }
  }

  GridOptions get getGridOptions => gridOptions;

  void set setGridOptions(GridOptions newGridOptions) {
    if (!getEditorLock.commitCurrentEdit()) {
      return;
    }

    makeActiveCellNormal();

    if (gridOptions.enableAddRow != newGridOptions.enableAddRow) {
      invalidateRow(getDataLength);
    }

    gridOptions.extend(newGridOptions); // TODO verify
    validateAndEnforceOptions();

    $viewport.style.overflowY = gridOptions.autoHeight != "" ? "hidden" : "auto";
    render();
  }

  void validateAndEnforceOptions() {
    if (gridOptions.autoHeight == null) {
      gridOptions.leaveSpaceForNewRows = false;
    }
  }

  void setDataView(DataView newData, bool scrollToTop) {
    dataView = newData;
    data = null;
    _setData(scrollToTop);
  }
  void setDataMap(List<Map> newData, bool scrollToTop) {
    data = newData;
    dataView = null;
  }

  void _setData(bool scrollToTop) {
    invalidateAllRows();
    updateRowCount();
    if (scrollToTop) {
      scrollTo(0);
    }
  }

  List<Map> get getDataMap => data;
  DataView get getDataView => dataView;

  int get getDataLength {
    if (data != null) {
      return data.length;
    } else if(dataView != null){
      return dataView.getLength;
    } else {
      return 0;
    }
  }

  int getDataLengthIncludingAddNew() {
    return getDataLength + (gridOptions.enableAddRow ? 1 : 0);
  }

  Map getDataItem(int i) {
    if(i >= data.length) {
      return null;
    }
    return data[i];
  }

  Item getDataViewItem(int i) => dataView.items[i];

  dom.HtmlElement get getTopPanel => $topPanel;

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

  dom.ShadowRoot get getContainerNode => $container;

  //////////////////////////////////////////////////////////////////////////////////////////////
  // Rendering / Scrolling

  int getRowTop(int row) {
    var x = gridOptions.rowHeight * row - pageOffset;
    //print('rowTop - row: ${row}: ${x}');
    return x;
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
      $viewport.scrollTop = (lastRenderedScrollTop = scrollTop = prevScrollTop = newScrollTop);

      eventBus.fire(core.Events.VIEWPORT_CHANGED, new core.ViewportChanged(this));
      //this.fire(BwuDatagrid.ON_VIEWPORT_CHANGED, detail: {});
      //trigger(self.onViewportChanged, {});
    }
  }

  Formatter getFormatter(int row, Column column) {
    var rowMetadata = dataView != null && dataView.getItemMetadata != null ? dataView.getItemMetadata(row) : null;

    // look up by id, then index
    var columnOverrides = rowMetadata != null ?
        (rowMetadata.columns[column.id] != null ? rowMetadata.columns[column.id] : rowMetadata.columns[getColumnIndex(column.id)]) : null;

    var result = (columnOverrides != null && columnOverrides.formatter != null) ? columnOverrides.formatter :
        (rowMetadata != null && rowMetadata.formatter != null ? rowMetadata.formatter :
        column.formatter); // TODO check
    if(result == null) {
      if(gridOptions.formatterFactory != null) {
        result = gridOptions.formatterFactory.getFormatter(column);
      }
    }
    if(result == null) {
        result = gridOptions.defaultFormatter;
    }
    return result;
  }

  Editor getEditor(int row, int cell) {
    var column = columns[cell];
    var rowMetadata = dataView != null && dataView.getItemMetadata != null ? dataView.getItemMetadata(row) : null;
    var columnMetadata = rowMetadata != null ? rowMetadata.columns : null;

    if (columnMetadata != null && columnMetadata[column.id] != null && columnMetadata[column.id].editor != null) {
      return columnMetadata[column.id].editor;
    }
    if (columnMetadata != null && columnMetadata[cell] != null && columnMetadata[cell].editor != null) {
      return columnMetadata[cell].editor;
    }

    return column.editor != null ? column.editor : (gridOptions.editorFactory != null ? gridOptions.editorFactory.getEditor(column): null);
  }

  dynamic getDataItemValueForColumn(/*Item/Map*/ item, Column columnDef) {
    if (gridOptions.dataItemColumnValueExtractor != null) {
      return gridOptions.dataItemColumnValueExtractor(item, columnDef);
    }
    return item[columnDef.field];
  }

  dom.HtmlElement appendRowHtml(/*dom.HtmlElement stringArray,*/ int row, Range range, int dataLength) {
    var d = getDataItem(row);
    var dataLoading = row < dataLength && d == null;
    var rowCss = 'bwu-datagrid-row ${dataLoading ? " loading" : ""} ${row == activeRow ? " active" : ""} ${row % 2 == 1 ? " odd" : " even"}';

    if (d == null) {
      "${rowCss} ${gridOptions.addNewRowCssClass}";
    }

    ItemMetadata metadata = dataView != null && dataView.getItemMetadata != null ? dataView.getItemMetadata(row) : null;

    if (metadata != null && metadata.cssClasses != null) {
      "${rowCss} ${metadata.cssClasses}";
    }

    dom.HtmlElement rowElement =

        new dom.DivElement()
          ..classes.add('ui-widget-content')
          ..classes.add(rowCss)
          ..style.top = '${getRowTop(row)}px';
    //stringArray.add(rowElement);

    String colspan;
    Column m;
    if(columns != null) {
      for (var i = 0, ii = columns.length; i < ii; i++) {
        m = columns[i];
        colspan = '1';
        if (metadata != null && metadata.columns != null) {
          var columnData = metadata.columns[m.id] != null ? metadata.columns[m.id] : metadata.columns[i];
          colspan = columnData != null && columnData.colspan != null ? columnData.colspan : '1';
          if (colspan == "*") {
            colspan = '${ii - i}';
          }
        }

        // Do not render cells outside of the viewport.
        if (columnPosRight[math.min(ii - 1, i + tools.parseInt(colspan) - 1)] > range.leftPx) {
          if (columnPosLeft[i] > range.rightPx) {
            // All columns to the right are outside the range.
            break;
          }

          appendCellHtml(rowElement, row, i, colspan, d);
        }

        int intColspan = tools.parseInt(colspan);
        if (intColspan > 1) {
          i += (intColspan - 1);
        }
      }
    }

    //stringArray.add("</div>");
    return rowElement;
  }

  void appendCellHtml(dom.HtmlElement rowElement, int row, int cell, String colspan, /*Item/Map*/ item) {
    assert(item is Item || item is Map || item == null);

    var m = columns[cell];
    var cellCss = "bwu-datagrid-cell l${cell} r${math.min(columns.length - 1, cell + tools.parseInt(colspan) - 1)} ${
      (m.cssClass != null ? m.cssClass : '')}";
    if (row == activeRow && cell == activeCell) {
      cellCss = "${cellCss} active";
    }

    // TODO:  merge them together in the setter
    for (var key in cellCssClasses.keys) {
      if (cellCssClasses[key][row] && cellCssClasses[key][row][m.id]) {
        cellCss += (" " + cellCssClasses[key][row][m.id]);
      }
    }

    dom.HtmlElement cellElement = new dom.DivElement()..classes.add(cellCss);
    rowElement.append(cellElement);

    // if there is a corresponding row (if not, this is the Add New row or this data hasn't been loaded yet)
    if (item != null) {
      var value = getDataItemValueForColumn(item, m);
      /*cellElement.append(new dom.Text(*/getFormatter(row, m)(cellElement, row, cell, value, m, item); //));
    }

    //stringArray.add("</div>");

    rowsCache[row].cellRenderQueue.add(cell);
    rowsCache[row].cellColSpans[cell] = colspan;
  }


  void cleanupRows(Range rangeToKeep) {
    for (var i = 0; i < rowsCache.length; i++) { // TODO was probably associative
      if ((i != activeRow) && (i < rangeToKeep.top || i > rangeToKeep.bottom)) {
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
    for (var i = 0; i < rowsCache.length; i++) { // TODO was probably an associative array
      removeRowFromCache(i);
    }
  }

  void removeRowFromCache(int row) {
    var cacheEntry = rowsCache[row];
    if (cacheEntry == null) {
      return;
    }

    if (rowNodeFromLastMouseWheelEvent == cacheEntry.rowNode) {
      cacheEntry.rowNode.style.display = 'none';
      zombieRowNodeFromLastMouseWheelEvent = rowNodeFromLastMouseWheelEvent;
    } else {
      //$canvas.children[0].remove(cacheEntry.rowNode);
      cacheEntry.rowNode.remove(); // TODO remove/add event handlers
    }

    rowsCache.remove(row);
    postProcessedRows.remove(row);
    renderedRows--;
    counter_rows_removed++;
  }

  void invalidateRows(List<int> rows) {
    var i, rl;
    if (rows == null || rows.length == 0) {
      return;
    }
    vScrollDir = 0;
    for (i = 0; i < rows.length; i++) {
      if (currentEditor != null && activeRow == rows[i]) {
        makeActiveCellNormal();
      }
      if (rowsCache[rows[i]] != null) {
        removeRowFromCache(rows[i]);
      }
    }
  }

  void invalidateRow(int row) {
    invalidateRows([row]);
  }

  void updateCell(int row, int cell) {
    var cellNode = getCellNode(row, cell);
    if (cellNode == null) {
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
    if (cacheEntry == null) {
      return;
    }

    ensureCellNodesInRowsCache(row);

    var d = getDataItem(row);

    for (var columnIdx in cacheEntry.cellNodesByColumnIdx.keys) {
      if (!cacheEntry.cellNodesByColumnIdx.containsKey(columnIdx)) {
        continue;
      }

      columnIdx = columnIdx | 0;
      var m = columns[columnIdx],
          node = cacheEntry.cellNodesByColumnIdx[columnIdx];

      if (row == activeRow && columnIdx == activeCell && currentEditor != null) {
        currentEditor.loadValue(d);
      } else if (d != null) {
        /*node.innerHtml =*/ getFormatter(row, m)(node, row, columnIdx, getDataItemValueForColumn(d, m), m, d);
      } else {
        node.innerHtml = "";
      }
    }

    invalidatePostProcessingResults(row);
  }

  int getViewportHeight() {
    var containerCs = $container.host.getComputedStyle();
    var headerScrollerCs = $headerScroller.getComputedStyle();

    var x =
     tools.parseInt(containerCs.height) -
        tools.parseInt(containerCs.paddingTop) -
        tools.parseInt(containerCs.paddingBottom) -
        tools.parseInt(headerScrollerCs.height) - getVBoxDelta($headerScroller) -
        (gridOptions.showTopPanel ? gridOptions.topPanelHeight + getVBoxDelta($topPanelScroller) : 0) -
        (gridOptions.showHeaderRow ? gridOptions.headerRowHeight + getVBoxDelta($headerRowScroller) : 0);
    //print('viewportHeight: ${x}');
    return x;
  }

  void resizeCanvas([int e]) {
    if (!initialized) { return; }
    if (gridOptions.autoHeight) {
      viewportH = gridOptions.rowHeight * getDataLengthIncludingAddNew();
    } else {
      viewportH = getViewportHeight();
    }

    numVisibleRows = (viewportH / gridOptions.rowHeight).ceil();
    viewportW = this.offsetWidth; //tools.parseInt(this.getComputedStyle().width);
    if (!gridOptions.autoHeight) {
      $viewport.style.height = "${viewportH}px";
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

    for (int i = 0; i < rowsCache.length; i++) {
      if (i >= l) {
        removeRowFromCache(i);
      }
    }

    if (activeCellNode != null && activeRow > l) {
      resetActiveCell();
    }

    var oldH = h;
    th = math.max(gridOptions.rowHeight * numberOfRows, viewportH - scrollbarDimensions.y);
    if (th < maxSupportedCssHeight) {
      // just one page
      h = ph = th.toDouble();
      n = 1;
      cj = 0.0;
    } else {
      // break into pages
      h = maxSupportedCssHeight.toDouble();
      ph = h / 100;
      n = (th / ph).floor();
      cj = (th - h) / (n - 1);
    }

    if (h != oldH) {
      $canvas.style.height = "${h}px";
      scrollTop = $viewport.scrollTop;
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

  Range getVisibleRange([int viewportTop, int viewportLeft]) {
    if (viewportTop == null) {
      viewportTop = scrollTop;
    }
    if (viewportLeft == null) {
      viewportLeft = scrollLeft;
    }

    return new Range(
      top: getRowFromPosition(viewportTop),
      bottom: getRowFromPosition(viewportTop + viewportH) + 1,
      leftPx: viewportLeft,
      rightPx: viewportLeft + viewportW
    );
  }

  Range getRenderedRange([int viewportTop, int viewportLeft]) {
    var range = getVisibleRange(viewportTop, viewportLeft);
    int buffer = (viewportH / gridOptions.rowHeight).round();
    int minBuffer = 3;

    if (vScrollDir == -1) {
      range.top -= buffer;
      range.bottom += minBuffer;
    } else if (vScrollDir == 1) {
      range.top -= minBuffer;
      range.bottom += buffer;
    } else {
      range.top -= minBuffer;
      range.bottom += minBuffer;
    }

    range.top = math.max(0, range.top);
    range.bottom = math.min(getDataLengthIncludingAddNew() - 1, range.bottom);

    range.leftPx -= viewportW;
    range.rightPx += viewportW;

    range.leftPx = math.max(0, range.leftPx);
    range.rightPx = math.min(canvasWidth, range.rightPx);

    return range;
  }

  void ensureCellNodesInRowsCache(int row) {
    var cacheEntry = rowsCache[row];
    if (cacheEntry != null) {
      if (cacheEntry.cellRenderQueue.length > 0) {
        var lastChild = cacheEntry.rowNode.lastChild;
        while (cacheEntry.cellRenderQueue.length > 0) {
          var columnIdx = cacheEntry.cellRenderQueue.removeLast(); // TODO check if removefirst is the right replacement for pop()
          cacheEntry.cellNodesByColumnIdx[columnIdx] = lastChild;
          lastChild = lastChild.previousNode;
        }
      }
    }
  }

  void cleanUpCells(Range range, int row) {
    var totalCellsRemoved = 0;
    var cacheEntry = rowsCache[row];

    // Remove cells outside the range.
    var cellsToRemove = [];
    for (var i in cacheEntry.cellNodesByColumnIdx.keys) {
      // I really hate it when people mess with Array.prototype.
//      if (!cacheEntry.cellNodesByColumnIdx.containsKey(i)) { // TODO check
//        continue;
//      }

      // This is a string, so it needs to be cast back to a number.
      //i = i | 0;

      var colspan = cacheEntry.cellColSpans[i];
      int intColspan = tools.parseInt(colspan);
      if (columnPosLeft[i] > range.rightPx ||
        columnPosRight[math.min(columns.length - 1, i + intColspan - 1)] < range.leftPx) {
        if (!(row == activeRow && i == activeCell)) {
          cellsToRemove.add(i);
        }
      }
    }

    int cellToRemove;
    while (cellsToRemove.length > 0) {
      cellToRemove = cellsToRemove.removeLast();
      cacheEntry.cellNodesByColumnIdx[cellToRemove].remove();
      cacheEntry.cellColSpans.remove(cellToRemove);
      cacheEntry.cellNodesByColumnIdx.remove(cellToRemove);
      if (postProcessedRows.contains(row)) {
        postProcessedRows[row].remove(cellToRemove);
      }
      totalCellsRemoved++;
    }
  }

  void cleanUpAndRenderCells(Range range) {
    RowCache cacheEntry;
    //var stringArray = [];
    dom.HtmlElement rowElement = new dom.DivElement();
    var processedRows = [];
    int cellsAdded;
    var totalCellsAdded = 0;
    String colspan;

    for (var row = range.top; row <= range.bottom; row++) {
      cacheEntry = rowsCache[row];
      if (cacheEntry == null) {
        continue;
      }

      // cellRenderQueue populated in renderRows() needs to be cleared first
      ensureCellNodesInRowsCache(row);

      cleanUpCells(range, row);

      // Render missing cells.
      cellsAdded = 0;

      ItemMetadata itemMetadata;
      if(dataView != null) {
        itemMetadata = dataView.getItemMetadata(row);
      }
      List<ColumnMetadata>metadata = itemMetadata != null ? itemMetadata.columns : null;

      var d = getDataItem(row);

      // TODO:  shorten this loop (index? heuristics? binary search?)
      for (var i = 0, ii = columns.length; i < ii; i++) {
        // Cells to the right are outside the range.
        if (columnPosLeft[i] > range.rightPx) {
          break;
        }

        int intColspan;
        // Already rendered.
        if ((colspan = cacheEntry.cellColSpans[i]) != null) {
          intColspan = tools.parseInt(colspan);
          i += (intColspan > 1 ? intColspan - 1 : 0);
          continue;
        }

        colspan = '1';
        if (metadata != null) {
          var columnData = metadata[columns[i].id] != null ? metadata[columns[i].id] : metadata[i];
          colspan = (columnData != null && columnData.colspan != null) ? columnData.colspan : '1';
          if (colspan == "*") {
            colspan = '${ii - i}';
          }
        }

        intColspan = tools.parseInt(colspan);
        if (columnPosRight[math.min(ii - 1, i + intColspan - 1)] > range.leftPx) {
          appendCellHtml(rowElement, row, i, colspan, d);
          cellsAdded++;
        }

        i += (intColspan > 1 ? intColspan - 1 : 0);
      }

      if (cellsAdded > 0) {
        totalCellsAdded += cellsAdded;
        processedRows.add(row);
      }
    }

    if (rowElement.children.length == 0) {
      return;
    }

    var x = new dom.DivElement();
    rowElement.children.forEach((e) {
      x.append(e.clone(true));
    });

    var processedRow;
    var node;
    while (processedRows.length > 0 && (processedRow = processedRows.removeLast()) != null) {
      cacheEntry = rowsCache[processedRow];
      var columnIdx;
      while (cacheEntry.cellRenderQueue.length > 0) {
        columnIdx = cacheEntry.cellRenderQueue.removeLast();
        node = x.lastChild;
        cacheEntry.rowNode.append(node);
        cacheEntry.cellNodesByColumnIdx[columnIdx] = node;
      }
    }
  }

  void renderRows(Range range) {
    var parentNode = $canvas;

    //stringArray = [],
    //dom.HtmlElement rowElement;
    List<dom.HtmlElement> rowElements = [];

    List<int> rows = [];
    bool needToReselectCell = false;
    int dataLength = getDataLength;

    var x = new dom.DivElement();

    for (var i = range.top; i <= range.bottom; i++) {
      if (rowsCache[i] != null) {
        continue;
      }
      renderedRows++;
      rows.add(i);

      // Create an entry right away so that appendRowHtml() can
      // start populatating it.
      rowsCache[i] = new RowCache();
//        rowNode: null,
//
//        // ColSpans of rendered cells (by column idx).
//        // Can also be used for checking whether a cell has been rendered.
//        cellColSpans: [],
//
//        // Cell nodes (by column idx).  Lazy-populated by ensureCellNodesInRowsCache().
//        cellNodesByColumnIdx: [],
//
//        // Column indices of cell nodes that have been rendered, but not yet indexed in
//        // cellNodesByColumnIdx.  These are in the same order as cell nodes added at the
//        // end of the row.
//        cellRenderQueue: []
//      );

      x.append(appendRowHtml(/*stringArray,*/ i, range, dataLength));
      if (activeCellNode != null && activeRow == i) {
        needToReselectCell = true;
      }
      counter_rows_rendered++;
    }

    if (rows.length == 0) { return; }

    //x.append(rowElement); //stringArray.join(""), validator: nodeValidator);

    for (var i = 0; i < rows.length; i++) {
      rowsCache[rows[i]].rowNode = parentNode.append(x.firstChild);
      rowsCache[rows[i]].rowNode.querySelectorAll(".bwu-datagrid-cell").forEach((e) {
        (e as dom.HtmlElement)
          ..onMouseEnter.listen(handleMouseEnter)
          ..onMouseLeave.listen(handleMouseLeave);
      });
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

    postProcessFromRow = visible.top;
    postProcessToRow = math.min(getDataLengthIncludingAddNew() - 1, visible.bottom);
    startPostProcessing();

    lastRenderedScrollTop = scrollTop;
    lastRenderedScrollLeft = scrollLeft;
    h_render = null;
  }

  void handleHeaderRowScroll([dom.Event e]) {
    var scrollLeft = $headerRowScroller.scrollLeft;
    if (scrollLeft != $viewport.scrollLeft) {
      $viewport.scrollLeft = scrollLeft;
    }
  }

  void handleScroll([dom.Event e]) {
    scrollTop = $viewport.scrollTop;
    scrollLeft = $viewport.scrollLeft;
    int vScrollDist = (scrollTop - prevScrollTop).abs();
    int hScrollDist = (scrollLeft - prevScrollLeft).abs();

    if (hScrollDist != 0) {
      prevScrollLeft = scrollLeft;
      $headerScroller.scrollLeft = scrollLeft;
      $topPanelScroller.scrollLeft = scrollLeft;
      $headerRowScroller.scrollLeft = scrollLeft;
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

    if (hScrollDist != null || vScrollDist != null) {
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

        eventBus.fire(core.Events.VIEWPORT_CHANGED, new core.ViewportChanged(this));
        //trigger(self.onViewportChanged, {});
      }
    }

    eventBus.fire(core.Events.SCROLL, new core.Scroll(this, scrollLeft: scrollLeft, scrollTop: scrollTop));
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
        postProcessedRows[row] = []; // TODO {}
      }

      ensureCellNodesInRowsCache(row);
      for (var columnIdx in cacheEntry.cellNodesByColumnIdx) {
        if (!cacheEntry.cellNodesByColumnIdx.containsKey(columnIdx)) {
          continue;
        }

        columnIdx = columnIdx | 0; // TODO

        var m = columns[columnIdx];
        if (m.asyncPostRender && postProcessedRows[row][columnIdx] == null) {
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

  void updateCellCssStylesOnRenderedRows(String addedHash, List<int> removedHash) {
    dom.HtmlElement node;
    int columnId;
    bool addedRowHash;
    bool removedRowHash;
    for (var row = 0; row < rowsCache.length; row++) { // TODO check was probably associative array
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

    fire('cell-css-style-changed', detail: { "key": key, "hash": hash }); // TODO eventbus.fire
    //trigger(self.onCellCssStylesChanged, { "key": key, "hash": hash });
  }

  void removeCellCssStyles(String key) {
    if (cellCssClasses[key] == null) {
      return;
    }

    updateCellCssStylesOnRenderedRows(null, cellCssClasses[key]);
    cellCssClasses.remove(key);

    eventBus.fire(core.Events.CELL_CSS_STYLES_CHANGED, new core.CellCssStylesChanged(this, key));
    //trigger(self.onCellCssStylesChanged, { "key": key, "hash": null });
  }

  void setCellCssStyles(String key, List<Map<String,String>> hash) {
    var prevHash = cellCssClasses[key];

    cellCssClasses[key] = hash;
    updateCellCssStylesOnRenderedRows(hash, prevHash);

    eventBus.fire(core.Events.CELL_CSS_STYLES_CHANGED, new core.CellCssStylesChanged(this, key, hash: hash));
    //trigger(self.onCellCssStylesChanged, { "key": key, "hash": hash });
  }

  Map<int,String> getCellCssStyles(int key) {
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
    var rowNode = tools.closest((e.target as dom.HtmlElement), '.bwu-datagrid-row');
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

  bool handleDrag(dom.MouseEvent e, [int dd]) {
    Cell cell = getCellFromEvent(e);
    if (cell == null || !cellExists(cell.row, cell.cell)) {
      return false;
    }

    var data = eventBus.fire(core.Events.DRAG_INIT, new core.DragInit(this, dd: dd, causedBy: e));
    //var retval = trigger(self.onDragInit, dd, e);
    if (e.currentTarget == null && e.eventPhase == 0) { // .isImmediatePropagationStopped()) {
      return data.retVal;
    }

    // if nobody claims to be handling drag'n'drop by stopping immediate propagation,
    // cancel out of it
    return false;
  }

  bool handleDragStart(dom.MouseEvent e, Map dd) {
    var cell = getCellFromEvent(e);
    if (cell != null|| !cellExists(cell.row, cell.cell)) {
      return false;
    }

    dd['origin-event'] = e;
    var retval = fire('drag-start', detail: dd);  // TODO eventbus.fire
    //var retval = trigger(self.onDragStart, dd, e);
    if(e.defaultPrevented) {
    //if (e.isImmediatePropagationStopped()) {
      //return retval;
      return true;
    }

    return false;
  }

  void handleDragOver(dom.MouseEvent e, [Map dd]) {
    dd['origin-event'] = e;
     fire('drag', detail: dd) as dom.HtmlElement; // TODO eventbus fire
    //return trigger(self.onDrag, dd, e);
  }

  void handleDragEnd(dom.MouseEvent e, [Map dd]) {
    dd['origin-event'] = e;
    fire('drag-end', detail: dd);  // TODO eventbus fire
    //trigger(self.onDragEnd, dd, e);
  }

  void handleKeyDown(dom.KeyboardEvent e) {
    eventBus.fire(core.Events.KEY_DOWN, new  core.KeyDown(this, new Cell(activeRow, activeCell), causedBy: e));
    //trigger(self.onKeyDown, {'row': activeRow, 'cell': activeCell}, e);
    //var handled = e.isImmediatePropagationStopped();
    var handled = e.defaultPrevented;

    if (!handled) {
      if (!e.shiftKey && !e.altKey && !e.ctrlKey) {
        if (e.which == 27) {
          if (!getEditorLock.isActive) {
            return; // no editing mode to cancel, allow bubbling and default processing (exit without cancelling the event)
          }
          cancelEditAndSetFocus();
        } else if (e.which == dom.KeyCode.NUM_SOUTH_EAST) {
          navigatePageDown();
          handled = true;
        } else if (e.which == dom.KeyCode.NUM_NORTH_EAST) {
          navigatePageUp();
          handled = true;
        } else if (e.which == dom.KeyCode.NUM_WEST) {
          handled = navigateLeft();
        } else if (e.which == dom.KeyCode.NUM_EAST) {
          handled = navigateRight();
        } else if (e.which == dom.KeyCode.NUM_NORTH) {
          handled = navigateUp();
        } else if (e.which == dom.KeyCode.NUM_SOUTH) {
          handled = navigateDown();
        } else if (e.which == dom.KeyCode.TAB) {
          handled = navigateNext();
        } else if (e.which == dom.KeyCode.ENTER) {
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
      } else if (e.which == dom.KeyCode.TAB && e.shiftKey && !e.ctrlKey && !e.altKey) {
        handled = navigatePrev();
      }
    }

    if (handled) {
      // the event has been handled so don't let parent element (bubbling/propagation) or browser (default) handle it
      e.stopPropagation();
      e.preventDefault();
//      try {
//        e.originalEvent.keyCode = 0; // prevent default behaviour for special keys in IE browsers (F3, F5, etc.)
//      }
//      // ignore exceptions - setting the original event's keycode throws access denied exception for "Ctrl"
//      // (hitting control key only, nothing else), "Shift" (maybe others)
//      catch (error) {
//      }
    }
  }

  void handleClick(dom.MouseEvent e) {
    if (currentEditor == null) {
      // if this click resulted in some cell child node getting focus,
      // don't steal it back - keyboard events will still bubble up
      // IE9+ seems to default DIVs to tabIndex=0 instead of -1, so check for cell clicks directly.
      if (e.target != dom.document.activeElement || (e.target as dom.HtmlElement).classes.contains("bwu-datagrid-cell")) {
        setFocus();
      }
    }

    var cell = getCellFromEvent(e);
    if (cell == null || (currentEditor != null && activeRow == cell.row && activeCell == cell.cell)) {
      return;
    }

    eventBus.fire(core.Events.CLICK, new core.Click(this, cell, causedBy: e));
    //trigger(self.onClick, {'row': cell['row'], 'cell': cell['cell']}, e);
    //if (e.isImmediatePropagationStopped()) {
    if(e.defaultPrevented) {
      return;
    }

    if ((activeCell != cell.cell || activeRow != cell.row) && canCellBeActive(cell.row, cell.cell)) {
      if (!getEditorLock.isActive || getEditorLock.commitCurrentEdit()) {
        scrollRowIntoView(cell.row, false);
        setActiveCellInternal(getCellNode(cell.row, cell.cell));
      }
    }
  }

  void handleContextMenu(dom.MouseEvent e) {
    var $cell = tools.closest((e.target as dom.HtmlElement), '.bwu-datagrid-cell', context: $canvas);
    if ($cell == null) {
      return;
    }

    // are we editing this cell?
    if (activeCellNode == $cell && currentEditor != null) {
      return;
    }

    fire('context-menu', detail: {'origin-event': e}); // TODO eventbus fire
    //trigger(self.onContextMenu, {}, e);
  }

  void handleDblClick(dom.MouseEvent e) {
    Cell cell = getCellFromEvent(e);
    if (cell == null|| (currentEditor != null && activeRow == cell.row && activeCell == cell.cell)) {
      return;
    }

    eventBus.fire(core.Events.DOUBLE_CLICK, new core.DoubleClick(this, cell, causedBy: e));
    //trigger(self.onDblClick, {'row': cell['row'], 'cell': cell['cell']}, e);
    //if (e.isImmediatePropagationStopped()) {
    if(e.defaultPrevented) {
      return;
    }

    if (gridOptions.editable) {
      gotoCell(cell.row, cell.cell, true);
    }
  }

  void handleHeaderMouseEnter(dom.MouseEvent e) {
    eventBus.fire(core.Events.HEADER_MOUSE_ENTER, new core.HeaderMouseEnter(this, (e.target as BwuDatagridHeaderColumn).column, causedBy: e));
    //fire(core.Events.HEADER_MOUSE_ENTER, detail: new core.HeaderMouseEnter(this, (e.target as BwuDatagridHeaderColumn).column, causedBy: e));
    //trigger(self.onHeaderMouseEnter, {
//      "column": dataset["column"],
//      'origin-event': e
//    });
  }

  void handleHeaderMouseLeave(dom.MouseEvent e) {
    eventBus.fire(core.Events.HEADER_MOUSE_LEAVE, new core.HeaderMouseLeave(this, dataset['column'], causedBy: e));
    //trigger(self.onHeaderMouseLeave, {
//      "column": dataset["column"],
//      'origin-event': e
//    });
  }

  void handleHeaderContextMenu(dom.MouseEvent e) {
    var $header = tools.closest((e.target as dom.HtmlElement), ".bwu-datagread-header-column" /*, ".bwu-datagrid-header-columns"*/) as BwuDatagridHeaderColumn;
    var column = $header != null ? $header.column : null;
    eventBus.fire(core.Events.HEADER_CONTEX_MENU, new core.HeaderContextMenu(this, column, causedBy: e));
    //trigger(self.onHeaderContextMenu, {column: column}, e);
  }

  void handleHeaderClick(dom.MouseEvent e) {
    var $header = tools.closest((e.target as dom.HtmlElement),'.bwu-datagrid-header-column' /*, ".bwu-datagrid-header-columns"*/) as BwuDatagridHeaderColumn;
    var column = $header != null ? $header.column : null;
    if (column != null) {
      eventBus.fire(core.Events.HEADER_CLICK, new core.HeaderClick(this, column, causedBy: e));
      // trigger(self.onHeaderClick, {column: column}, e);
    }
  }

  void handleMouseEnter(dom.MouseEvent e) {
    eventBus.fire(core.Events.MOUSE_ENTER, new core.MouseEnter(this, causedBy: e));
    //trigger(self.onMouseEnter, {}, e);
  }

  void handleMouseLeave(dom.MouseEvent e) {
    eventBus.fire(core.Events.MOUSE_LEAVE, new core.MouseLeave(this, causedBy: e));
    //trigger(self.onMouseLeave, {}, e);
  }

  bool cellExists(int row, int cell) {
    return !(row < 0 || row >= getDataLength || cell < 0 || cell >= columns.length);
  }

  Cell getCellFromPoint(int x, int y) {
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

    return new Cell(row, cell - 1);
  }

  int getCellFromNode(dom.HtmlElement cellNode) {
    // read column number from .l<columnNumber> CSS class
    var matches = new RegExp(r'(?:\l)(\d+)').firstMatch(cellNode.className);
    //var cls = new RegExp(r'l\d+').allMatches(cellNode.className);
    if (matches == null) {
      throw "getCellFromNode: cannot get cell - ${cellNode.className}";
    }
    return tools.parseInt(matches.group(1));
  }

  int getRowFromNode(dom.HtmlElement rowNode) {
    for (final row in rowsCache.keys) { // TODO in rowsCache) {
      if (rowsCache[row] != null && rowsCache[row].rowNode == rowNode) {
        return row;
      }
    }

    return null;
  }

  Cell getCellFromEvent(dom.Event e) {
    var $cell = tools.closest((e.target as dom.HtmlElement), '.bwu-datagrid-cell', context: $canvas);
    if ($cell == null) {
      return null;
    }

    var row = getRowFromNode($cell.parentNode);
    var cell = getCellFromNode($cell);

    if (row == null || cell == null) {
      return null;
    } else {
      return new Cell(row, cell);
    }
  }

  NodeBox getCellNodeBox(int row, int cell) {
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
    return new NodeBox(top: y1, left: x1, bottom: y2, right: x2);
  }

  //////////////////////////////////////////////////////////////////////////////////////////////
  // Cell switching

  void resetActiveCell() {
    setActiveCellInternal(null, false);
  }

  void setFocus() {
    if (tabbingDirection == -1) {
      $focusSink.focus();
    } else {
      $focusSink2.focus();
    }
  }

  void scrollCellIntoView(int row, int cell, bool doPaging) {
    scrollRowIntoView(row, doPaging);

    var colspan = getColspan(row, cell);
    int intColspan = tools.parseInt(colspan);
    var left = columnPosLeft[cell],
      right = columnPosRight[cell + (intColspan > 1 ? intColspan - 1 : 0)],
      scrollRight = scrollLeft + viewportW;

    if (left < scrollLeft) {
      $viewport.scrollLeft = left;
      handleScroll();
      render();
    } else if (right > scrollRight) {
      $viewport.scrollLeft = math.min(left, right - $viewport.clientWidth);
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
      eventBus.fire(core.Events.ACTIVE_CELL_CHANGED, new core.ActiveCellChanged(this, getActiveCell()));
      //trigger(self.onActiveCellChanged, getActiveCell());
    }
  }

  void clearTextSelection() {
//    if (dom.document.selection && dom.document.selection.empty) {
//      try {
//        //IE fails here if selected element is not in dom
//        dom.document.selection.empty();
//      } catch (e) { }
//    } else
//      if (dom.window.getSelection) {
      var sel = dom.window.getSelection();
      if (sel && sel.removeAllRanges) {
        sel.removeAllRanges();
      }
//    }
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
    eventBus.fire(core.Events.BEFORE_CELL_EDITOR_DESTROY, new core.BeforeCellEditorDestroy(this, currentEditor));
    //trigger(self.onBeforeCellEditorDestroy, {'editor': currentEditor});
    currentEditor.destroy();
    currentEditor = null;

    if (activeCellNode != null) {
      var d = getDataItem(activeRow);
      activeCellNode.classes..remove("editable")..remove("invalid");
      if (d != null) {
        var column = columns[activeCell];
        Formatter formatter = getFormatter(activeRow, column);
        /*activeCellNode.innerHtml =*/ formatter(activeCellNode, activeRow, activeCell, getDataItemValueForColumn(d, column), column, d);
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

    /*if(*/eventBus.fire(core.Events.BEFORE_EDIT_CELL, new core.BeforeEditCell(this, cell: new Cell(activeRow, activeCell), item: item, column: columnDef));/*) { */
//    if (trigger(self.onBeforeEditCell, {'row': activeRow, 'cell': activeCell, 'item': item, 'column': columnDef}) == false) { // TODO == false
      setFocus();
//      return;
    //}

    getEditorLock.activate(editController);
    activeCellNode.classes.add("editable");

    // don't clear the cell if a custom editor is passed through
    if (editor == null) {
      activeCellNode.innerHtml = "";
    }

    if(editor != null) {
      currentEditor = editor;
    } else {
      currentEditor = getEditor(activeRow, activeCell);
    }
    currentEditor = currentEditor.newInstance(new EditorArgs(
      grid: this,
      gridPosition: absBox($container.host),
      position: (absBox(activeCellNode)),
      container: activeCellNode,
      column: columnDef,
      item :  item != null ? item : new Item(),
      commitChanges : commitEditAndSetFocus,
      cancelChanges : cancelEditAndSetFocus));

    //currentEditor = new (editor || getEditor(activeRow, activeCell))({
//      'grid': this,
//      'gridPosition': absBox($container.children[0]),
//      'position': absBox(activeCellNode),
//      'container': activeCellNode,
//      'column': columnDef,
//      'item': item || {},
//      'commitChanges': commitEditAndSetFocus,
//      'cancelChanges': cancelEditAndSetFocus
//    });

    if (item != null) {
      currentEditor.loadValue(item);
    }

    serializedEditorValue = currentEditor.serializeValue();

    if (currentEditor.position != null) {
      handleActiveCellPositionChange(null);
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

  NodeBox absBox(dom.HtmlElement elem) {
    var bcr = elem.getBoundingClientRect();
    var box = new NodeBox(
        top: (bcr.top as double).toInt(),
        left: (bcr.left as double).toInt(),
        bottom: (bcr.bottom as double).toInt(),
        right: (bcr.right as double).toInt(),
        width: (bcr.width as double).toInt(),
        height: (bcr.height as double).toInt(),
        visible: true);
//    var cs = elem.getComputedStyle();
//    var box = new NodeBox(
//      top: elem.offsetTop,
//      left: elem.offsetLeft,
//      bottom: 0,
//      right: 0,
//      width: tools.outerWidth(elem), //tools.parseInt(cs.width) + tools.parseInt(cs.paddingLeft) + tools.parseInt(cs.paddingRight) + tools.parseInt(cs.borderLeft) + tools.parseInt(cs.borderRight), //elem.outerWidth(),
//      height: tools.outerHeight(elem), //parseInt(cs.height) + tools.parseInt(cs.paddingTop) + tools.parseInt(cs.paddingBottom) + tools.parseInt(cs.borderTop) + tools.parseInt(cs.borderBottom), //elem.outerHeight(), // TODO check all other outerWidth/outherHeight if they include border
//      visible: true);
//    box.bottom = box.top + box.height;
//    box.right = box.left + box.width;

    // walk up the tree
//    var offsetParent = elem.offsetParent;
//    while ((elem = tools.getParentElement(elem.parentNode)) != this) {
//      if (box.visible && elem.scrollHeight != elem.offsetHeight && elem.style.overflowY != "visible") {
//        box.visible = box.bottom > elem.scrollTop && box.top < elem.scrollTop + elem.clientHeight;
//      }
//
//      if (box.visible && elem.scrollWidth != elem.offsetWidth && elem.style.overflowX != "visible") {
//        box.visible = box.right > elem.scrollLeft && box.left < elem.scrollLeft + elem.clientWidth;
//      }
//
//      box.left -= elem.scrollLeft;
//      box.top -= elem.scrollTop;
//
//      if (elem == offsetParent) {
//        box.left += elem.offsetLeft;
//        box.top += elem.offsetTop;
//        offsetParent = elem.offsetParent;
//      }
//
//      box.bottom = box.top + box.height;
//      box.right = box.left + box.width;
//    }

    return box;
  }

  NodeBox getActiveCellPosition() {
    return absBox(activeCellNode);
  }

  NodeBox getGridPosition() {
    return absBox($container.host);
  }

  void handleActiveCellPositionChange(dom.Event e) {
    if (activeCellNode == null) {
      return;
    }

    eventBus.fire(core.Events.ACTIVE_CELL_POSITION_CHANGED, new core.ActiveCellPositionChanged(this));
    //trigger(self.onActiveCellPositionChanged, {});

    if (currentEditor != null) {
      var cellBox = getActiveCellPosition();
      //if (currentEditor.show && currentEditor.hide) {
        if (!cellBox.visible) {
          currentEditor.hide(); // TODO show/hide
        } else {
          currentEditor.show();
        }
      //}

      currentEditor.position(cellBox);
    }
  }

  Editor getCellEditor() {
    return currentEditor;
  }

  Cell getActiveCell() {
    if (activeCellNode == null) {
      return null;
    } else {
      return new Cell(activeRow, activeCell);
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

  String getColspan(int row, int cell) {
    ItemMetadata metadata = dataView != null && dataView.getItemMetadata != null ? dataView.getItemMetadata(row) : null;
    if (metadata == null || metadata.columns == null) {
      return '1';
    }

    ColumnMetadata columnData = metadata.columns[columns[cell].id] != null ? metadata.columns[columns[cell].id] : metadata.columns[cell];
    String colspan = columnData != null ? columnData.colspan : null;
    if (colspan == "*") {
      colspan = '${columns.length - cell}';
    } else {
      colspan = colspan != null ? colspan : '1';
    }

    return colspan;
  }

  int findFirstFocusableCell(int row) {
    var cell = 0;
    while (cell < columns.length) {
      if (canCellBeActive(row, cell)) {
        return cell;
      }
      cell += getColspan(row, cell);
    }
    return null;
  }

  int findLastFocusableCell(int row) {
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

  CellPos gotoRight(int row, int cell, int posX) {
    if (cell >= columns.length) {
      return null;
    }

    do {
      cell += tools.parseInt(getColspan(row, cell));
    }
    while (cell < columns.length && !canCellBeActive(row, cell));

    if (cell < columns.length) {
      return new CellPos(row: row, cell: cell, posX: cell);
    }
    return null;
  }

  CellPos gotoLeft(int row, int cell, int posX) {
    if (cell <= 0) {
      return null;
    }

    var firstFocusableCell = findFirstFocusableCell(row);
    if (firstFocusableCell == null || firstFocusableCell >= cell) {
      return null;
    }

    var prev = new CellPos(row: row, cell: firstFocusableCell, posX: firstFocusableCell);
    var pos;
    while (true) {
      pos = gotoRight(prev.row, prev.cell, prev.cell); //prev.posX']);
      if (pos == null) {
        return null;
      }
      if (pos.cell >= cell) {
        return prev;
      }
      prev = pos;
    }
  }

  CellPos gotoDown(int row, int cell, int posX) {
    var prevCell;
    var dataLengthIncludingAddNew = getDataLengthIncludingAddNew();
    while (true) {
      if (++row >= dataLengthIncludingAddNew) {
        return null;
      }

      prevCell = cell = 0;
      while (cell <= posX) {
        prevCell = cell;
        cell += tools.parseInt(getColspan(row, cell));
      }

      if (canCellBeActive(row, prevCell)) {
        return new CellPos(row: row,cell: prevCell, posX: posX);
      }
    }
  }

  CellPos gotoUp(int row, int cell, int posX) {
    var prevCell;
    while (true) {
      if (--row < 0) {
        return null;
      }

      prevCell = cell = 0;
      while (cell <= posX) {
        prevCell = cell;
        cell += tools.parseInt(getColspan(row, cell));
      }

      if (canCellBeActive(row, prevCell)) {
        return new CellPos(
          row: row,
          cell: prevCell,
          posX: posX
        );
      }
    }
  }

  CellPos gotoNext(int row, int cell, int posX) {
    if (row == null && cell == null) {
      row = cell = posX = 0;
      if (canCellBeActive(row, cell)) {
        return new CellPos(
          row: row,
          cell: cell,
          posX: cell
        );
      }
    }

    var pos = gotoRight(row, cell, posX);
    if (pos != null) {
      return pos;
    }

    var firstFocusableCell = null;
    var dataLengthIncludingAddNew = getDataLengthIncludingAddNew();
    while (++row < dataLengthIncludingAddNew) {
      firstFocusableCell = findFirstFocusableCell(row);
      if (firstFocusableCell != null) {
        return new CellPos(
          row: row,
          cell: firstFocusableCell,
          posX: firstFocusableCell
        );
      }
    }
    return null;
  }

  CellPos gotoPrev(int row, int cell, int posX) {
    if (row == null && cell == null) {
      row = getDataLengthIncludingAddNew() - 1;
      cell = posX = columns.length - 1;
      if (canCellBeActive(row, cell)) {
        return new CellPos(
          row: row,
          cell: cell,
          posX: cell
        );
      }
    }

    CellPos pos;
    var lastSelectableCell;
    while (pos == null) {
      pos = gotoLeft(row, cell, posX);
      if (pos != null) {
        break;
      }
      if (--row < 0) {
        return null;
      }

      cell = 0;
      lastSelectableCell = findLastFocusableCell(row);
      if (lastSelectableCell != null) {
        pos = new CellPos(
          row: row,
          cell: lastSelectableCell,
          posX: lastSelectableCell
        );
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
    if (pos != null) {
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
      var c = rowsCache[row].cellNodesByColumnIdx[cell];
      return c;
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

  bool canCellBeActive(int row, int cell) {
    if (!gridOptions.enableCellNavigation || row >= getDataLengthIncludingAddNew() ||
        row < 0 || cell >= columns.length || cell < 0) {
      return false;
    }

    ItemMetadata rowMetadata = dataView != null && dataView.getItemMetadata != null ? dataView.getItemMetadata(row) : null;
    if (rowMetadata != null && rowMetadata.focusable == true) {
      return rowMetadata.focusable;
    }

    ColumnMetadata columnMetadata = rowMetadata != null ? rowMetadata.columns : null;
    if (columnMetadata != null && columnMetadata[columns[cell].id] != null && columnMetadata[columns[cell].id].focusable is bool) {
      return columnMetadata[columns[cell].id].focusable;
    }
    if (columnMetadata != null && columnMetadata[cell] != null && columnMetadata[cell].focusable is bool) {
      return columnMetadata[cell].focusable;
    }

    return columns[cell].focusable;
  }

  bool canCellBeSelected(row, cell) {
    if (row >= getDataLength || row < 0 || cell >= columns.length || cell < 0) {
      return false;
    }

    ItemMetadata rowMetadata = dataView!= null && dataView.getItemMetadata != null ? dataView.getItemMetadata(row) : null;
    if (rowMetadata && rowMetadata.selectable is bool) {
      return rowMetadata.selectable;
    }

    ColumnMetadata columnMetadata;
    if(rowMetadata != null && rowMetadata.columns != null) {
      columnMetadata =rowMetadata.columns[columns[cell].id];
    } else {
      columnMetadata = rowMetadata.columns[cell];
    }
    if (columnMetadata != null && columnMetadata.selectable is bool) {
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

        if (validationResults.isValid) {
          if (activeRow < getDataLength) {
            EditCommand editCommand;
            editCommand = new EditCommand(
              row: activeRow,
              cell: activeCell,
              editor: currentEditor,
              serializedValue: currentEditor.serializeValue(),
              prevSerializedValue: serializedEditorValue,
              execute: () {
                EditCommand cmd = editCommand;
                cmd.editor.applyValue(item, cmd.serializedValue);
                updateRow(cmd.row);
                eventBus.fire(core.Events.CELL_CHANGED, new core.CellChanged(this, new Cell(activeRow, activeCell), item));
                //trigger(self.onCellChange, {
//                  'row': activeRow,
//                  'cell': activeCell,
//                  'item': item
//                });
              },
              undo: () {
                EditCommand cmd = editCommand;
                cmd.editor.applyValue(item, cmd.prevSerializedValue);
                updateRow(cmd.row);
                eventBus.fire(core.Events.CELL_CHANGED, new core.CellChanged(this, new Cell(activeRow, activeCell), item));
                //trigger(self.onCellChange, {
//                  'row': activeRow,
//                  'cell': activeCell,
//                  'item': item
//                });
              });

            if (gridOptions.editCommandHandler != null) {
              makeActiveCellNormal();
              gridOptions.editCommandHandler(item, column, editCommand);
            } else {
              editCommand.execute();
              makeActiveCellNormal();
            }

          } else {
            var newItem = new Item();
            currentEditor.applyValue(newItem, currentEditor.serializeValue());
            makeActiveCellNormal();
            eventBus.fire(core.Events.ADD_NEW_ROW, new core.AddNewRow(this, item, column));
            //trigger(self.onAddNewRow, {item: newItem, column: column});
          }

          // check whether the lock has been re-acquired by event handlers
          return !getEditorLock.isActive;
        } else {
          // Re-add the CSS class to trigger transitions, if any.
          activeCellNode.classes.remove("invalid");
          activeCellNode.style.width;  // force layout // TODO ob das in Dart so funktioniert
          activeCellNode.classes.add("invalid");

          eventBus.fire(core.Events.VALIDATION_ERROR, new core.ValidationError(this,
              editor: currentEditor,
              cellNode: activeCellNode,
              validationResults: validationResults,
              cell: new Cell(activeRow, activeCell),
              column: column));
          //trigger(self.onValidationError, {
//            'editor': currentEditor,
//            'cellNode': activeCellNode,
//            'validationResults': validationResults,
//            'row': activeRow,
//            'cell': activeCell,
//            'column': column
//          });

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
      ranges.add(new Range(fromRow: rows[i], fromCell: 0, toRow: rows[i], toCell: lastCell));
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
//      "updateColumnHeader": updaBUSteColumnHeader,
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

  /**
   * on header-mouse-enter
   */
  async.Stream<core.HeaderMouseEnter> get onBwuHeaderMouseEnter =>
      eventBus.onEvent(core.Events.HEADER_MOUSE_ENTER);
      //BwuDatagrid._onBwuHeaderMouseEnter.forTarget(this);

//  static const dom.EventStreamProvider<dom.CustomEvent> _onBwuHeaderMouseEnter =
//      const dom.EventStreamProvider<dom.CustomEvent>(core.Events.HEADER_MOUSE_ENTER);

  /**
   * on mouse-enter
   */
  async.Stream<core.MouseEnter> get onBwuMouseEnter =>
      eventBus.onEvent(core.Events.MOUSE_ENTER);
      //BwuDatagrid._onBwuMouseEnter.forTarget(this);

//  static const dom.EventStreamProvider<dom.CustomEvent> _onBwuMouseEnter =
//      const dom.EventStreamProvider<dom.CustomEvent>(core.Events.MOUSE_ENTER);


  /**
   * on header-mouse-leave
   */
  async.Stream<core.HeaderMouseLeave> get onBwuHeaderMouseLeave =>
      eventBus.onEvent(core.Events.HEADER_MOUSE_LEAVE);
      //BwuDatagrid._onBwuHeaderMouseLeave.forTarget(this);

//  static const dom.EventStreamProvider<dom.CustomEvent> _onBwuHeaderMouseLeave =
//      const dom.EventStreamProvider<dom.CustomEvent>(core.Events.HEADER_MOUSE_LEAVE);

  /**
   * on mouse-enter
   */
  async.Stream<core.MouseLeave> get onBwuMouseLeave =>
      eventBus.onEvent(core.Events.MOUSE_LEAVE);
      //BwuDatagrid._onBwuMouseLeave.forTarget(this);

//  static const dom.EventStreamProvider<dom.CustomEvent> _onBwuMouseLeave =
//      const dom.EventStreamProvider<dom.CustomEvent>(core.Events.MOUSE_LEAVE);

}
//  /**
//   * on before--destory
//   */
//  static const ON_BEFORE_DESTROY = 'before-destory';
//  async.Stream<dom.CustomEvent> get onBeforeDestory =>
//      BwuDatagrid._onBeforeDestory.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onBeforeDestory =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_BEFORE_DESTROY);

//  /**
//   * on before-header-cell-destory
//   */
//  static const ON_BEFORE_HEADER_CELL_DESTROY = 'before-header-cell-destory';
//  async.Stream<dom.CustomEvent> get onBeforeHeaderCellDestory =>
//      BwuDatagrid._onBeforeHeaderCellDestory.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onBeforeHeaderCellDestory =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_BEFORE_HEADER_CELL_DESTROY);

//  /**
//   * on header-cell-rendered
//   */
//  static const ON_HEADER_CELL_RENDERED = 'header-cell-rendered';
//  async.Stream<dom.CustomEvent> get onHeaderCellRendered =>
//      BwuDatagrid._onHeaderCellRendered.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onHeaderCellRendered =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_HEADER_CELL_RENDERED);

//  /**
//   * on header-row-cell-rendered
//   */
//  static const ON_HEADER_ROW_CELL_RENDERED = 'header-row-cell-rendered';
//  async.Stream<dom.CustomEvent> get onHeaderRowCellRendered =>
//      BwuDatagrid._onHeaderRowCellRendered.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onHeaderRowCellRendered =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_HEADER_ROW_CELL_RENDERED);

//  /**
//   * on sort
//   */
//  static const ON_SORT = 'sort';
//  async.Stream<dom.CustomEvent> get onSort =>
//      BwuDatagrid._onSort.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onSort =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_SORT);
//
//  /**
//   * on columns-resized
//   */
//  static const ON_COLUMNS_RESIZED = 'columns-resized';
//  async.Stream<dom.CustomEvent> get onColumnsResized =>
//      BwuDatagrid._onColumnsResized.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onColumnsResized =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_COLUMNS_RESIZED);

//  /**
//   * on columns-reordered
//   */
//  static const ON_COLUMNS_REORDERED = 'columns-reordered';
//  async.Stream<dom.CustomEvent> get onColumnsReordered =>
//      BwuDatagrid._onColumnsReordered.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onColumnsReordered =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_COLUMNS_REORDERED);

//  /**
//   * on selected-rows-changed
//   */
//  static const ON_SELECTED_ROWS_CHANGED = 'selected-rows-changed';
//  async.Stream<dom.CustomEvent> get onSelectedRowsChanged =>
//      BwuDatagrid._onSelectedRowsChanged.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onSelectedRowsChanged =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_SELECTED_ROWS_CHANGED);

//  /**
//   * on viewport-changed
//   */
//  static const ON_VIEWPORT_CHANGED = 'viewport-changed';
//  async.Stream<dom.CustomEvent> get onViewportChanged =>
//      BwuDatagrid._onViewportChanged.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onViewportChanged =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_VIEWPORT_CHANGED);

//  /**
//   * on cell-css-styles-changed
//   */
//  static const ON_CELL_CSS_STYLES_CHANGED = 'cell-css-styles-changed';
//  async.Stream<dom.CustomEvent> get onCellCssStylesChanged =>
//      BwuDatagrid._onCellCssStylesChanged.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onCellCssStylesChanged =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_CELL_CSS_STYLES_CHANGED);


//  /**
//   * on header-mouse-leave
//   */
//  static const ON_HEADER_CONTEXT_MENU = 'header-context-menu';
//  async.Stream<dom.CustomEvent> get onHeaderContextMenu =>
//      BwuDatagrid._onHeaderContextMenu.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onHeaderContextMenu =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_HEADER_CONTEXT_MENU);

//  /**
//   * on header-click
//   */
//  static const ON_HEADER_CLICK = 'header-click';
//  async.Stream<dom.CustomEvent> get onHeaderClick =>
//      BwuDatagrid._onHeaderClick.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onHeaderClick =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_HEADER_CLICK);

//  /**
//   * on active-cell-changed
//   */
//  static const ON_ACTIVE_CELL_CHANGED = 'active-cell-changed';
//  async.Stream<dom.CustomEvent> get onActiveCellChanged =>
//      BwuDatagrid._onActiveCellChanged.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onActiveCellChanged =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_ACTIVE_CELL_CHANGED);

//  /**
//   * on before-cell-editor-destroy
//   */
//  static const ON_BEFORE_CELL_EDITOR_DESTROY = 'before-cell-editor-destroy';
//  async.Stream<dom.CustomEvent> get onBeforeCellEditorDestroy =>
//      BwuDatagrid._onBeforeCellEditorDestroy.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onBeforeCellEditorDestroy =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_BEFORE_CELL_EDITOR_DESTROY);

//  /**
//   * on before-edit-cell
//   */
//  static const ON_BEFORE_EDIT_CELL = 'before-edit-cell';
//  async.Stream<dom.CustomEvent> get onBeforeEditCell =>
//      BwuDatagrid._onBeforeEditCell.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvenHeaderMouseentert> _onBeforeEditCell =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_BEFORE_EDIT_CELL);

//  /**
//   * on active-cell-position-changed
//   */
//  static const ON_ACTIVE_CELL_POSITION_CHANGED = 'active-cell-position-changed';
//  async.Stream<dom.CustomEvent> get onActiveCellPositionChanged =>
//      BwuDatagrid._onActiveCellPositionChanged.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onActiveCellPositionChanged =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_ACTIVE_CELL_POSITION_CHANGED);

//  /**
//   * on cell-changed
//   */
//  static const ON_CELL_CHANGED = 'cell-changed';
//  async.Stream<dom.CustomEvent> get onCellChanged =>
//      BwuDatagrid._onCellChanged.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onCellChanged =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_CELL_CHANGED);

//  /**
//   * on add-new-row
//   */
//  static const ON_ADD_NEW_ROW = 'add-new-row';
//  async.Stream<dom.CustomEvent> get onAddNewRow =>
//      BwuDatagrid._onAddNewRow.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onAddNewRow =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_ADD_NEW_ROW);

//  /**
//   * on validation-error
//   */
//  static const ON_VALIDATION_ERROR = 'validation-error';
//  async.Stream<dom.CustomEvent> get onValidationError =>
//      BwuDatagrid._onValidationError.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onValidationError =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_VALIDATION_ERROR);

//  /**
//   * on drag-init
//   */
//  static const ON_DRAG_INIT = 'drag-init';
//  async.Stream<dom.CustomEvent> get onDragInit =>
//      BwuDatagrid._onDragInit.forTarget(this);
//
//  static const dom.EventStreamProvider<dom.CustomEvent> _onDragInit =
//      const dom.EventStreamProvider<dom.CustomEvent>(ON_DRAG_INIT);
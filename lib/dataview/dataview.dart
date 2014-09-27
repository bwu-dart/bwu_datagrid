library bwu_dart.bwu_datagrid.dataview;

import 'dart:math' as math;
import 'dart:async' as async;
import 'package:bwu_datagrid/groupitem_metadata_providers/groupitem_metadata_providers.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/bwu_datagrid.dart' as grid;

part 'aggregators.dart';
part 'helpers.dart';

//(function ($) {
//  $.extend(true, window, {
//    Slick: {
//      Data: {
//        DataView: DataView,
//        Aggregators: {
//          Avg: AvgAggregator,
//          Min: MinAggregator,
//          Max: MaxAggregator,
//          Sum: SumAggregator
//        }
//      }
//    }
//  });


typedef bool FilterFn(a, b);

class DataView extends DataProvider {

  /***
   * A sample Model implementation.
   * Provides a filtered view of the underlying data.
   *
   * Relies on the data item having an "id" property uniquely identifying it.
   */

  DataViewOptions options = new DataViewOptions();
  GroupingInfo groupingInfo = new GroupingInfo();

  DataView({DataViewOptions options, List<DataItem> items}) : super(items) {
    if(options != null) {
      this.options = options;
    }
  }

  // private
  String idProperty = "id";  // property holding a unique row id
  //List<core.ItemBase> items = [];         // data by index
  List<core.ItemBase> rows = [];          // data by row
  Map<dynamic,int> idxById = {};       // indexes by id - the id needs to be a valid map key
  Map<dynamic,int> rowsById = null;    // rows by id; lazy-calculated - the id needs to be a valid map key
  FilterFn filter = null;      // filter function
  Map<dynamic,bool> updated = null;     // updated item ids - the id needs to be a valid map key
  bool suspend = false;    // suspends the recalculation
  bool sortAsc = true;
  String fastSortField;
  SortComparerFunc sortComparer;
  Map<String,int> refreshHints = {}; // TODO make class, if this String stores ids it should be dynamic
  Map<String,int> prevRefreshHints = {};
  Map filterArgs;
  List<core.ItemBase> filteredItems = [];
  FilterFn compiledFilter;
  FilterFn compiledFilterWithCaching;
  Map<int,bool> filterCache = {};

  List<GroupingInfo> groupingInfos = [];
  List<core.Group> groups = [];
  List<Map<String,core.Group>> toggledGroupsByLevel = [];
  String groupingDelimiter = ':|:';

  int pagesize = 0;
  int pagenum = 0;
  int totalRows = 0;

  core.EventBus get eventBus => _eventBus;
  core.EventBus _eventBus = new core.EventBus();

  async.Stream<core.PagingInfoChanged> get onBwuPagingInfoChanged =>
      _eventBus.onEvent(core.Events.PAGING_INFO_CHANGED);

  async.Stream<core.RowCountChanged> get onBwuRowCountChanged =>
      _eventBus.onEvent(core.Events.ROW_COUNT_CHANGED);

  async.Stream<core.RowsChanged> get onBwuRowsChanged =>
      _eventBus.onEvent(core.Events.ROWS_CHANGED);

  async.Stream<core.SelectedRowIdsChanged> get onBwuSelectedRowIdsChanged =>
      _eventBus.onEvent(core.Events.SELECTED_ROW_IDS_CHANGED);


  void beginUpdate() {
    suspend = true;
  }

  void endUpdate() {
    suspend = false;
    refresh();
  }

  void setRefreshHints(Map<String,int> hints) {
    refreshHints = hints;
  }

  void setFilterArgs(Map args) {
    filterArgs = args;
  }

  void updateIdxById([int startingIndex]) {
    startingIndex = startingIndex != null ? startingIndex : 0;
    var id;
    for (int i = startingIndex; i < items.length; i++) {
      id = items[i][idProperty];
      if (id == null) {
        throw "Each data element must implement a unique 'id' property";
      }
      idxById[id] = i;
    }
  }

  void ensureIdUniqueness() {
    var id;
    for (int i = 0; i < items.length; i++) {
      id = items[i][idProperty];
      if (id == null || idxById[id] != i) {
        throw "Each data element must implement a unique 'id' property";
      }
    }
  }

  List<core.ItemBase> getItems() => items;

  @override set items(List<core.ItemBase> items) => setItems(items);

  void setItems(List<DataItem> data, [String objectIdProperty]) {
    if (objectIdProperty != null) {
      idProperty = objectIdProperty;
    }
    super.items = filteredItems = data;
    idxById = {};
    updateIdxById();
    ensureIdUniqueness();
    refresh();
  }

  void setPagingOptions(PagingInfo args) {
    if (args.pageSize != null) {
      pagesize = args.pageSize;
      pagenum = pagesize != null && pagesize != 0? math.min(pagenum, math.max(0, (totalRows / pagesize).ceil() - 1)) : 0;
    }

    if (args.pageNum != null) {
      pagenum = math.min(args.pageNum, math.max(0, (totalRows / pagesize).ceil() - 1));
    }

    eventBus.fire(core.Events.PAGING_INFO_CHANGED, new core.PagingInfoChanged(this, pagingInfo: getPagingInfo()));
    refresh();
  }

  PagingInfo getPagingInfo() {
    var totalPages = pagesize != null && pagesize != 0 ? math.max(1, (totalRows / pagesize).ceil()) : 1;
    return new PagingInfo(pageSize: pagesize, pageNum: pagenum, totalRows: totalRows, totalPages: totalPages);
  }

  void sort(SortComparerFunc comparer, [bool ascending = true]) {
    assert(ascending is bool && ascending != null);

    sortAsc = ascending;
    sortComparer = comparer;
    fastSortField = null;
    if (ascending == false) { // TODO why would it make sense to revers before sorting?
      items = items.reversed.toList();
    }
    items.sort(comparer);
    if (ascending == false) {
      items = items.reversed.toList();
    }
    idxById = {};
    updateIdxById();
    refresh();
  }

//    /***
//     * Provides a workaround for the extremely slow sorting in IE.
//     * Does a [lexicographic] sort on a give column by temporarily overriding Object.prototype.toString
//     * to return the value of that field and then doing a native Array.sort().
//     */
//    void fastSort(String field, bool ascending) {
//      sortAsc = ascending;
//      fastSortField = field;
//      sortComparer = null;
//      var oldToString = Object.prototype.toString;
//      Object.prototype.toString = (typeof field == "function") ? field : function () {
//        return this[field]
//      };
//      // an extra reversal for descending sort keeps the sort stable
//      // (assuming a stable native sort implementation, which isn't true in some cases)
//      if (ascending === false) {
//        items.reverse();
//      }
//      items.sort();
//      Object.prototype.toString = oldToString;
//      if (ascending === false) {
//        items.reverse();
//      }
//      idxById = {};
//      updateIdxById();
//      refresh();
//    }

  void reSort() {
    if (sortComparer != null) {
      sort(sortComparer, sortAsc);
//      } else if (fastSortField != null) {
//        fastSort(fastSortField, sortAsc);
      }
  }

  void setFilter(FilterFn filterFn) {
    filter = filterFn;
    if (options.inlineFilters) {
      //compiledFilter = compileFilter();
      //compiledFilterWithCaching = compileFilterWithCaching();
    }
    refresh();
  }

  List<GroupingInfo> get getGrouping => groupingInfos;

  void setGrouping(List<GroupingInfo> groupingInfo) {
    if (options.groupItemMetadataProvider == null) {
      options.groupItemMetadataProvider = new GroupItemMetadataProvider();
    }

    groups = [];
    toggledGroupsByLevel = [];
    groupingInfo = groupingInfo != null ? groupingInfo : [];
    groupingInfos = (groupingInfo is List) ? groupingInfo : [groupingInfo];

    for (var i = 0; i < groupingInfos.length; i++) {
      GroupingInfo gi = groupingInfos[i];
      gi.getterIsAFn = gi.getter is Function;

      // pre-compile accumulator loops
//      gi.compiledAccumulators = [];
//      int idx = gi.aggregators.length;
//      while (idx-- != 0) {
//        gi.compiledAccumulators[idx] = compileAccumulatorLoop(gi.aggregators[idx]);
//      }
      toggledGroupsByLevel.add({});
    }
    refresh();
  }

//    /**
//     * @deprecated Please use {@link setGrouping}.
//     */
//    function groupBy(valueGetter, valueFormatter, sortComparer) {
//      if (valueGetter == null) {
//        setGrouping([]);
//        return;
//      }
//
//      setGrouping({
//        getter: valueGetter,
//        formatter: valueFormatter,
//        comparer: sortComparer
//      });
//    }
//
//    /**
//     * @deprecated Please use {@link setGrouping}.
//     */
//    function setAggregators(groupAggregators, includeCollapsed) {
//      if (!groupingInfos.length) {
//        throw new Error("At least one grouping must be specified before calling setAggregators().");
//      }
//
//      groupingInfos[0].aggregators = groupAggregators;
//      groupingInfos[0].aggregateCollapsed = includeCollapsed;
//
//      setGrouping(groupingInfos);
//    }

  DataItem getItemByIdx(int i) {
    if(i < 0 || i >= items.length) {
      return null;
    }
    return items[i];
  }

  int getIdxById(id) {
    return idxById[id];
  }

  void ensureRowsByIdCache() {
    if (rowsById == null) {
      rowsById = {};
      for (int i = 0; i < rows.length; i++) {
        rowsById[rows[i][idProperty]] = i;
      }
    }
  }

  // the id needs to be a valid map key
  int getRowById(id) {
    ensureRowsByIdCache();
    return rowsById[id];
  }

  // the id needs to be a valid map key
  DataItem getItemById(id) {
    var idx = idxById[id];
    if(idx == null) {
      return null;
    }
    return items[idx];
  }

  // the id needs to be a valid map key
  List<int> mapIdsToRows(List idArray) {
    List<int> rows = [];
    ensureRowsByIdCache();
    for (int i = 0; i < idArray.length; i++) {
      var row = rowsById[idArray[i]];
      if (row != null) {
        rows.add(row);
      }
    }
    return rows;
  }

  // the id needs to be a valid map key
  List mapRowsToIds(List<int> rowArray) {
    List ids = [];
    for (int i = 0; i < rowArray.length; i++) {
      if (rowArray[i] < rows.length) {
        ids.add(rows[rowArray[i]][idProperty]);
      }
    }
    return ids;
  }

  // the id needs to be a valid map key
  void updateItem(id, core.ItemBase item) {
    if (idxById[id] == null || id != item[idProperty]) {
      throw "Invalid or non-matching id";
    }
    items[idxById[id]] = item;
    if (updated == null) {
      updated = {};
    }
    updated[id] = true;
    refresh();
  }

  void insertItem(int insertBefore, core.ItemBase item) {
    items.insert(insertBefore, item);
    updateIdxById(insertBefore);
    refresh();
  }

  void addItem(DataItem item) {
    items.add(item);
    updateIdxById(items.length - 1);
    refresh();
  }

  // the id needs to be a valid map key
  void deleteItem(id) {
    int idx = idxById[id];
    if (idx == null) {
      throw "Invalid id";
    }
    idxById.remove(id);
    items.removeAt(idx);
    updateIdxById(idx);
    refresh();
  }

  int get length => rows.length;

  core.ItemBase getItem(int i) {
    core.ItemBase item = rows[i];

    // if this is a group row, make sure totals are calculated and update the title
    if (item != null && item is core.Group && item.totals != null && !item.totals.isInitialized) {
      GroupingInfo gi = groupingInfos[item.level];
      if (!gi.isDisplayTotalsRow) {
        calculateTotals(item.totals);
        item.title = gi.formatter != null ? gi.formatter(item) : item.value;
      }
    }
    // if this is a totals row, make sure it's calculated
    else if (item != null && item is core.GroupTotals && !item.isInitialized) {
      calculateTotals(item);
    }

    return item;
  }

  RowMetadata getItemMetadata(int i) {
    if(rows.length <= i) {
      return null;
    }
    var item = rows[i];
    if (item == null) {
      return null;
    }

    // overrides for grouping rows
    if (item is core.Group) {
      return options.groupItemMetadataProvider.getGroupRowMetadata(item);
    }

    // overrides for totals rows
    if (item is core.GroupTotals) {
      return options.groupItemMetadataProvider.getTotalsRowMetadata(item);
    }

    return null;
  }

  void expandCollapseAllGroups(bool collapse, [int level]) {
    if (level == null) {
      for (var i = 0; i < groupingInfos.length; i++) {
        toggledGroupsByLevel[i] = {};
        groupingInfos[i].isCollapsed = collapse;
      }
    } else {
      toggledGroupsByLevel[level] = {};
      groupingInfos[level].isCollapsed = collapse;
    }
    refresh();
  }

  /**
   * @param level {Number} Optional level to collapse.  If not specified, applies to all levels.
   */
  void  collapseAllGroups([int level]) {
    expandCollapseAllGroups(true, level);
  }

  /**
   * @param level {Number} Optional level to expand.  If not specified, applies to all levels.
   */
  void expandAllGroups([int level]) {
    expandCollapseAllGroups(false, level);
  }

  void expandCollapseGroup(int level, String groupingKey, bool collapse) {
    toggledGroupsByLevel[level][groupingKey] = groupingInfos[level].isCollapsed != collapse ? groupingInfos[level].isCollapsed : null;
    refresh();
  }

  /**
   * @param varArgs Either a Group's "groupingKey" property, or a
   *     variable argument list of grouping values denoting a unique path to the row.  For
   *     example, calling collapseGroup('high', '10%') will collapse the '10%' subgroup of
   *     the 'high' group.
   */
  void collapseGroup(List<String> varArgs) {
    var args = varArgs.toList(); //Array.prototype.slice.call(arguments); // TODO select elements from an array, arguments is an array of args passed to this function
    var arg0 = args[0];
    if (args.length == 1 && arg0.indexOf(groupingDelimiter) != -1) {
      expandCollapseGroup(arg0.split(groupingDelimiter).length - 1, arg0, true);
    } else {
      expandCollapseGroup(args.length - 1, args.join(groupingDelimiter), true);
    }
  }

  /**
   * @param varArgs Either a Group's "groupingKey" property, or a
   *     variable argument list of grouping values denoting a unique path to the row.  For
   *     example, calling expandGroup('high', '10%') will expand the '10%' subgroup of
   *     the 'high' group.
   */
  void expandGroup(List<String> varArgs) {
    var args = varArgs.toList(); //Array.prototype.slice.call(arguments); // TODO
    var arg0 = args[0];
    if (args.length == 1 && arg0.indexOf(groupingDelimiter) != -1) {
      expandCollapseGroup(arg0.split(groupingDelimiter).length - 1, arg0, false);
    } else {
      expandCollapseGroup(args.length - 1, args.join(groupingDelimiter), false);
    }
  }

  List<core.Group> get getGroups => groups;

  List<core.Group> extractGroups(List<core.ItemBase> rows, [core.Group parentGroup]) {
    core.Group group;
    var val;
    List<core.Group> groups = [];
    Map<int, core.Group> groupsByVal = {};
    core.ItemBase r;
    int level = parentGroup != null ? parentGroup.level + 1 : 0;
    GroupingInfo gi = groupingInfos[level];

    for (int i = 0; i < gi.predefinedValues.length; i++) {
      val = gi.predefinedValues[i];
      group = groupsByVal[val];
      if (group == null) {
        group = new core.Group();
        group.value = val;
        group.level = level;
        group.groupingKey = '${(parentGroup != null ? '${parentGroup.groupingKey}${groupingDelimiter}' : '')}${val}';
        groups.add(group);
        groupsByVal[val] = group;
      }
    }

    for (int i = 0; i < rows.length; i++) {
      r = rows[i];
      val = gi.getterIsAFn ? gi.getter(r) : r[gi.getter];
      group = groupsByVal[val];
      if (group == null) {
        group = new core.Group();
        group.value = val;
        group.level = level;
        group.groupingKey = '${(parentGroup != null ? '${parentGroup.groupingKey}${groupingDelimiter}' : '')}${val}';
        groups.add(group);
        groupsByVal[val] = group;
      }

      group.rows.add(r);
    }

    if (level < groupingInfos.length - 1) {
      for (int i = 0; i < groups.length; i++) {
        group = groups[i];
        group.groups = extractGroups(group.rows, group);
      }
    }

    groups.sort(groupingInfos[level].comparer);

    return groups;
  }

  void calculateTotals(core.GroupTotals totals) {
    core.Group group = totals.group; // TODO group or parent?
    GroupingInfo gi = groupingInfos[group.level];
    bool isLeafLevel = (group.level == groupingInfos.length);
    Aggregator agg;
    int idx = gi.aggregators.length;

    if (!isLeafLevel && gi.doAggregateChildGroups) {
      // make sure all the subgroups are calculated
      int i = group.groups != null ? group.groups.length : 0;
      while (i-- > 0) {
        if (group.groups[i].totals != null && !group.groups[i].totals.isInitialized) {
          calculateTotals(group.groups[i].totals);
        }
      }
    }

    while (idx-- > 0) {
      agg = gi.aggregators[idx];
      agg.init();
      if (!isLeafLevel && gi.doAggregateChildGroups) {
        agg(group.groups);
      } //else {
        agg(group.rows);
      //}
      agg.storeResult(totals);
    }
    totals.isInitialized = true;
  }

  void addGroupTotals(core.Group group) {
    GroupingInfo gi = groupingInfos[group.level];
    core.GroupTotals totals = new core.GroupTotals();
    totals.group = group;
    group.totals = totals;
    if (!gi.isLazyTotalsCalculation) {
      calculateTotals(totals);
    }
  }

  void addTotals(List<core.Group> groups, [int level]) {
    level = level != null ? level : 0;
    GroupingInfo gi = groupingInfos[level];
    bool groupCollapsed = gi.isCollapsed;
    Map<String,core.Group> toggledGroups = toggledGroupsByLevel[level];
    int idx = groups.length;
    core.Group g;
    while (idx-- > 0) {
      g = groups[idx];

      if (g.isCollapsed && !gi.doAggregateCollapsed) {
        continue;
      }

      // Do a depth-first aggregation so that parent group aggregators can access subgroup totals.
      if (g.groups != null) {
        addTotals(g.groups, level + 1);
      }

      if (gi.aggregators.length > 0 && (
          gi.doAggregateEmpty || g.rows.length > 0 || (g.groups != null && g.groups.length > 0))) {
        addGroupTotals(g);
      }

      g.isCollapsed = groupCollapsed != (toggledGroups[g.groupingKey] != null);
      g.title = gi.formatter != null ? gi.formatter(g) : g.value;
    }
  }

  List<core.ItemBase> flattenGroupedRows(List<core.Group> groups, [int level]) {
    level = level != null ? level : 0;
    GroupingInfo gi = groupingInfos[level];
    List<core.ItemBase> groupedRows = [];
    List<core.ItemBase>rows;
    int gl = 0;
    core.Group g;
    for (int i = 0; i < groups.length; i++) {
      g = groups[i];
      groupedRows.add(g); //[gl++] = g;

      if (!g.isCollapsed) {
        rows = g.groups != null ? flattenGroupedRows(g.groups, level + 1) : g.rows;
        for (int j = 0; j < rows.length; j++) {
          groupedRows.add(rows[j]); //[gl++] = rows[j];
        }
      }

      if (g.totals != null && gi.isDisplayTotalsRow && (!g.isCollapsed || gi.doAggregateCollapsed)) {
        groupedRows.add(g.totals); //[gl++] = g.totals;
      }
    }
    return groupedRows;
  }

//  FunctionInfo getFunctionInfo(Function fn) {
//    RegExp fnRegex = new RegExp(r'^function[^(]*\(([^)]*)\)\s*{([\s\S]*)}$');
//    List<Match> matches = fnRegex.allMatches(fn.toString());
//    //List<Match> matches = fn.toString().allMatches(fnRegex);
//    return new FunctionInfo(matches[1].split(","), matches[2]);
//  }

//  String compileAccumulatorLoop(Aggregator aggregator) {
//    var accumulatorInfo = getFunctionInfo(aggregator.accumulate);
//      var fn = new Function(
//          "_items",
//          "for (var " + accumulatorInfo.params[0] + ", _i=0, _il=_items.length; _i<_il; _i++) {" +
//              accumulatorInfo.params[0] + " = _items[_i]; " +
//              accumulatorInfo.body +
//          "}"
//      );
//      fn.displayName = fn.name = "compiledAccumulatorLoop";
//      return fn;
//  }


//  FilterFn compileFilter() {
//    var filterInfo = getFunctionInfo(filter);

//      var filterBody = filterInfo.body
//          .replace(/return false\s*([;}]|$)/gi, "{ continue _coreloop; }$1")
//          .replace(/return true\s*([;}]|$)/gi, "{ _retval[_idx++] = $item$; continue _coreloop; }$1")
//          .replace(/return ([^;}]+?)\s*([;}]|$)/gi,
//          "{ if ($1) { _retval[_idx++] = $item$; }; continue _coreloop; }$2");

      // This preserves the function template code after JS compression,
      // so that replace() commands still work as expected.
//      var tpl = [
//        //"function(_items, _args) { ",
//        "var _retval = [], _idx = 0; ",
//        "var $item$, $args$ = _args; ",
//        "_coreloop: ",
//        "for (var _i = 0, _il = _items.length; _i < _il; _i++) { ",
//        "$item$ = _items[_i]; ",
//        "$filter$; ",
//        "} ",
//        "return _retval; "
//        //"}"
//      ].join("");
//      tpl = tpl.replace(/\$filter\$/gi, filterBody);
//      tpl = tpl.replace(/\$item\$/gi, filterInfo.params[0]);
//      tpl = tpl.replace(/\$args\$/gi, filterInfo.params[1]);

//    var fn = new Function("_items,_args", tpl);
//    fn.displayName = fn.name = "compiledFilter";
//    return fn;
//  }

//  FilterFn compileFilterWithCaching() {
//    var filterInfo = getFunctionInfo(filter);
//
//      var filterBody = filterInfo.body
//          .replace(/return false\s*([;}]|$)/gi, "{ continue _coreloop; }$1")
//          .replace(/return true\s*([;}]|$)/gi, "{ _cache[_i] = true;_retval[_idx++] = $item$; continue _coreloop; }$1")
//          .replace(/return ([^;}]+?)\s*([;}]|$)/gi,
//          "{ if ((_cache[_i] = $1)) { _retval[_idx++] = $item$; }; continue _coreloop; }$2");

      // This preserves the function template code after JS compression,
      // so that replace() commands still work as expected.
//      var tpl = [
//        //"function(_items, _args, _cache) { ",
//        "var _retval = [], _idx = 0; ",
//        "var $item$, $args$ = _args; ",
//        "_coreloop: ",
//        "for (var _i = 0, _il = _items.length; _i < _il; _i++) { ",
//        "$item$ = _items[_i]; ",
//        "if (_cache[_i]) { ",
//        "_retval[_idx++] = $item$; ",
//        "continue _coreloop; ",
//        "} ",
//        "$filter$; ",
//        "} ",
//        "return _retval; "
//        //"}"
//      ].join("");
//      tpl = tpl.replace(/\$filter\$/gi, filterBody);
//      tpl = tpl.replace(/\$item\$/gi, filterInfo.params[0]);
//      tpl = tpl.replace(/\$args\$/gi, filterInfo.params[1]);

//    var fn = new Function("_items,_args,_cache", tpl);
//    fn.displayName = fn.name = "compiledFilterWithCaching";
//    return fn;
//  }

  List<core.ItemBase> uncompiledFilter(List<core.ItemBase>items, Map args) {
    List<core.ItemBase> retval = [];
    int idx = 0;

    try {
      for (int i = 0; i < items.length; i++) {
        if (filter(items[i], args)) {
          retval.add(items[i]);
        }
      }
    }catch(e, s) {
      print(e);
      print(s);
    }

    return retval;
  }

  List<core.ItemBase> uncompiledFilterWithCaching(List<core.ItemBase> items, Map args, Map<int,bool> cache) {
    List<core.ItemBase> retval = [];
    int idx = 0;
    core.ItemBase item;

    for (int i = 0; i < items.length; i++) {
      item = items[i];
      if (cache[i] == true) {
        retval.add(item);
      } else if (filter(item, args)) {
        retval.add(item);
        cache[i] = true;
      }
    }

    return retval;
  }

  Map getFilteredAndPagedItems(List<core.ItemBase> items) {
    if (filter != null) {
      var batchFilter = /*options.inlineFilters ? compiledFilter :*/ uncompiledFilter;
      var batchFilterWithCaching = /*options.inlineFilters ? compiledFilterWithCaching :*/ uncompiledFilterWithCaching;

      if (refreshHints['isFilterNarrowing'] == true) {
        filteredItems = batchFilter(filteredItems, filterArgs);
      } else if (refreshHints['isFilterExpanding'] == true) {
        filteredItems = batchFilterWithCaching(items, filterArgs, filterCache);
      } else if (refreshHints['isFilterUnchanged'] == null) {
        filteredItems = batchFilter(items, filterArgs);
      }
    } else {
      // special case:  if not filtering and not paging, the resulting
      // rows collection needs to be a copy so that changes due to sort
      // can be caught
      filteredItems = pagesize != null ? items : new List<core.ItemBase>.from(items);
    }

    // get the current page
    List<core.ItemBase> paged;
    if (pagesize != 0) {
      if (filteredItems.length < pagenum * pagesize) {
        pagenum = (filteredItems.length / pagesize).floor();
      }
      paged = filteredItems.getRange(pagesize * pagenum, math.min(pagesize * pagenum + pagesize, filteredItems.length)).toList();
    } else {
      paged = filteredItems;
    }

    return {'totalRows': filteredItems.length, 'rows': paged};
  }

  List<int> getRowDiffs(List<core.ItemBase> rows, List<core.ItemBase> newRows) {
    core.ItemBase item;
    core.ItemBase r;
    bool eitherIsNonData;
    List<int> diff = [];
    int from = 0;
    int to = newRows != null ? newRows.length : 0;

    if (refreshHints != null && refreshHints['ignoreDiffsBefore'] == true) {
      from = math.max(0,
          math.min(newRows.length, refreshHints['ignoreDiffsBefore']));
    }

    if (refreshHints != null && refreshHints['ignoreDiffsAfter'] == true) {
      to = math.min(newRows.length,
          math.max(0, refreshHints['ignoreDiffsAfter']));
    }

    final rl = rows.length;
    for (int i = from; i < to; i++) {
      if (i >= rl) {
        diff.add(i);
      } else {
        item = newRows[i];
        r = rows[i];

        eitherIsNonData = (item is core.NonDataItem);
        if ((groupingInfos.length > 0 && (eitherIsNonData || (r is core.NonDataItem)) &&
            item is core.Group != r is core.Group ||
            item is core.Group && item != r)
            || (eitherIsNonData &&
            // no good way to compare totals since they are arbitrary DTOs
            // deep object comparison is pretty expensive
            // always considering them 'dirty' seems easier for the time being
            (item is core.GroupTotals || r is core.GroupTotals))
            || item[idProperty] != r[idProperty]
            || (updated != null && updated[item[idProperty]] != null)
            ) {
          diff.add(i);
        }
      }
    }
    return diff;
  }

  List<int> recalc(List<core.ItemBase> items) {
    rowsById = null;

    if (refreshHints['isFilterNarrowing'] != prevRefreshHints['isFilterNarrowing'] ||
        refreshHints['isFilterExpanding'] != prevRefreshHints['isFilterExpanding']) {
      filterCache = {};
    }

    Map filteredItems = getFilteredAndPagedItems(items);
    totalRows = filteredItems['totalRows'];
    List<core.ItemBase> newRows = filteredItems['rows'];

    groups = [];
    if (groupingInfos.length > 0) {
      groups = extractGroups(newRows);
      if (groups.length > 0) {
        addTotals(groups);
        newRows = flattenGroupedRows(groups);
      }
    }

    List<int> diff = getRowDiffs(rows, newRows);

    rows = newRows;

    return diff;
  }

  void refresh() {
    if (suspend) {
      return;
    }

    int countBefore = rows.length;
    int totalRowsBefore = totalRows;

    List<int> diff = recalc(items /*, filter*/); //  pass as direct refs to avoid closure perf hit // TODO seems to be a bug. The receiving method has no filter param

    // if the current page is no longer valid, go to last page and recalc
    // we suffer a performance penalty here, but the main loop (recalc) remains highly optimized
    if (pagesize != 0 && totalRows < pagenum * pagesize) {
      pagenum = math.max(0, (totalRows / pagesize).ceil() - 1);
      diff = recalc(items /*, filter*/);
    }

    updated = null;
    prevRefreshHints = refreshHints;
    refreshHints = {};

    if (totalRowsBefore != totalRows) {
      eventBus.fire(core.Events.PAGING_INFO_CHANGED, new core.PagingInfoChanged(this, pagingInfo: getPagingInfo()));
      //onPagingInfoChanged.notify(getPagingInfo(), null, self);
    }
    if (countBefore != rows.length) {
      eventBus.fire(core.Events.ROW_COUNT_CHANGED, new core.RowCountChanged(this, oldCount: countBefore, newCount: rows.length));
      //onRowCountChanged.notify({previous: countBefore, current: rows.length}, null, self);
    }
    if (diff.length > 0) {
      eventBus.fire(core.Events.ROWS_CHANGED, new core.RowsChanged(this, changedRows: diff));
      //onRowsChanged.notify({rows: diff}, null, self);
    }
  }

  /***
   * Wires the grid and the DataView together to keep row selection tied to item ids.
   * This is useful since, without it, the grid only knows about rows, so if the items
   * move around, the same rows stay selected instead of the selection moving along
   * with the items.
   *
   * NOTE:  This doesn't work with cell selection model.
   *
   * @param grid {BwuDatagrid} The grid to sync selection with.
   * @param preserveHidden {Boolean} Whether to keep selected items that go out of the
   *     view due to them getting filtered out.
   * @param preserveHiddenOnSelectionChange {Boolean} Whether to keep selected items
   *     that are currently out of the view (see preserveHidden) as selected when selection
   *     changes.
   * @return {Event} An event that notifies when an internal list of selected row ids
   *     changes.  This is useful since, in combination with the above two options, it allows
   *     access to the full list selected row ids, and not just the ones visible to the grid.
   * @method syncGridSelection
   */
  async.Stream syncGridSelection(grid.BwuDatagrid grid, bool preserveHidden, {bool preserveHiddenOnSelectionChange: false}) {
    bool inHandler = false;
    // the id needs to be a valid map key
    List selectedRowIds = mapRowsToIds(grid.getSelectedRows());
    //var onSelectedRowIdsChanged = new Event();

    void setSelectedRowIds(rowIds) {
      // TODO(zoechi) check how this join works with non-String values
      if (selectedRowIds.join(",") == rowIds.join(",")) {
        return;
      }

      selectedRowIds = rowIds;

      eventBus.fire(core.Events.SELECTED_ROW_IDS_CHANGED, new core.SelectedRowIdsChanged(
        this, grid, selectedRowIds));
    }

    void update(e) {
      if (selectedRowIds.length > 0) {
        inHandler = true;
        var selectedRows = mapIdsToRows(selectedRowIds);
        if (!preserveHidden) {
          setSelectedRowIds(mapRowsToIds(selectedRows));
        }
        grid.setSelectedRows(selectedRows);
        inHandler = false;
      }
    }

    grid.onBwuSelectedRowsChanged.listen((e) {
      if (inHandler) { return; }
      var newSelectedRowIds = mapRowsToIds(grid.getSelectedRows());
      if (!preserveHiddenOnSelectionChange || !grid.getGridOptions.multiSelect) {
        setSelectedRowIds(newSelectedRowIds);
      } else {
        // keep the ones that are hidden
        List<String> existing = selectedRowIds.where((id) => getRowById(id) == null).toList();
        // add the newly selected ones
        setSelectedRowIds(existing.addAll(newSelectedRowIds));
      }
    });

    onBwuRowsChanged.listen(update);

    onBwuRowCountChanged.listen(update);

    return onBwuSelectedRowIdsChanged;
  }

  // TODO(zoechi) set type annotations
  void syncGridCellCssStyles(grid, key) {
    var hashById;
    var inHandler;

    void storeCellCssStyles(hash) {
      hashById = {};
      for (int row in hash) {
        var id = rows[row][idProperty];
        hashById[id] = hash[row];
      }
    }

    // since this method can be called after the cell styles have been set,
    // get the existing ones right away
    storeCellCssStyles(grid.getCellCssStyles(key));


    void update(dynamic e) {
      if (hashById) {
        inHandler = true;
        ensureRowsByIdCache();
        Map newHash = {};
        // the id needs to be a valid map key
        for (final id in hashById) {
          int row = rowsById[id];
          if (row != null) {
            newHash[row] = hashById[id];
          }
        }
        grid.setCellCssStyles(key, newHash);
        inHandler = false;
      }
    }

    grid.onCellCssStylesChanged.subscribe((e, args) {
      if (inHandler) { return; }
      if (key != args.key) { return; }
      if (args.hash) {
        storeCellCssStyles(args.hash);
      }
    });

    onBwuRowsChanged.listen(update);

    onBwuRowCountChanged.listen(update);
  }

//    $.extend(this, {
//      // methods
//      "beginUpdate": beginUpdate,
//      "endUpdate": endUpdate,
//      "setPagingOptions": setPagingOptions,
//      "getPagingInfo": getPagingInfo,
//      "getItems": getItems,
//      "setItems": setItems,
//      "setFilter": setFilter,
//      "sort": sort,
//      "fastSort": fastSort,
//      "reSort": reSort,
//      "setGrouping": setGrouping,
//      "getGrouping": getGrouping,
//      "groupBy": groupBy,
//      "setAggregators": setAggregators,
//      "collapseAllGroups": collapseAllGroups,
//      "expandAllGroups": expandAllGroups,
//      "collapseGroup": collapseGroup,
//      "expandGroup": expandGroup,
//      "getGroups": getGroups,
//      "getIdxById": getIdxById,
//      "getRowById": getRowById,
//      "getItemById": getItemById,
//      "getItemByIdx": getItemByIdx,
//      "mapRowsToIds": mapRowsToIds,
//      "mapIdsToRows": mapIdsToRows,
//      "setRefreshHints": setRefreshHints,
//      "setFilterArgs": setFilterArgs,
//      "refresh": refresh,
//      "updateItem": updateItem,
//      "insertItem": insertItem,
//      "addItem": addItem,
//      "deleteItem": deleteItem,
//      "syncGridSelection": syncGridSelection,
//      "syncGridCellCssStyles": syncGridCellCssStyles,
//
//      // data provider methods
//      "getLength": getLength,
//      "getItem": getItem,
//      "getItemMetadata": getItemMetadata,
//
//      // events
//      "onRowCountChanged": onRowCountChanged,
//      "onRowsChanged": onRowsChanged,
//      "onPagingInfoChanged": onPagingInfoChanged
//    });
//  }
//
}

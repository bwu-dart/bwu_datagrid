library bwu_dart.bwu_datagrid.dataview;

import 'dart:math' as math;
import 'dart:html' as dom;
import 'package:bwu_datagrid/core/core.dart';
import 'package:bwu_datagrid/groupitem_metadata_providers/groupitem_metadata_providers.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';

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


typedef FilterFunc(a, b);

class DataView {

  /***
   * A sample Model implementation.
   * Provides a filtered view of the underlying data.
   *
   * Relies on the data item having an "id" property uniquely identifying it.
   */

  Options options = new Options();
  GroupingInfo groupingInfo = new GroupingInfo();

  DataView([Options options]) {
    if(options != null) {
      this.options = options;
    }
  }

    // private
    String idProperty = "id";  // property holding a unique row id
    List<Item> items = [];         // data by index
    List<int> rows = [];          // data by row
    Map<String,int> idxById = {};       // indexes by id
    Map<String,int> rowsById = null;    // rows by id; lazy-calculated
    FilterFunc filter = null;      // filter function
    Map<String,bool> updated = null;     // updated item ids
    bool suspend = false;    // suspends the recalculation
    bool sortAsc = true;
    String fastSortField;
    SortComparerFunc sortComparer;
    Map<String,int> refreshHints = {};
    Map<String,int> prevRefreshHints = {};
    List<String> filterArgs;
    List<int> filteredItems = [];
    Function compiledFilter;
    Function compiledFilterWithCaching;
    List<String> filterCache = [];

    List<GroupingInfo> groupingInfos = [];
    List<Group> groups = [];
    List<bool> toggledGroupsByLevel = [];
    String groupingDelimiter = ':|:';

    int pagesize = 0;
    int pagenum = 0;
    int totalRows = 0;


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

    void setFilterArgs(List<String> args) {
      filterArgs = args;
    }

    void updateIdxById([startingIndex]) {
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
      String id;
      for (int i = 0; i < items.length; i++) {
        id = items[i][idProperty];
        if (id == null || idxById[id] != i) {
          throw "Each data element must implement a unique 'id' property";
        }
      }
    }

    List<Item> getItems() {
      return items;
    }

    void setItems(List<Map<String,int>> data, [String objectIdProperty]) {
      if (objectIdProperty != null) {
        idProperty = objectIdProperty;
      }
      items = filteredItems = data;
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

      EVENT_BUS.fire(Events.pagingInfoChanged, new EventData(sender: this));
      refresh();
    }

    PagingInfo getPagingInfo() {
      var totalPages = pagesize != null && pagesize != 0 ? math.max(1, (totalRows / pagesize).ceil()) : 1;
      return new PagingInfo(pageSize: pagesize, pageNum: pagenum, totalRows: totalRows, totalPages: totalPages);
    }

    void sort(SortComparerFunc comparer, bool ascending) {
      sortAsc = ascending;
      sortComparer = comparer;
      fastSortField = null;
      if (ascending == false) {
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
      } else if (fastSortField != null) {
        fastSort(fastSortField, sortAsc);
      }
    }

    void setFilter(filterFn) {
      filter = filterFn;
      if (options.inlineFilters) {
        compiledFilter = compileFilter();
        compiledFilterWithCaching = compileFilterWithCaching();
      }
      refresh();
    }

    List<GroupingInfo> get getGrouping => groupingInfos;

    void setGrouping(GroupingInfo groupingInfo) {
      if (options.groupItemMetadataProvider == null) {
        options.groupItemMetadataProvider = new GroupItemMetadataProvider();
      }

      groups = [];
      toggledGroupsByLevel = [];
      groupingInfo = groupingInfo != null ? groupingInfo : [];
      groupingInfos = (groupingInfo is List) ? groupingInfo : [groupingInfo];

      for (var i = 0; i < groupingInfos.length; i++) {
        var gi = groupingInfos[i] = $.extend(true, {}, groupingInfoDefaults, groupingInfos[i]);
        gi.getterIsAFn = gi.getter is Function;

        // pre-compile accumulator loops
        gi.compiledAccumulators = [];
        int idx = gi.aggregators.length;
        while (idx-- != 0) {
          gi.compiledAccumulators[idx] = compileAccumulatorLoop(gi.aggregators[idx]);
        }

        toggledGroupsByLevel[i] = {};
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

    int getItemByIdx(i) {
      return items[i];
    }

    int getIdxById(id) {
      return idxById[id];
    }

    void ensureRowsByIdCache() {
      if (rowsById != null) {
        rowsById = {};
        for (int i = 0; i < rows.length; i++) {
          rowsById[rows[i][idProperty]] = i;
        }
      }
    }

    int getRowById(String id) {
      ensureRowsByIdCache();
      return rowsById[id];
    }

    int getItemById(String id) {
      return items[idxById[id]];
    }

    List<int> mapIdsToRows(List<int> idArray) {
      List<int> rows = [];
      ensureRowsByIdCache();
      for (int i = 0; i < idArray.length; i++) {
        var row = rowsById[idArray[i]];
        if (row != null) {
          rows[rows.length] = row;
        }
      }
      return rows;
    }

    List<String> mapRowsToIds(List<int> rowArray) {
      List<String> ids = [];
      for (int i = 0; i < rowArray.length; i++) {
        if (rowArray[i] < rows.length) {
          ids[ids.length] = rows[rowArray[i]][idProperty];
        }
      }
      return ids;
    }

    void updateItem(String id, int item) {
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

    void insertItem(int insertBefore, String item) {
      items.splice(insertBefore, 0, item); // TODO
      updateIdxById(insertBefore);
      refresh();
    }

    void addItem(String item) {
      items.add(item);
      updateIdxById(items.length - 1);
      refresh();
    }

    void deleteItem(String id) {
      int idx = idxById[id];
      if (idx == null) {
        throw "Invalid id";
      }
      idxById.remove(id);
      items.removeAt(idx);
      updateIdxById(idx);
      refresh();
    }

    int get getLength => rows.length;

    String getItem(int i) {
      String item = rows[i];

      // if this is a group row, make sure totals are calculated and update the title
      if (item != null && item is Group && (item as Group).totals != null && !(item as Group).totals.isInitialized) {
        GroupingInfo gi = groupingInfos[(item as Group).level];
        if (!gi.isDisplayTotalsRow) {
          calculateTotals((item as Group).totals);
          (item as Group).title = gi.formatter != null ? gi.formatter(item) : (item as Group).value;
        }
      }
      // if this is a totals row, make sure it's calculated
      else if (item && item is GroupTotals && !(item as GroupTotals).isInitialized) {
        calculateTotals(item);
      }

      return item;
    }

    MetaData getItemMetadata(int i) {
      var item = rows[i];
      if (item == null) {
        return null;
      }

      // overrides for grouping rows
      if (item is Group) {
        return options.groupItemMetadataProvider.getGroupRowMetadata(item);
      }

      // overrides for totals rows
      if (item is GroupTotals) {
        return options.groupItemMetadataProvider.getTotalsRowMetadata(item);
      }

      return null;
    }

    void expandCollapseAllGroups(level, collapse) {
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
    void  collapseAllGroups(int level) {
      expandCollapseAllGroups(level, true);
    }

    /**
     * @param level {Number} Optional level to expand.  If not specified, applies to all levels.
     */
    void expandAllGroups(int level) {
      expandCollapseAllGroups(level, false);
    }

    void expandCollapseGroup(int level, String groupingKey, bool collapse) {
      toggledGroupsByLevel[level][groupingKey] = groupingInfos[level].isCollapsed ^ collapse; // TODO ^
      refresh();
    }

    /**
     * @param varArgs Either a Group's "groupingKey" property, or a
     *     variable argument list of grouping values denoting a unique path to the row.  For
     *     example, calling collapseGroup('high', '10%') will collapse the '10%' subgroup of
     *     the 'high' group.
     */
    void collapseGroup(String varArgs) {
      var args = Array.prototype.slice.call(arguments);
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
    void expandGroup(varArgs) {
      var args = Array.prototype.slice.call(arguments); // TODO
      var arg0 = args[0];
      if (args.length == 1 && arg0.indexOf(groupingDelimiter) != -1) {
        expandCollapseGroup(arg0.split(groupingDelimiter).length - 1, arg0, false);
      } else {
        expandCollapseGroup(args.length - 1, args.join(groupingDelimiter), false);
      }
    }

    List<Group> get getGroups => groups;

    List<Group> extractGroups(List<int>rows, [Group parentGroup]) {
      Group group;
      int val;
      List<Group> groups = [];
      Map<int, Group> groupsByVal = {};
      int r;
      int level = parentGroup != null ? parentGroup.level + 1 : 0;
      GroupingInfo gi = groupingInfos[level];

      for (int i = 0; i < gi.predefinedValues.length; i++) {
        val = gi.predefinedValues[i];
        group = groupsByVal[val];
        if (group == null) {
          group = new Group();
          group.value = val;
          group.level = level;
          group.groupingKey = (parentGroup != null ? parentGroup.groupingKey + groupingDelimiter : '') + val;
          groups[groups.length] = group;
          groupsByVal[val] = group;
        }
      }

      for (int i = 0; i < rows.length; i++) {
        r = rows[i];
        val = gi.getterIsAFn ? gi.getter(r) : r[gi.getter];
        group = groupsByVal[val];
        if (group != null) {
          group = new Group();
          group.value = val;
          group.level = level;
          group.groupingKey = (parentGroup != null ? parentGroup.groupingKey + groupingDelimiter : '') + val;
          groups[groups.length] = group;
          groupsByVal[val] = group;
        }

        group.rows[group.count++] = r;
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

    void calculateTotals(GroupTotals totals) {
      Group group = totals.group;
      GroupingInfo gi = groupingInfos[group.level];
      bool isLeafLevel = (group.level == groupingInfos.length);
      Aggregator agg;
      int idx = gi.aggregators.length;

      if (!isLeafLevel && gi.aggregateChildGroups) {
        // make sure all the subgroups are calculated
        int i = group.groups.length;
        while (i-- > 0) {
          if (!group.groups[i].initialized) {
            calculateTotals(group.groups[i]);
          }
        }
      }

      while (idx-- > 0) {
        agg = gi.aggregators[idx];
        agg.init();
        if (!isLeafLevel && gi.doAggregateChildGroups) {
          gi.compiledAccumulators[idx].call(agg, group.groups);
        } else {
          gi.compiledAccumulators[idx].call(agg, group.rows);
        }
        agg.storeResult(totals);
      }
      totals.isInitialized = true;
    }

    void addGroupTotals(Group group) {
      GroupingInfo gi = groupingInfos[group.level];
      GroupTotals totals = new GroupTotals();
      totals.group = group;
      group.totals = totals;
      if (!gi.isLazyTotalsCalculation) {
        calculateTotals(totals);
      }
    }

    void addTotals(List<Group> groups, [int level]) {
      level = level != null ? level : 0;
      GroupingInfo gi = groupingInfos[level];
      bool groupCollapsed = gi.isCollapsed;
      var toggledGroups = toggledGroupsByLevel[level];
      int idx = groups.length;
      Group g;
      while (idx-- > 0) {
        g = groups[idx];

        if (g.isCollapsed && !gi.doAggregateCollapsed) {
          continue;
        }

        // Do a depth-first aggregation so that parent group aggregators can access subgroup totals.
        if (g.groups != null) {
          addTotals(g.groups, level + 1);
        }

        if (gi.aggregators.length && (
            gi.doAggregateEmpty || g.rows.length || (g.groups && g.groups.length))) {
          addGroupTotals(g);
        }

        g.isCollapsed = groupCollapsed ^ toggledGroups[g.groupingKey]; // TODO ^
        g.title = gi.formatter != null ? gi.formatter(g) : g.value;
      }
    }

    Lits<Group> flattenGroupedRows(List<Group>groups, [int level]) {
      level = level != null ? level : 0;
      GroupingInfo gi = groupingInfos[level];
      List<Group> groupedRows = [];
      List<Group>rows;
      int gl = 0;
      Group g;
      for (int i = 0; i < groups.length; i++) {
        g = groups[i];
        groupedRows[gl++] = g;

        if (!g.isCollapsed) {
          rows = g.groups != null ? flattenGroupedRows(g.groups, level + 1) : g.rows;
          for (int j = 0; j < rows.length; j++) {
            groupedRows[gl++] = rows[j];
          }
        }

        if (g.totals != null && gi.isDisplayTotalsRow && (!g.isCollapsed || gi.doAggregateCollapsed)) {
          groupedRows[gl++] = g.totals;
        }
      }
      return groupedRows;
    }

    FunctionInfo getFunctionInfo(Function fn) {
      var fnRegex = new RegExp(r'^function[^(]*\(([^)]*)\)\s*{([\s\S]*)}$');
      List<Match> matches = fn.toString().match(fnRegex);
      return new FunctionInfo(        matches[1].split(","),        matches[2]      );
    }

    Function compileAccumulatorLoop(Aggregator aggregator) {
      var accumulatorInfo = getFunctionInfo(aggregator.accumulate);
//      var fn = new Function(
//          "_items",
//          "for (var " + accumulatorInfo.params[0] + ", _i=0, _il=_items.length; _i<_il; _i++) {" +
//              accumulatorInfo.params[0] + " = _items[_i]; " +
//              accumulatorInfo.body +
//          "}"
//      );
//      fn.displayName = fn.name = "compiledAccumulatorLoop";
//      return fn;
    }

    Function compileFilter() {
      var filterInfo = getFunctionInfo(filter);

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

      var fn = new Function("_items,_args", tpl);
      fn.displayName = fn.name = "compiledFilter";
      return fn;
    }

    Function compileFilterWithCaching() {
      var filterInfo = getFunctionInfo(filter);

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

      var fn = new Function("_items,_args,_cache", tpl);
      fn.displayName = fn.name = "compiledFilterWithCaching";
      return fn;
    }

    List<int> uncompiledFilter(List<int>items, String args) {
      List<int> retval = [];
      int idx = 0;

      for (final i = 0; i < items.length; i++) {
        if (filter(items[i], args)) {
          retval[idx++] = items[i];
        }
      }

      return retval;
    }

    List<int> uncompiledFilterWithCaching(List<int>items, String args, String cache) {
      List<int> retval = [];
      int idx = 0;
      String item;

      for (final i = 0; i < items.length; i++) {
        item = items[i];
        if (cache[i]) {
          retval[idx++] = item;
        } else if (filter(item, args)) {
          retval[idx++] = item;
          cache[i] = true;
        }
      }

      return retval;
    }

    Map<int,List<int>> getFilteredAndPagedItems(List<int> items) {
      if (filter != null) {
        var batchFilter = options.inlineFilters ? compiledFilter : uncompiledFilter;
        var batchFilterWithCaching = options.inlineFilters ? compiledFilterWithCaching : uncompiledFilterWithCaching;

        if (refreshHints.isFilterNarrowing) {
          filteredItems = batchFilter(filteredItems, filterArgs);
        } else if (refreshHints.isFilterExpanding) {
          filteredItems = batchFilterWithCaching(items, filterArgs, filterCache);
        } else if (!refreshHints.isFilterUnchanged) {
          filteredItems = batchFilter(items, filterArgs);
        }
      } else {
        // special case:  if not filtering and not paging, the resulting
        // rows collection needs to be a copy so that changes due to sort
        // can be caught
        filteredItems = pagesize != null ? items : items.concat();
      }

      // get the current page
      List<int> paged;
      if (pagesize != null) {
        if (filteredItems.length < pagenum * pagesize) {
          pagenum = (filteredItems.length / pagesize).floor();
        }
        paged = filteredItems.slice(pagesize * pagenum, pagesize * pagenum + pagesize);
      } else {
        paged = filteredItems;
      }

      return {totalRows: filteredItems.length, rows: paged};
    }

    List<int> getRowDiffs(List<int>rows, List<int>newRows) {
      String item;
      String r;
      String eitherIsNonData;
      List<int> diff = [];
      int from = 0, to = newRows.length;

      if (refreshHints && refreshHints.ignoreDiffsBefore) {
        from = math.max(0,
            math.min(newRows.length, refreshHints.ignoreDiffsBefore));
      }

      if (refreshHints && refreshHints.ignoreDiffsAfter) {
        to = math.min(newRows.length,
            math.max(0, refreshHints.ignoreDiffsAfter));
      }

      final rl = rows.length;
      for (final i = from; i < to; i++) {
        if (i >= rl) {
          diff[diff.length] = i;
        } else {
          item = newRows[i];
          r = rows[i];

          if ((groupingInfos.length && (eitherIsNonData = (item  is NonDataRow) || (r is NonDataRow)) &&
              item is Group != r is Group ||
              item is Group && item != r)
              || (eitherIsNonData &&
              // no good way to compare totals since they are arbitrary DTOs
              // deep object comparison is pretty expensive
              // always considering them 'dirty' seems easier for the time being
              (item is GroupTotals || r is GroupTotals))
              || item[idProperty] != r[idProperty]
              || (updated && updated[item[idProperty]])
              ) {
            diff[diff.length] = i;
          }
        }
      }
      return diff;
    }

    List<int> recalc(List<int>_items) {
      rowsById = null;

      if (refreshHints.isFilterNarrowing != prevRefreshHints.isFilterNarrowing ||
          refreshHints.isFilterExpanding != prevRefreshHints.isFilterExpanding) {
        filterCache = [];
      }

      var filteredItems = getFilteredAndPagedItems(_items);
      totalRows = filteredItems.totalRows;
      List<int> newRows = filteredItems.rows;

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

      List<int> diff = recalc(items /*, filter*/); // pass as direct refs to avoid closure perf hit

      // if the current page is no longer valid, go to last page and recalc
      // we suffer a performance penalty here, but the main loop (recalc) remains highly optimized
      if (pagesize != null && totalRows < pagenum * pagesize) {
        pagenum = math.max(0, (totalRows / pagesize).ceil() - 1);
        diff = recalc(items /*, filter*/);
      }

      updated = null;
      prevRefreshHints = refreshHints;
      refreshHints = {};

      if (totalRowsBefore != totalRows) {
        EVENT_BUS.fire(Events.pagingInfoChanged, new EventData(sender: this, details: {'pagingInfo': getPagingInfo()}));
        //onPagingInfoChanged.notify(getPagingInfo(), null, self);
      }
      if (countBefore != rows.length) {
        EVENT_BUS.fire(Events.rowCountChanged, new EventData(sender: this, details: {'previous': countBefore, 'current': rows.length}));
        //onRowCountChanged.notify({previous: countBefore, current: rows.length}, null, self);
      }
      if (diff.length > 0) {
        EVENT_BUS.fire(Events.rowsChanged, new EventData(sender: this, detail: {'rows': diff}));
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
    void syncGridSelection(dom.HtmlElement grid, bool preserveHidden, bool preserveHiddenOnSelectionChange) {
      var self = this;
      var inHandler;
      var selectedRowIds = self.mapRowsToIds(grid.getSelectedRows());
      var onSelectedRowIdsChanged = new Event();

      void setSelectedRowIds(rowIds) {
        if (selectedRowIds.join(",") == rowIds.join(",")) {
          return;
        }

        selectedRowIds = rowIds;

        onSelectedRowIdsChanged.notify({
          "grid": grid,
          "ids": selectedRowIds
        }, new EventData(), self);
      }

      void update(e) {
        if (selectedRowIds.length > 0) {
          inHandler = true;
          var selectedRows = self.mapIdsToRows(selectedRowIds);
          if (!preserveHidden) {
            setSelectedRowIds(self.mapRowsToIds(selectedRows));
          }
          grid.setSelectedRows(selectedRows);
          inHandler = false;
        }
      }

      grid.onSelectedRowsChanged.subscribe((e, args) {
        if (inHandler) { return; }
        var newSelectedRowIds = self.mapRowsToIds(grid.getSelectedRows());
        if (!preserveHiddenOnSelectionChange || !grid.getOptions().multiSelect) {
          setSelectedRowIds(newSelectedRowIds);
        } else {
          // keep the ones that are hidden
          var existing = $.grep(selectedRowIds, (id) { return self.getRowById(id) == null; });
          // add the newly selected ones
          setSelectedRowIds(existing.concat(newSelectedRowIds));
        }
      });

      EVENT_BUS.onEvent(Events.rowsChanged).listen(update);

      EVENT_BUS.onEvent(Events.rowCountChanged).listen(update);

      return onSelectedRowIdsChanged;
    }

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


      void update() {
        if (hashById) {
          inHandler = true;
          ensureRowsByIdCache();
          Map newHash = {};
          for (final String id in hashById) {
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

      this.onRowsChanged.subscribe(update);

      this.onRowCountChanged.subscribe(update);
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
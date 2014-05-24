part of bwu_dart.bwu_datagrid.dataview;

class Options {
  GroupItemMetadataProvider groupItemMetadataProvider; // TODO type
  bool inlineFilters;

  Options({this.groupItemMetadataProvider : null, this.inlineFilters: false});
}

class GroupingInfo {
  bool getter = null;
  Formatter formatter = null;
  SortComparerFunc comparer = (a, b) => a.value - b.value;
  List predefinedValues = [];
  List<Aggregator> aggregators = [];
  bool doAggregateEmpty = false;
  bool doAggregateCollapsed = false;
  bool doAggregateChildGroups = false;
  bool isCollapsed = false;
  bool isDisplayTotalsRow = true;
  bool isLazyTotalsCalculation = false;

  GroupingInfo({this.getter, this.formatter, this.comparer,
    this.predefinedValues, this.aggregators, this.doAggregateEmpty,
        this.doAggregateCollapsed, this.doAggregateChildGroups, this.isCollapsed,
        this.isDisplayTotalsRow, this.isLazyTotalsCalculation});
}

class Args {
  int pageSize = 0;
}

class PagingInfo {
  int pageSize;
  int pageNum;
  int totalRows;
  int totalPages;

  PagingInfo({this.pageSize, this.pageNum, this.totalRows, this.totalPages});
}

class FunctionInfo {
  List<String> params;
  String body;

  FunctionInfo(this.params, this.body);
}


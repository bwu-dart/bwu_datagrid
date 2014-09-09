part of bwu_dart.bwu_datagrid.dataview;

class DataViewOptions {
  GroupItemMetadataProvider groupItemMetadataProvider; // TODO type
  bool inlineFilters;

  DataViewOptions({this.groupItemMetadataProvider : null, this.inlineFilters: false});
}

typedef int SortComparerFunc(a, b);

class GroupingInfo {
  var getter;
  bool getterIsAFn = false;
  core.GroupTitleFormatter formatter;
  SortComparerFunc comparer;
  List predefinedValues;
  List<Aggregator> aggregators;
  bool doAggregateEmpty;
  bool doAggregateCollapsed;
  bool doAggregateChildGroups;
  bool isCollapsed;
  bool isDisplayTotalsRow;
  bool isLazyTotalsCalculation;

  GroupingInfo({this.getter, this.formatter, this.comparer,
    this.predefinedValues, this.aggregators, this.doAggregateEmpty : false,
        this.doAggregateCollapsed : false, this.doAggregateChildGroups : false, this.isCollapsed : false,
        this.isDisplayTotalsRow : true, this.isLazyTotalsCalculation: false}) {
    if(predefinedValues == null) predefinedValues = [];
    if(aggregators == null) aggregators = [];
    if(comparer == null) comparer = (a, b) {
      if(a.value is bool && b.value is bool) {
        return (a.value ? 1 : 0) - (b.value ? 1 : 0);
      }
      if(a.value is String) {
        return (a.value as String).compareTo('${b.value}');
      }
      if(a.value == null) {
        return b.value == null ? 0 : -1;
      }
      return a.value - b.value;
    };
  }
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


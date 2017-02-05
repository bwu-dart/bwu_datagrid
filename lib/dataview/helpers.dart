part of bwu_datagrid.dataview;

class DataViewOptions {
  GroupItemMetadataProvider groupItemMetadataProvider; // TODO type
  bool inlineFilters;

  DataViewOptions(
      {this.groupItemMetadataProvider: null, this.inlineFilters: false});
}

typedef int SortComparerFunc<T>(T a, T b);

class GroupingInfo {
  Object getter;
  bool getterIsAFn = false;
  fm.GroupTitleFormatter formatter;
  SortComparerFunc<core.ItemBase> comparer;
  List<Object> predefinedValues;
  List<Aggregator> aggregators;
  bool doAggregateEmpty;
  bool doAggregateCollapsed;
  bool doAggregateChildGroups;
  bool isCollapsed;
  bool isDisplayTotalsRow;
  bool isLazyTotalsCalculation;

  GroupingInfo(
      {this.getter,
      this.formatter,
      this.comparer,
      this.predefinedValues,
      this.aggregators,
      this.doAggregateEmpty: false,
      this.doAggregateCollapsed: false,
      this.doAggregateChildGroups: false,
      this.isCollapsed: false,
      this.isDisplayTotalsRow: true,
      this.isLazyTotalsCalculation: false}) {
    if (predefinedValues == null) predefinedValues = <Object>[];
    if (aggregators == null) aggregators = <Aggregator>[];
    if (comparer == null)
      comparer = (core.ItemBase a, core.ItemBase b) {
      if (a['value'] is bool && b['value'] is bool) {
        return (a['value'] != null ? 1 : 0) - (b['value'] != null ? 1 : 0);
      }
      if (a['value'] is String) {
        return (a['value'] as String).compareTo('${b['value']}');
      }
      if (a['value'] == null) {
        return b['value'] == null ? 0 : -1;
      }
      return (a['value'] as int) - (b['value'] as int);
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

part of bwu_dart.bwu_datagrid.dataview;

abstract class Aggregator {
  void init();
  void storeResult(GroupTotals groupTotals);
  void accumulate(String item);
}

class AvgAggregator extends Aggregator {
  int _field;

  int _count = 0;
  int _nonNullCount = 0;
  double _sum = 0.0;

  AvgAggregator(this._field);

  @override
  void accumulate(String item) {
    var val = item[_field];
    _count++;
    if (val != null && val != '' && val is num) {
      _nonNullCount++;
      _sum += double.parse(val);
    }
  }

  @override
  void storeResult (GroupTotals groupTotals) {
    if (groupTotals.avg == null) {
      groupTotals.avg = {};
    }
    if (_nonNullCount != 0) {
      groupTotals.avg[_field] = _sum / _nonNullCount;
    }
  }
}

class MinAggregator extends Aggregator{
  int _field;
  double _min;
  MinAggregator(this._field);

  @override
  void accumulate(String item) {
    num val = item[_field];
    if (val != null && val != '' && val is num) {
      if (_min == null || val < _min) {
        _min = val;
      }
    }
  }

  @override
  void storeResult(GroupTotals groupTotals) {
    if (groupTotals.min == null) {
      groupTotals.min = {};
    }
    groupTotals.min[_field] = _min;
  }
}

class MaxAggregator extends Aggregator{
  int _field;
  double _max;
  MaxAggregator(this._field);

  @override
  void accumulate(String item) {
    num val = item[_field];
    if (val != null && val != '' && val is num) {
      if (_max == null || val > _max) {
        _max = val;
      }
    }
  }

  @override
  void storeResult(GroupTotals groupTotals) {
    if (groupTotals.max == null) {
      groupTotals.max = {};
    }
    groupTotals.max[_field] = _max_;
  }
}

class SumAggregator extends Aggregator{
  int _field;
  double _sum;
  SumAggregator(this._field) {

    @override
  void accumulate(String item) {
    num val = item[_field];
    if (val != null && val != '' && val is double) {
      _sum += double.parse(val);
    }
  };

  @override
  void storeResult(GroupTotals groupTotals) {
    if (groupTotals.sum == null) {
      groupTotals.sum = {};
    }
    groupTotals.sum[_field] = _sum;
  }
}

// TODO:  add more built-in aggregators
// TODO:  merge common aggregators in one to prevent needles iterating
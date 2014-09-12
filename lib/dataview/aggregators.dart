part of bwu_dart.bwu_datagrid.dataview;

abstract class Aggregator {
  void init();
  void storeResult(core.GroupTotals groupTotals);
  void accumulate(core.ItemBase item);
  bool _isCalculated = false;
  void call(List<core.ItemBase> rows) {
    if(rows != null) {
      rows.forEach((r) => accumulate(r));
    }
    _isCalculated = true;
  }
}

class AvgAggregator extends Aggregator {
  String _field;

  int _count = 0;
  int _nonNullCount = 0;
  num _sum = 0.0;

  AvgAggregator(this._field);

  @override
  void init() {
    _count = 0;
    _nonNullCount = 0;
    _sum= 0;
  }

  @override
  void accumulate(core.ItemBase item) {
    var val = item[_field];
    _count++;
    if (val != null) {
      _nonNullCount++;
      if(val is String && val.isNotEmpty) {
      _sum += double.parse(val);
      } else if(val is num) {
        _sum += val;
      }
    }
  }

  @override
  void storeResult(core.GroupTotals groupTotals) {
    if (groupTotals['avg'] == null) {
      groupTotals['avg'] = {};
    }
    if (_nonNullCount != 0) {
      groupTotals['avg'][_field] = _sum / _nonNullCount;
    }
  }
}

class MinAggregator extends Aggregator {
  String _field;
  double _min;
  MinAggregator(this._field);

  @override
  void init() {
    _min = null;
  }

  @override
  void accumulate(core.ItemBase item) {
    num val = item[_field];
    if (val != null && val != '' && val is num) {
      if (_min == null || val < _min) {
        _min = val;
      }
    }
  }

  @override
  void storeResult(core.GroupTotals groupTotals) {
    if (groupTotals['min'] == null) {
      groupTotals['min'] = {};
    }
    groupTotals['min'][_field] = _min;
  }
}

class MaxAggregator extends Aggregator {
  String _field;
  double _max;
  MaxAggregator(this._field);

  @override
  void init() {
    _max = null;
  }

  @override
  void accumulate(core.ItemBase item) {
    num val = item[_field];
    if (val != null && val != '' && val is num) {
      if (_max == null || val > _max) {
        _max = val;
      }
    }
  }

  @override
  void storeResult(core.GroupTotals groupTotals) {
    if (groupTotals['max'] == null) {
      groupTotals['max'] = {};
    }
    groupTotals['max'][_field] = _max;
  }
}

class SumAggregator extends Aggregator {
  String _field;
  double _sum = 0.0;
  SumAggregator(this._field);

  @override
  void init() {
    _sum = 0.0;
  }

  @override
  void accumulate(core.ItemBase item) {
    var val = item[_field];
    if (val != null) {
      if(val is String && val.isNotEmpty){
        _sum += double.parse(val);
      } else if(val is num) {
        _sum += val;
      }
    }
  }

  @override
  void storeResult(core.GroupTotals groupTotals) {
    if (groupTotals['sum'] == null) {
      groupTotals['sum'] = {};
    }
    groupTotals['sum'][_field] = _sum;
  }
}

// TODO:  add more built-in aggregators
// TODO:  merge common aggregators in one to prevent needles iterating

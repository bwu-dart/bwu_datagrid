library bwu_datagrid.datagrid.bwu_datagrid_header_column;

import 'package:polymer/polymer.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';

@CustomTag('bwu-datagrid-header-column')
class BwuDatagridHeaderColumn extends PolymerElement {
  BwuDatagridHeaderColumn.created() : super.created();

  Column column;
}
library bwu_datagrid.datagrid.bwu_datagrid_headerrow_column;

import 'package:polymer/polymer.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';

@CustomTag('bwu-datagrid-headerrow-column')
class BwuDatagridHeaderrowColumn extends PolymerElement {
  BwuDatagridHeaderrowColumn.created() : super.created();

  Column column;
}
library bwu_datagrid.datagrid.bwu_datagrid_headers;

import 'package:polymer/polymer.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';

@CustomTag('bwu-datagrid-headers')
class BwuDatagridHeaders extends PolymerElement {
  BwuDatagridHeaders.created() : super.created();

  Filter filter;
  Sortable sortable;
}
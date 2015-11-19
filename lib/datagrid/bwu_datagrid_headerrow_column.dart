@HtmlImport('bwu_datagrid_headerrow_column.html')
library bwu_datagrid.datagrid.bwu_datagrid_headerrow_column;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;
import 'package:bwu_datagrid/datagrid/helpers.dart';

@PolymerRegister('bwu-datagrid-headerrow-column')
class BwuDatagridHeaderrowColumn extends PolymerElement {
  BwuDatagridHeaderrowColumn.created() : super.created();

  Column column;
}

@HtmlImport('bwu_datagrid_header_column.html')
library bwu_datagrid.datagrid.bwu_datagrid_header_column;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;
import 'package:bwu_datagrid/datagrid/helpers.dart';

@PolymerRegister('bwu-datagrid-header-column')
class BwuDatagridHeaderColumn extends PolymerElement {
  BwuDatagridHeaderColumn.created() : super.created();

  Column column;
}

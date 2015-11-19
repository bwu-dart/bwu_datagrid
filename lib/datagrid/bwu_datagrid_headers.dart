@HtmlImport('bwu_datagrid_headers.html')
library bwu_datagrid.datagrid.bwu_datagrid_headers;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;
import 'package:bwu_datagrid/effects/sortable.dart';

@PolymerRegister('bwu-datagrid-headers')
class BwuDatagridHeaders extends PolymerElement {
  BwuDatagridHeaders.created() : super.created();

  //Filter filter;
  Sortable sortable;
}

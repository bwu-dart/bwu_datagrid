@HtmlImport('row_item.html')
library bwu_datagrid_examples.e04_model.filter_form;

import 'dart:html' as dom;
import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;
import 'package:bwu_datagrid/datagrid/helpers.dart';

@PolymerRegister('row-item')
class RowItem extends PolymerElement {
  factory RowItem() => new dom.Element.tag('row-item') as RowItem;

  RowItem.created() : super.created();

  set data(MapDataItem d) {
    d.keys.forEach((String e) {
      ($[e] as dom.Element).text = d[e];
    });
  }
}

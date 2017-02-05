@HtmlImport('row_item.html')
library bwu_datagrid_examples.e04_model.filter_form;

import 'dart:html' as dom;
import 'package:bwu_datagrid/core/core.dart' show ItemBase;
import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

@PolymerRegister('row-item')
class RowItem extends PolymerElement {
  factory RowItem() => new dom.Element.tag('row-item') as RowItem;

  RowItem.created() : super.created();

  @property
  String name;
  @property
  String titlex;
  @property
  String email;
  @property
  String phone;

  set data(ItemBase d) {
    async(() {
      d.keys.forEach((k) {
        set(k as String != 'title' ? k as String : 'titlex', d[k]);
      });
    });
  }
}

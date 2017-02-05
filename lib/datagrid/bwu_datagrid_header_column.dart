@HtmlImport('bwu_datagrid_header_column.html')
library bwu_datagrid.datagrid.bwu_datagrid_header_column;

import 'dart:html' as dom;
import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;
import 'package:bwu_datagrid/datagrid/helpers.dart' show Column;

@PolymerRegister('bwu-datagrid-header-column')
class BwuDatagridHeaderColumn extends PolymerElement {
  factory BwuDatagridHeaderColumn() =>
      new dom.Element.tag('bwu-datagrid-header-column')
      as BwuDatagridHeaderColumn;
  BwuDatagridHeaderColumn.created() : super.created();

  Column column;

  static const String defaultThemeName = 'bwu-datagrid-default-theme';

  /// The actually used theme name is [theme] + '-header-column'.
  @Property(observer: 'themeChanged')
  String theme = defaultThemeName;

  @reflectable
  void themeChanged(String newValue, String oldValue) {
    PolymerDom root = new PolymerDom(this.root);
    root
        .querySelectorAll('[bwu-datagrid-theme]')
        .forEach((dom.Element e) => root.removeChild(e));
    root.insertBefore(
        new dom.Element.tag('style', 'custom-style')
          ..attributes['bwu-datagrid-theme'] = newValue
          ..attributes['include'] =
              (newValue ?? defaultThemeName) + '-column-header',
        $['theme-placeholder'] as dom.Node);
//    updateStyles();
    PolymerDom.flush();
  }
}

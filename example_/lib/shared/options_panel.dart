@HtmlImport('options_panel.html')
library bwu_datagrid_examples.shared.options_panel;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

@PolymerRegister('options-panel')
class OptionsPanel extends PolymerElement {
  // TODO(zoechi) update branch name for release
  static const String _branch = 'polymer1';

  OptionsPanel.created() : super.created();

  @property
  String sourceDir;

  @reflectable
  String gitHubSourceUri(String sourceDir) =>
      'https://github.com/bwu-dart/bwu_datagrid/tree/${_branch}/example_/lib/${sourceDir}';
}

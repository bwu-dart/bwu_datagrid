library bwu_datagrid_examples.test.common;

//import 'package:webdriver/io.dart' as wd;
import 'dart:io' as io;
import 'dart:async' show Future;
import 'package:webdriver/io.dart' as wd;
import 'package:bwu_webdriver/bwu_webdriver.dart';
import 'package:bwu_webdriver/firefox.dart';
import 'package:test/test.dart';

const int pubServePort = 21234;

Future<String> get webServer async =>
    'http://${await pubServeIp}:${pubServePort}';

Future<String> get pubServeIp async {
  const List<String> prioritize = const <String>['eth0', 'eth1', 'wlan0'];
  const List<String> ignoreList = const <String>['docker0'];
  String ip = io.Platform.environment['PUB_SERVE_IP'];
  if (ip == null) {
    ip = (await io.NetworkInterface.list())
        .where((io.NetworkInterface ni) => !ignoreList.contains(ni.name))
        .reduce((io.NetworkInterface n1, io.NetworkInterface n2) =>
            prioritize.indexOf(n1.name) >= prioritize.indexOf(n2.name)
                ? n1
                : n2)
        .addresses
        .first
        .address;
    print('Environment variable "PUB_SERVE_IP" is not set.');
  }
  print('Ip "${ip}" is used to access "pub serve" from the Selenium nodes.');
  return ip;
}

//const server = 'http://webserver:21234';
//final server = io.Platform.environment['PUB_SERVE_URL'] != null
//    ? io.Platform.environment['PUB_SERVE_URL']
//    : throw '"PUB_SERVE_URL" is not set. It needs to point to an url '
//    'accessible from within Docker containers. Example '
//    '"export PUB_SERVE_URL=http://192.168.1.1:21234".';

const String gridCellSelectorBase =
    'app-element::shadow #myGrid::shadow #viewport #canvas div.bwu-datagrid-row div.bwu-datagrid-cell.l';
const String gridCellSelectorBaseNoShadow =
    'app-element > #myGrid > #viewport #canvas div.bwu-datagrid-row div.bwu-datagrid-cell.l';

const By viewPortSelector =
    const By.shadow('app-element::shadow #myGrid::shadow #viewport');
const By firstColumnSelector = const By.shadow('${gridCellSelectorBase}0');

const String gridActiveRowCellSelectorBase =
    'app-element::shadow #myGrid::shadow div.bwu-datagrid-row.active div.bwu-datagrid-cell.l';
const By titleCellActiveRowSelector =
    const By.shadow('${gridActiveRowCellSelectorBase}0');
const By descriptionCellActiveRowSelector =
    const By.shadow('${gridActiveRowCellSelectorBase}1');
// e03a_compound_editors
const By rangeCellActiveRowSelector =
    const By.shadow('${gridActiveRowCellSelectorBase}1');
const By durationCellActiveRowSelector =
    const By.shadow('${gridActiveRowCellSelectorBase}2');
const By percentCellActiveRowSelector =
    const By.shadow('${gridActiveRowCellSelectorBase}3');

const By percentCellActiveRowPercentBarSelector = const By.shadow(
    '${gridActiveRowCellSelectorBase}3 span.percent-complete-bar');

const By startCellActiveRowSelector =
    const By.shadow('${gridActiveRowCellSelectorBase}4');
const By finishCellActiveRowSelector =
    const By.shadow('${gridActiveRowCellSelectorBase}5');
const By effortDrivenCellActiveRowSelector =
    const By.shadow('${gridActiveRowCellSelectorBase}6');
const By effortDrivenCellActiveRowCheckedSelector = const By.shadow(
    '${gridActiveRowCellSelectorBase}6 img[src="packages/bwu_datagrid/asset/images/tick.png"]');

const By effortDrivenCheckedImageSelector = const By.cssSelector(
    'img[src="packages/bwu_datagrid/asset/images/tick.png"]');

typedef dynamic BrowserTest(WebBrowser browser);

void forEachBrowser(BrowserTest testsWithBrowser) {
  group('Chrome,',
      () => testsWithBrowser(WebBrowser.chrome) /*, skip: 'temporary'*/);
  group('Chrome (Android),',
      () => testsWithBrowser(WebBrowser.chrome) /*, skip: 'temporary'*/);
  group(
      'Firefox,',
      () => testsWithBrowser(WebBrowser
          .firefox) /*,
      skip: 'blocked by FirefoxDriver issue - s'*/
      );
  group('Edge,', () => testsWithBrowser(WebBrowser.edge),
      skip: 'blocked by driver limitations (too many missing features)');
  group('IE,', () => testsWithBrowser(WebBrowser.ie),
      skip: 'blocked by driver limitations (wasn\'t able to find an element');

  // https://github.com/SeleniumHQ/selenium/issues/939 // closed because in FF 4.0.3 shadow DOM is disabled
  // https://github.com/SeleniumHQ/selenium/issues/940
}

final Map<WebBrowser, Map<String, dynamic>> _defaultBrowserCapabilities =
    <WebBrowser, Map<String, dynamic>>{
  WebBrowser.android: wd.Capabilities.chrome
    ..['chromeOptions'] = <String, String>{
      'androidPackage': 'com.android.chrome'
    },
  WebBrowser.chrome: wd.Capabilities.chrome,
  WebBrowser.edge: <String, String>{'browserName': WebBrowser.edge.value},
  WebBrowser.firefox: wd.Capabilities.firefox
    ..addAll((new FirefoxProfile()
          ..setOption(new PrefsOption<int>('devtools.selfxss.count', 100)))
        .toJson() as Map<String, dynamic>), // disable paste protection
  WebBrowser.ie: <String, String>{'browserName': WebBrowser.ie.value},
  WebBrowser.ipad: <String, String>{'browserName': WebBrowser.ipad.value},
  WebBrowser.iphone: <String, String>{'browserName': WebBrowser.iphone.value},
  WebBrowser.safari: <String, String>{'browserName': WebBrowser.safari.value},
};

Future<ExtendedWebDriver> commonSetUp(
    String pageUrl, WebBrowser browser) async {
  // for capabilities see https://code.google.com/p/selenium/wiki/DesiredCapabilities
  final Map<String, dynamic> desired = _defaultBrowserCapabilities[browser];
  final ExtendedWebDriver driver = await ExtendedWebDriver.createNew(
      uri: Uri.parse('http://localhost:4444/wd/hub/'), desired: desired);
  await driver.timeouts.setScriptTimeout(const Duration(milliseconds: 1500));
//  await driver.timeouts.setPageLoadTimeout(const Duration(seconds: 90));
//  await driver.timeouts.setImplicitTimeout(const Duration(seconds: 300));

  //      print('Capabilities: ${driver.capabilities}');
  await driver.get(pageUrl);
  expect(await driver.currentUrl, pageUrl);
  await new Future<Null>.delayed(const Duration(milliseconds: 100));
  return driver;
}

library bwu_datagrid_examples.test.common;

//import 'package:webdriver/io.dart' as wd;
import 'dart:async' show Future;
import 'package:bwu_webdriver/bwu_webdriver.dart';
import 'package:test/test.dart';

const server = 'http://webserver:8080';
const gridCellSelectorBase =
    'app-element::shadow #myGrid::shadow #viewport #canvas div.bwu-datagrid-row div.bwu-datagrid-cell.l';

const viewPortSelector =
    const By.cssSelector('app-element::shadow #myGrid::shadow #viewport');
const firstColumnSelector = const By.cssSelector('${gridCellSelectorBase}0');

const gridActiveRowCellSelectorBase =
    'app-element::shadow #myGrid::shadow div.bwu-datagrid-row.active div.bwu-datagrid-cell.l';
const titleCellActiveRowSelector =
    const By.cssSelector('${gridActiveRowCellSelectorBase}0');
const descriptionCellActiveRowSelector =
    const By.cssSelector('${gridActiveRowCellSelectorBase}1');
const durationCellActiveRowSelector =
    const By.cssSelector('${gridActiveRowCellSelectorBase}2');
const percentCellActiveRowSelector =
    const By.cssSelector('${gridActiveRowCellSelectorBase}3');

const percentCellActiveRowPercentBarSelector = const By.cssSelector(
    '${gridActiveRowCellSelectorBase}3 span.percent-complete-bar');

const startCellActiveRowSelector =
    const By.cssSelector('${gridActiveRowCellSelectorBase}4');
const finishCellActiveRowSelector =
    const By.cssSelector('${gridActiveRowCellSelectorBase}5');
const effortDrivenCellActiveRowSelector =
    const By.cssSelector('${gridActiveRowCellSelectorBase}6');
const effortDrivenCellActiveRowCheckedSelector = const By.cssSelector(
    '${gridActiveRowCellSelectorBase}6 img[src="packages/bwu_datagrid/asset/images/tick.png"]');

const effortDrivenCheckedImageSelector = const By.cssSelector(
    'img[src="packages/bwu_datagrid/asset/images/tick.png"]');

Future<ExtendedWebDriver> commonSetUp(
    String pageUrl, WebBrowser browser) async {
  // for capabilities see https://code.google.com/p/selenium/wiki/DesiredCapabilities
  final driver = await ExtendedWebDriver.createNew(
      uri: Uri.parse('http://localhost:4444/wd/hub/'),
      desired: {'browserName': browser.value});
  await driver.timeouts.setScriptTimeout(const Duration(milliseconds: 1500));
//  await driver.timeouts.setPageLoadTimeout(const Duration(seconds: 90));
//  await driver.timeouts.setImplicitTimeout(const Duration(seconds: 30));

  //      print('Capabilities: ${driver.capabilities}');
  await driver.get(pageUrl);
  expect(await driver.currentUrl, pageUrl);
  await new Future.delayed(const Duration(milliseconds: 100));
  return driver;
}

@TestOn('vm')
library bwu_datagrid_examples.test.autotooltips_test;

import 'dart:async' show Future, Stream;
import 'dart:math' show Point, Rectangle;

import 'package:bwu_webdriver/bwu_webdriver.dart';
import 'package:test/test.dart';
import 'package:webdriver/io.dart';
import 'common.dart';

const pageUrl = '${server}/autotooltips.html';

main() {
  group('Chrome', () => tests(WebBrowser.chrome));
  group('Firefox', () => tests(WebBrowser.firefox),
      skip: 'blocked by FirefoxDriver issue - s');
}

tests(WebBrowser browser) {
  group('autotooltips', () {
    ExtendedWebDriver driver;
    setUp(() async {
      driver = await commonSetUp(pageUrl, browser);
    });

    tearDown(() {
      return driver.close();
    });

    test('load', () async {
//      print(driver.capabilities);
      await driver.get(pageUrl);
      WebElement start = await driver.findElement(
          const By.cssSelector('* /deep/ bwu-datagrid-header-column#start'));
      expect(await start.attributes['id'], 'start');
      int startColumnWidth = (await driver.getBoundingClientRect(start)).width;
      expect(startColumnWidth, 80);
      print('width: ${startColumnWidth}');
      WebElement startResizeHandle = await driver.findElement(const By.cssSelector(
          '* /deep/ bwu-datagrid-header-column#start /deep/ .bwu-datagrid-resizable-handle'));
      expect(startResizeHandle, isNotNull);
      Rectangle bounds = await driver.getBoundingClientRect(start);
      print('bounds before: ${bounds}');
      final target = new Point(
          bounds.left + bounds.width ~/ 2, bounds.top + bounds.height ~/ 2);
      // 292-25
      print('target: ${target}');
//      print(await startResizeHandle.attributes['class']);
//      await driver.mouse.moveTo(element: startResizeHandle);
      await driver.dragAndDrop(
          sourceSelector:
              '* /deep/ bwu-datagrid-header-column#start /deep/ .bwu-datagrid-resizable-handle',
          targetSelector: '* /deep/ bwu-datagrid-header-column#start',
          targetLocation: target);
      print('width2: ${await driver.getBoundingClientRect(start)}');
      startColumnWidth = (await driver.getBoundingClientRect(start)).width;

      await new Future.delayed(const Duration(seconds: 150), () {});
      expect(startColumnWidth, lessThan(80));
    });
  },
      timeout: const Timeout(const Duration(seconds: 180)),
      skip: 'drag\'n drop doesn\'t work with webdriver');
}

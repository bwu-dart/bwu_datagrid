@TestOn('vm')
library bwu_datagrid_examples.test.autotooltips_test;

import 'dart:async' show Future, Stream;
import 'dart:math' show Point, Rectangle;

import 'package:bwu_webdriver/bwu_webdriver.dart';
import 'package:test/test.dart';
import 'common.dart';

String pageUrl;

dynamic main() async {
  pageUrl = '${await webServer}/autotooltips.html';
  forEachBrowser(tests);
}

void tests(WebBrowser browser) {
  group('autotooltips', () {
    ExtendedWebDriver driver;
    setUp(() async {
      driver = await commonSetUp(pageUrl, browser);
    });

    tearDown(() {
      return driver?.quit();
    });

    test('load', () async {
//      print(driver.capabilities);
      await driver.get(pageUrl);
      WebElement start = await driver.findElement(
          const By.shadow('* /deep/ bwu-datagrid-header-column#start'));
      expect(await start.attributes['id'], 'start');
      int startColumnWidth = (await start.size).width;
      expect(startColumnWidth, 80);
      print('width: ${startColumnWidth}');
      WebElement startResizeHandle = await driver.findElement(const By.shadow(
          '* /deep/ bwu-datagrid-header-column#start /deep/ .bwu-datagrid-resizable-handle'));
      expect(startResizeHandle, isNotNull);
      Rectangle<int> bounds = await start.size;
      print('bounds before: ${bounds}');
      final Point<int> target = new Point<int>(
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
      print('width2: ${await start.size}'); //.getBoundingClientRect(start)}');
//      print('width2: ${await start.size}'); //.getBoundingClientRect(start)}');
//      startColumnWidth = (await driver.getBoundingClientRect(start)).width;
      startColumnWidth = (await start.size).width;

      await new Future.delayed(const Duration(seconds: 150), () {});
      expect(startColumnWidth, lessThan(80));
    });
  },
      timeout: const Timeout(const Duration(seconds: 180)),
      skip: 'drag\'n drop doesn\'t work with webdriver');
}

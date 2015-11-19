@TestOn('vm')
library bwu_datagrid_examples.test.e02_formatters_test;

import 'dart:async' show Future, Stream;

import 'package:bwu_webdriver/bwu_webdriver.dart';
import 'package:test/test.dart';
import 'common.dart';

String pageUrl;

main() async {
  pageUrl = '${await webServer}/e02_formatters.html';
  forEachBrowser(tests);
}

tests(WebBrowser browser) {
  group('e02_formatters', () {
    ExtendedWebDriver driver;
    setUp(() async {
      driver = await commonSetUp(pageUrl, browser);
    });

    tearDown(() {
      return driver?.quit();
    });

    test('link', () async {
      const linksInFirstColumnSelector =
          const By.shadow('${gridCellSelectorBase}0 a[href="#"]');

      final linksInFirstColumn =
          await driver.findElements(linksInFirstColumnSelector).toList();
      expect(linksInFirstColumn.length, 5);
      for (final link in linksInFirstColumn) {
        expect(await link.text, 'Task');
      }
    });

    test('percentCompleteBar', () async {
      const barsInPercentCompleteColumnSelector =
          const By.shadow('${gridCellSelectorBase}2 span.percent-complete-bar');

      final barsInPercentCompleteColumn = await driver
          .findElements(barsInPercentCompleteColumnSelector)
          .toList();
      expect(barsInPercentCompleteColumn.length, 5);
      for (final bar in barsInPercentCompleteColumn) {
        expect(await bar.attributes['style'], matches(r'width: \d{1,3}%;'));
      }
    });

    test('checkMark', () async {
      const checkMarksInEffortDrivenColumnSelector = const By.shadow(
          '${gridCellSelectorBase}5 img[src="packages/bwu_datagrid/asset/images/tick.png"]');

      final checkMarkInEffortDrivenColumn = await driver
          .findElements(checkMarksInEffortDrivenColumnSelector)
          .toList();
      expect(checkMarkInEffortDrivenColumn.length, 1);
    });
  }, timeout: const Timeout(const Duration(seconds: 180)));
}

Future<bool> isTaskShown(ExtendedWebDriver driver, int number) {
  return driver
      .findElements(firstColumnSelector)
      .asyncMap(
          (e) async => await e.text == 'Task ${number}' && await e.displayed)
      .contains(true);
}

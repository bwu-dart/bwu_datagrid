@TestOn('vm')
library bwu_datagrid_examples.test.e01_simple_test;

import 'dart:async' show Future, Stream;

import 'package:bwu_webdriver/bwu_webdriver.dart';
import 'package:test/test.dart';
import 'package:webdriver/io.dart';
import 'common.dart';

const pageUrl = '${server}/e01_simple.html';

main() {
  group('Chrome', () => tests(WebBrowser.chrome));
  group('Firefox', () => tests(WebBrowser.firefox),
      skip: 'blocked by FirefoxDriver issue - s');
// https://github.com/SeleniumHQ/selenium/issues/939
// https://github.com/SeleniumHQ/selenium/issues/940
}

tests(WebBrowser browser) {
  group('e01_simple', () {
    ExtendedWebDriver driver;
    setUp(() async {
      driver = await commonSetUp(pageUrl, browser);
    });

    tearDown(() {
      return driver.close();
    });

    test('scroll', () async {
      WebElement viewPort = await driver.findElement(viewPortSelector);
      expect(viewPort, isNotNull);
      final maxYScroll = int.parse(await viewPort.attributes['scrollHeight']);
      expect(maxYScroll, greaterThan(12000));

      await new Future.delayed(const Duration(milliseconds: 100));

      expect(await isTaskShown(driver, 0), isTrue);
      expect(await isTaskShown(driver, 499), isFalse);

      await driver.scrollElementAbsolute(viewPort, y: maxYScroll);

      await new Future.delayed(const Duration(milliseconds: 100));

      expect(await isTaskShown(driver, 0), isFalse);
      expect(await isTaskShown(driver, 499), isTrue);

      await driver.scrollElementAbsolute(viewPort, y: 0);

      expect(await isTaskShown(driver, 0), isTrue);
      // this element is still contained in the DOM
      // expect(await isTaskShown(driver, 499), isFalse);

      await driver.scrollElementAbsolute(viewPort, y: maxYScroll ~/ 2);
      await new Future.delayed(const Duration(milliseconds: 100));

      expect(await isTaskShown(driver, 250), isTrue);
//      await new Future.delayed(const Duration(seconds: 200));
    });
  }, timeout: const Timeout(const Duration(seconds: 180)));
}

Future<bool> isTaskShown(WebDriver driver, int number) {
  return driver
      .findElements(firstColumnSelector)
      .asyncMap(
          (e) async => await e.text == 'Task ${number}' && await e.displayed)
      .contains(true);
}

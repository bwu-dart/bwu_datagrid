@TestOn('vm')
library bwu_datagrid_examples.test.e07_events_test;

import 'package:bwu_webdriver/bwu_webdriver.dart';
import 'package:test/test.dart';
import 'common.dart';

String pageUrl;

dynamic main() async {
  pageUrl = '${await webServer}/e07_events.html';

  forEachBrowser(tests);
}

// TODO(zoechi)
// - accept with tab

void tests(WebBrowser browser) {
  group('e07_events,', () {
    ExtendedWebDriver driver;
    setUp(() async {
      driver = await commonSetUp(pageUrl, browser);
    });

    tearDown(() {
      return driver?.quit();
    });

    test('filter % complete', () async {
      final WebElement app = await driver
          .findElement(const By.shadow('app-element /deep/ #canvas'));
      final WebElement filterSlider = await driver.findElement(const By.shadow(
          'app-element /deep/ div.options-panel #filter-form /deep/ input#txtSearch'));
      await driver.mouse.moveTo(element: app);
      await driver.mouse.click();
      await driver.mouse.moveTo(element: filterSlider, xOffset: 1, yOffset: 1);
      await driver.mouse.click();
      expect(await filterSlider.attributes['value'], '50');
    });
  },
      timeout: const Timeout(const Duration(seconds: 180)),
      skip: 'temp / unfinished');
}

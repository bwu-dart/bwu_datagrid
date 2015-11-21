@TestOn('vm')
library bwu_datagrid_examples.test.e04_model_test;

import 'package:bwu_webdriver/bwu_webdriver.dart';
import 'package:test/test.dart';
import 'common.dart';

String pageUrl;

dynamic main() async {
  pageUrl = '${await webServer}/e04_model.html';

  forEachBrowser(tests);
}

// TODO(zoechi)
// - accept with tab

void tests(WebBrowser browser) {
  group('e04_model,', () {
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
          '* /deep/ div.options-panel /deep/ input#slider')); //  /deep/ #txtSearch
      await app.click();
//      final filterSlider = await driver.findElement(const By.shadow(
//      'app-element /deep/ bwu-datagrid-header-column#title'));
      print(await filterSlider.location);
//      await driver.mouse.click();
//      await driver.mouse.moveTo(element: filterSlider, xOffset: 1, yOffset: 1);
      await filterSlider.click();
      await driver.mouse.moveTo(element: filterSlider);
      await driver.mouse.click();

      expect(await filterSlider.attributes['value'], '50');
    } /*,
        skip:
            'webdriver issue https://code.google.com/p/chromedriver/issues/detail?id=1049'*/
        );
  }, timeout: const Timeout(const Duration(seconds: 180)));
}

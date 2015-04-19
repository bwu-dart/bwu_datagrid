@Timeout(const Duration(minutes: 5))

import '../util/webdriver.dart' as wd;

import 'dart:async' show Future, Stream;
import 'package:test/test.dart';

main() async {
  wd.DriverFactory wdFactory = wd.createDriverFactory();
  await wdFactory.startFactory();

  wd.WebDriver driver;
  wd.PubServe server;
  group('x', () {
    setUp(() async {
      print('setUp');
      server = new wd.PubServe();
      await server.start(directories: const ['example']);
      driver = await wdFactory.createDriver();
      print('driver = $driver');
    });

    tearDown(() async {
      print('closing driver ${wdFactory}');
      await driver.quit();

      print('closing server');
      server.stop();
      return wdFactory.stopFactory();
    });


    test('', () async {
      final examplePubServePort = server.directoryPorts['example'];
      print('get: http://localhost:${examplePubServePort}/e01_simple.html');
      await driver.get('http://localhost:${examplePubServePort}/e01_simple.html');
      await new Future.delayed(new Duration(seconds: 1), () {});
      String title = await driver.title;
      print('title: $title');
      expect(title, startsWith('BWU Datagrid example 01: Basic grid'));
    }, timeout: const Timeout(const Duration(minutes: 5)));
  });
}

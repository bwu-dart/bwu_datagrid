library bwu_datagrid_examples.tool.grind;

import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:grinder/grinder.dart';
import 'package:bwu_docker/bwu_docker.dart';
import 'package:bwu_docker/tasks.dart' as task;

import 'package:bwu_grinder_tasks/bwu_grinder_tasks.dart' as grinderTasks;
export 'package:bwu_grinder_tasks/bwu_grinder_tasks.dart' hide main;

const seleniumImageVersion = ':2.47.1';

const _seleniumHubImage = 'selenium/hub${seleniumImageVersion}';
const _hubContainerName = 'selenium-hub';

//const seleniumChromeImage = 'selenium/node-chrome${seleniumImageVersion}';
const _seleniumChromeImage =
    'selenium/node-chrome-debug${seleniumImageVersion}';

//const seleniumFirefoxImage = 'selenium/node-firefox${seleniumImageVersion}';
const _seleniumFirefoxImage =
    'selenium/node-firefox-debug${seleniumImageVersion}';

const webServer = 'webserver:192.168.2.156';
//const webServer = 'webserver:192.168.2.96';

main(List<String> args) async {
  final origTestTask = grinderTasks.testTask;
//  grinderTasks.testTask = (List<String> platforms) async {
  try {
//    await _startSelenium();
//      origTestTask(platforms);
  } finally {
//      await stopSelenium();
  }
//  };
  grind(args);
}

@Task('dummy')
dummy() {}

DockerConnection _dockerConnection;
CreateResponse _createdHubContainer;
CreateResponse _createdChromeNodeContainer;
CreateResponse _createdFirefoxNodeContainer;

@Task('start-selenium')
startSelenium() => _startSelenium();

_startSelenium() async {
  final dockerHostStr = io.Platform.environment[dockerHostFromEnvironment];
  assert(dockerHostStr != null && dockerHostStr.isNotEmpty);
//  final dockerHost = Uri.parse(dockerHostStr);

  _dockerConnection = new DockerConnection(
      Uri.parse(io.Platform.environment[dockerHostFromEnvironment]),
      new http.Client());
  await _dockerConnection.init();
  _createdHubContainer = await task.run(_dockerConnection, _seleniumHubImage,
      name: _hubContainerName,
      detach: true,
      publish: const ['4444:4444'],
      rm: true);
  _createdChromeNodeContainer = await task.run(
      _dockerConnection, _seleniumChromeImage,
      detach: true,
      publishAll: true,
      rm: true,
      link: const ['${_hubContainerName}:hub'],
      addHost: const [webServer]);
  _createdFirefoxNodeContainer = await task.run(
      _dockerConnection, _seleniumFirefoxImage,
      detach: true,
      publishAll: true,
      rm: true,
      link: const ['${_hubContainerName}:hub'],
      addHost: const [webServer]);
}

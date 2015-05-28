library bwu_datagrid.tool.grind;

import 'package:stack_trace/stack_trace.dart' show Chain;
import 'package:grinder/grinder.dart';

const sourceDirs = const ['lib', 'tool', 'test'];

void main(List<String> args) {
  Chain.capture(() => _main(args), onError: (error, stack) {
    print(error);
    print(stack.terse);
  });
}

// TODO(zoechi) check if version was incremented
// TODO(zoechi) check if CHANGELOG.md contains version

_main(List<String> args) => grind(args);

@Task('Run analyzer')
analyze() => _analyze();

@Task('Run tests')
test() => _test();

@Task('Run tests headless')
testHeadless() => _testHeadless();

@Task('Run all checks (analyze, lint, test)') // check-format,
@Depends(analyze, lint, test) // checkFormat,
check() => _check();

//@Task('Check source code formatting')
//checkFormat() => checkFormatTask(['.']);

@Task('Fix source code formatting')
formatAll() => _formatAll();

@Task('Run lint checks')
lint() => _lint();

_analyze() => new PubApp.global('tuneup').run(['check']);

_test() => new PubApp.local('test').run(['-pdartium']);

_testHeadless() => new PubApp.local('test').run(['-pcontent-shell']);

_check() => run('pub', arguments: ['publish', '-n']);

_formatAll() => new PubApp.global('dart_style').run(['-w']..addAll(sourceDirs),
    script: 'format');

_lint() => new PubApp.global('linter')
    .run(['--stats', '-ctool/lintcfg.yaml']..addAll(sourceDirs));

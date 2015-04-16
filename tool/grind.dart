library bwu_datagrid.tool.grind;

import 'package:stack_trace/stack_trace.dart' show Chain;
import 'package:grinder/grinder.dart';
import 'package:bwu_utils/grinder.dart';

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
analyze() => new PubApp.global('tuneup').run(['check']);

@Task('Run tests')
test() => new PubApp.local('test').run(['-pdartium']);

@Task('Run tests headless')
testHeadless() => new PubApp.local('test').run(['-pcontent-shell']);

@Task('Run all checks (analyze, check-format, lint, test)')
@Depends(analyze, checkFormat, lint, test)
check() {}

@Task('Check source code formatting')
checkFormat() => checkFormatTask(['.']);

@Task('Fix source code formatting')
formatAll() => formatAllTask(['.']);

@Task('Run lint checks')
lint() =>
    new PubApp.global('linter').run(['--stats', '-ctool/lintcfg.yaml', '.']);

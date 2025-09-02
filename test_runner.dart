// test_runner.dart - Place this in your project root directory
import 'dart:io';

void main(List<String> args) async {
  print('🚀 UniStay App Test Suite Runner');
  print('=' * 50);

  // Parse command line arguments
  final runAll = args.isEmpty || args.contains('--all');
  final runWidget = args.contains('--widget') || runAll;
  final runIntegration = args.contains('--integration') || runAll;
  final runAdvanced = args.contains('--advanced') || runAll;
  final verbose = args.contains('--verbose') || args.contains('-v');

  if (args.contains('--help') || args.contains('-h')) {
    _showHelp();
    return;
  }

  // Test file configurations
  final testConfigs = <TestConfig>[
    if (runWidget)
      TestConfig(
        name: 'Widget Tests',
        path: 'test/widget_test/',
        description: 'Fast UI component tests',
        emoji: '🧩',
      ),
    if (runIntegration)
      TestConfig(
        name: 'Integration Tests',
        path: 'test/integration_test/app_test.dart',
        description: 'Basic user flow tests',
        emoji: '🔗',
      ),
    if (runAdvanced)
      TestConfig(
        name: 'Advanced Tests',
        path: 'test/integration_test/advanced_app_test.dart',
        description: 'Comprehensive testing suite',
        emoji: '🎯',
      ),
  ];

  int passCount = 0;
  int failCount = 0;
  final List<TestResult> results = [];

  print('\n📋 Running ${testConfigs.length} test suite(s)...\n');

  for (final config in testConfigs) {
    final result = await _runTest(config, verbose);
    results.add(result);

    if (result.passed) {
      passCount++;
    } else {
      failCount++;
    }
  }

  // Print summary
  _printSummary(results, passCount, failCount);
}

class TestConfig {
  final String name;
  final String path;
  final String description;
  final String emoji;

  TestConfig({
    required this.name,
    required this.path,
    required this.description,
    required this.emoji,
  });
}

class TestResult {
  final TestConfig config;
  final bool passed;
  final String output;
  final String error;
  final Duration duration;

  TestResult({
    required this.config,
    required this.passed,
    required this.output,
    required this.error,
    required this.duration,
  });
}

Future<TestResult> _runTest(TestConfig config, bool verbose) async {
  print('${config.emoji} Running ${config.name}...');
  print('   📁 Path: ${config.path}');
  print('   📝 ${config.description}');

  final stopwatch = Stopwatch()..start();

  try {
    // Check if test path exists
    final testPath = File(config.path);
    final testDir = Directory(config.path);

    if (!await testPath.exists() && !await testDir.exists()) {
      stopwatch.stop();
      print('   ⚠️  Test path not found: ${config.path}\n');
      return TestResult(
        config: config,
        passed: false,
        output: '',
        error: 'Test path not found',
        duration: stopwatch.elapsed,
      );
    }

    // Run the test
    final result = await Process.run(
      'flutter',
      ['test', config.path, if (verbose) '--verbose'],
      runInShell: true,
    );

    stopwatch.stop();

    if (result.exitCode == 0) {
      print('   ✅ PASSED (${stopwatch.elapsed.inSeconds}s)\n');
      if (verbose && result.stdout.toString().isNotEmpty) {
        print('   📤 Output:\n${result.stdout}\n');
      }
    } else {
      print('   ❌ FAILED (${stopwatch.elapsed.inSeconds}s)\n');
      if (verbose) {
        if (result.stderr.toString().isNotEmpty) {
          print('   🚨 Error:\n${result.stderr}\n');
        }
        if (result.stdout.toString().isNotEmpty) {
          print('   📤 Output:\n${result.stdout}\n');
        }
      }
    }

    return TestResult(
      config: config,
      passed: result.exitCode == 0,
      output: result.stdout.toString(),
      error: result.stderr.toString(),
      duration: stopwatch.elapsed,
    );

  } catch (e) {
    stopwatch.stop();
    print('   💥 ERROR: $e\n');

    return TestResult(
      config: config,
      passed: false,
      output: '',
      error: e.toString(),
      duration: stopwatch.elapsed,
    );
  }
}

void _printSummary(List<TestResult> results, int passCount, int failCount) {
  print('\n' + '=' * 60);
  print('📊 TEST SUMMARY');
  print('=' * 60);

  for (final result in results) {
    final status = result.passed ? '✅ PASSED' : '❌ FAILED';
    final duration = '${result.duration.inSeconds}s';
    print('${result.config.emoji} ${result.config.name}: $status ($duration)');

    if (!result.passed && result.error.isNotEmpty) {
      print('    💬 ${result.error.split('\n').first}');
    }
  }

  print('\n📈 STATISTICS:');
  print('   ✅ Passed: $passCount');
  print('   ❌ Failed: $failCount');
  print('   📊 Total:  ${passCount + failCount}');

  final successRate = passCount / (passCount + failCount) * 100;
  print('   🎯 Success Rate: ${successRate.toStringAsFixed(1)}%');

  if (failCount > 0) {
    print('\n💡 TIPS:');
    print('   • Run with --verbose flag for detailed output');
    print('   • Check that all test files exist');
    print('   • Ensure Flutter dependencies are installed');
    print('   • Firebase tests may fail without proper setup');
  }

  print('=' * 60);

  if (passCount == results.length) {
    print('🎉 ALL TESTS PASSED! Great job!');
  } else {
    print('🔧 Some tests need attention. Check the output above.');
  }
  print('=' * 60);
}

void _showHelp() {
  print('''
🚀 UniStay Test Runner

USAGE:
  dart test_runner.dart [options]

OPTIONS:
  --help, -h        Show this help message
  --all             Run all test suites (default)
  --widget          Run only widget tests
  --integration     Run only basic integration tests
  --advanced        Run only advanced integration tests
  --verbose, -v     Show detailed output

EXAMPLES:
  dart test_runner.dart                    # Run all tests
  dart test_runner.dart --widget           # Run only widget tests
  dart test_runner.dart --verbose          # Run all with detailed output
  dart test_runner.dart --integration -v   # Run integration tests with output

TEST TYPES:
  🧩 Widget Tests      - Fast UI component testing (no network)
  🔗 Integration Tests - Basic user flow testing (may require network)
  🎯 Advanced Tests    - Comprehensive testing suite (network dependent)
''');
}
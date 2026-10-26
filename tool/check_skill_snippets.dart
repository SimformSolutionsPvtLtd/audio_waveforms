// Checks that every Dart code block in `skills/**/*.md` compiles against this
// checkout of the package, and that blocks importing `flutter_test` pass.
//
// Run from the package root:
//
//   dart run tool/check_skill_snippets.dart
//
// It builds a throwaway Flutter project in the system temp directory that
// depends on this package by path, so it needs the `flutter` executable on
// PATH.
import 'dart:io';

const _audioWaveformsImport =
    "import 'package:audio_waveforms/audio_waveforms.dart';\n";

Future<void> main() async {
  final root = Directory.current;
  if (!File('${root.path}/pubspec.yaml').existsSync() ||
      !Directory('${root.path}/skills').existsSync()) {
    stderr.writeln('Run this from the audio_waveforms package root.');
    exit(2);
  }

  final project = Directory.systemTemp.createTempSync('skill_snippets_');
  try {
    final counts = _writeSnippets(root, project);
    if (counts.snippets == 0) {
      stderr.writeln('No Dart code blocks found under skills/.');
      exit(2);
    }
    stdout.writeln(
      'Extracted ${counts.snippets} snippets (${counts.tests} test files).',
    );

    File('${project.path}/pubspec.yaml').writeAsStringSync('''
name: skill_snippets
publish_to: none
environment:
  sdk: ">=3.0.0 <4.0.0"
dependencies:
  flutter:
    sdk: flutter
  audio_waveforms:
    path: ${root.path}
dev_dependencies:
  flutter_test:
    sdk: flutter
''');

    await _run('flutter', ['pub', 'get'], project);
    await _run('flutter', ['analyze'], project);
    if (counts.tests > 0) {
      await _run('flutter', ['test'], project);
    }
    stdout.writeln('Skill snippets OK.');
  } finally {
    project.deleteSync(recursive: true);
  }
}

({int snippets, int tests}) _writeSnippets(Directory root, Directory project) {
  final block = RegExp(r'```dart\n(.*?)```', dotAll: true);
  Directory('${project.path}/lib').createSync();
  Directory('${project.path}/test').createSync();

  var snippets = 0;
  var tests = 0;
  final markdown = Directory('${root.path}/skills')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'));

  for (final file in markdown) {
    final name = file.uri.pathSegments
        .where((s) => s.isNotEmpty)
        .skip(
          root.uri.pathSegments.where((s) => s.isNotEmpty).length,
        )
        .join('_')
        .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    var index = 0;
    for (final match in block.allMatches(file.readAsStringSync())) {
      var code = match.group(1)!;
      index++;
      // Comment-only blocks (migration tables) have nothing to compile.
      final lines = code.split('\n').where((l) => l.trim().isNotEmpty);
      if (lines.every((l) => l.trimLeft().startsWith('//'))) continue;

      final isTest = code.contains('package:flutter_test/');
      if (!code.contains('import ')) code = _audioWaveformsImport + code;
      final dir = isTest ? 'test' : 'lib';
      final suffix = isTest ? '_test' : '';
      File('${project.path}/$dir/${name}_$index$suffix.dart')
          .writeAsStringSync(code);
      snippets++;
      if (isTest) tests++;
    }
  }
  return (snippets: snippets, tests: tests);
}

Future<void> _run(String exe, List<String> args, Directory cwd) async {
  stdout.writeln('\$ $exe ${args.join(' ')}');
  final process = await Process.start(
    exe,
    args,
    workingDirectory: cwd.path,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await process.exitCode;
  if (code != 0) {
    stderr.writeln('`$exe ${args.join(' ')}` failed with exit code $code.');
    exit(code);
  }
}

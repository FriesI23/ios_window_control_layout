import 'dart:io';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final versionMatch = RegExp(
    r'^version:\s*(\S+)',
    multiLine: true,
  ).firstMatch(pubspec);
  if (versionMatch == null) {
    stderr.writeln('ERROR: version not found in pubspec.yaml');
    exitCode = 1;
    return;
  }

  final version = versionMatch.group(1)!;
  _syncPodspec('ios/ios_window_control_layout.podspec', version);
  stdout.writeln(version);
}

final _versionPattern = RegExp(
  r"^(\s*s\.version\s*=\s*)'[^']*'",
  multiLine: true,
);

void _syncPodspec(String path, String version) {
  final file = File(path);
  final content = file.readAsStringSync();
  final matches = _versionPattern.allMatches(content).length;
  if (matches != 1) {
    stderr.writeln(
      'ERROR: expected one s.version declaration in $path, found $matches',
    );
    exit(1);
  }

  final updated = content.replaceFirstMapped(
    _versionPattern,
    (match) => "${match.group(1)}'$version'",
  );
  if (updated != content) {
    file.writeAsStringSync(updated);
  }
}

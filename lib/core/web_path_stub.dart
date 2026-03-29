// Web stub for path_provider — provides safe no-op implementations
// so the package is not imported on Flutter Web builds.
// Returns a dummy object that satisfies callers without crashing.

class _WebDirectory {
  final String path;
  const _WebDirectory(this.path);
}

Future<_WebDirectory> getTemporaryDirectory() async {
  return const _WebDirectory('/tmp');
}

Future<_WebDirectory> getApplicationDocumentsDirectory() async {
  return const _WebDirectory('/documents');
}

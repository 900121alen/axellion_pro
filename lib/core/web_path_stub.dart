// Web stub for path_provider — provides no-op implementations
// so the package is not imported on Flutter Web builds.

Future<dynamic> getTemporaryDirectory() async {
  throw UnsupportedError('getTemporaryDirectory is not supported on web.');
}

Future<dynamic> getApplicationDocumentsDirectory() async {
  throw UnsupportedError(
    'getApplicationDocumentsDirectory is not supported on web.',
  );
}

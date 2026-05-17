class StorageTelemetry {
  int writeSuccessCount = 0;
  int writeFailureCount = 0;
  int lastWriteDurationMs = 0;
  bool diskFull = false;
  bool permissionError = false;

  void reset() {
    writeSuccessCount = 0;
    writeFailureCount = 0;
    lastWriteDurationMs = 0;
    diskFull = false;
    permissionError = false;
  }
}

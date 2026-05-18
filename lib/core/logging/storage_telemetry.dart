class StorageTelemetry {
  int writeSuccess = 0;
  int writeFailure = 0;
  int durationMs = 0;
  bool diskFull = false;
  bool permissionError = false;

  void recordSuccess(int ms) {
    writeSuccess++;
    durationMs = ms;
  }

  void recordFailure({bool diskFull = false, bool permissionError = false}) {
    writeFailure++;
    this.diskFull = diskFull;
    this.permissionError = permissionError;
  }

  void reset() {
    writeSuccess = 0;
    writeFailure = 0;
    durationMs = 0;
    diskFull = false;
    permissionError = false;
  }
}

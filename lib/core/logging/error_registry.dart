class ErrorRegistry {
  int providerErrors = 0;
  int parserErrors = 0;
  int validatorErrors = 0;
  int uiErrors = 0;
  int repairErrors = 0;
  int exportErrors = 0;
  int unknownErrors = 0;

  void clear() {
    providerErrors = 0;
    parserErrors = 0;
    validatorErrors = 0;
    uiErrors = 0;
    repairErrors = 0;
    exportErrors = 0;
    unknownErrors = 0;
  }
}

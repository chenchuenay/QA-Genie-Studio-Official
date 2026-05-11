enum GenerationMode {
  balanced,
  positiveOnly,
  securityFocused,
  boundaryFocused,
  validationOnly,
}

GenerationMode parseConstraints(String? constraints) {
  if (constraints == null || constraints.trim().isEmpty) return GenerationMode.balanced;
  final c = constraints.toLowerCase();
  if (c.contains('positive only')) return GenerationMode.positiveOnly;
  if (c.contains('security')) return GenerationMode.securityFocused;
  if (c.contains('boundary')) return GenerationMode.boundaryFocused;
  if (c.contains('validation')) return GenerationMode.validationOnly;
  return GenerationMode.balanced;
}

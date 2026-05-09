class PriorityUtils {
  static const List<String> allowed = ['High', 'Medium', 'Low'];
  static String normalize(String? value) {
    if (value == null || value.isEmpty) return 'Medium';
    final v = value.trim().toLowerCase();
    if (v == 'high' || v == 'critical' || v == 'p0' || v == '1' || v == 'highest') return 'High';
    if (v == 'medium' || v == 'p1' || v == '2' || v == 'major') return 'Medium';
    if (v == 'low' || v == 'p2' || v == '3' || v == 'minor') return 'Low';
    return 'Medium';
  }
}

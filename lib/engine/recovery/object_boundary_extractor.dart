class ObjectBoundaryExtractor {
  static List<String> extractSafeObjects(String raw) {
    final objects = <String>[];
    int objectDepth = 0;
    int arrayDepth = 0;
    bool inQuotes = false;
    bool escaped = false;
    int start = -1;

    for (int i = 0; i < raw.length; i++) {
      final c = raw[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (c == '\\' && inQuotes) {
        escaped = true;
        continue;
      }

      if (c == '"') {
        inQuotes = !inQuotes;
        continue;
      }

      if (!inQuotes) {
        if (c == '{') {
          if (objectDepth == 0 && arrayDepth == 0) {
            start = i;
          }
          objectDepth++;
        } else if (c == '}') {
          objectDepth--;
          if (objectDepth == 0 && arrayDepth == 0 && start != -1) {
            objects.add(raw.substring(start, i + 1));
            start = -1;
          }
        } else if (c == '[') {
          arrayDepth++;
        } else if (c == ']') {
          arrayDepth--;
        }
      }

      if (objectDepth < 0 || arrayDepth < 0) {
        break;
      }
    }
    return objects;
  }
}

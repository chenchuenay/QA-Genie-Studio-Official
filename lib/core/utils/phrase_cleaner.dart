class PhraseCleaner {
  static String clean(String text) {
    var cleaned = text;
    
    // Target robotic filler-context patterns specifically
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'The system should (display|show|process|execute|handle)', caseSensitive: false),
      (m) => '${m[1]![0].toUpperCase()}${m[1]!.substring(1)}',
    );
    
    cleaned = cleaned.replaceAll(RegExp(r'successfully logs in', caseSensitive: false), 'logs in');
    cleaned = cleaned.replaceAll(RegExp(r'successfully authenticated', caseSensitive: false), 'authenticated');
    
    // Only clean generic filler if it appears at the start of a sentence
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'^The system (processes|displays|shows) (.*?) successfully', caseSensitive: false),
      (m) => '${m[1]![0].toUpperCase()}${m[1]!.substring(1)} ${m[2]}',
    );
    
    return cleaned.trim();
  }
}

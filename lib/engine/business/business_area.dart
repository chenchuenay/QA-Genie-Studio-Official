/// Pure metadata for a business area. No knowledge of scenarios or outcomes.
class BusinessArea {
  final String id; // 'authentication', 'ecommerce', 'banking'
  final String domain; // 'security', 'transaction', 'general'
  final String riskProfile; // 'HIGH', 'MEDIUM', 'LOW'

  const BusinessArea({
    required this.id,
    required this.domain,
    required this.riskProfile,
  });
}

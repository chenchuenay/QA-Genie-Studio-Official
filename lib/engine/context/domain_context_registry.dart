class DomainContextRegistry {
  static const fintechTerms = [
    'settlement',
    'beneficiary',
    'OTP',
    'transaction limit',
    'retry window',
    'receipt',
    'balance',
    'gateway',
    'processing'
  ];
  static const ecommerceTerms = [
    'cart',
    'checkout',
    'coupon',
    'inventory',
    'payment retry',
    'order',
    'wishlist'
  ];
  static const authTerms = [
    'dashboard',
    'login',
    'session',
    'refresh',
    'token',
    'logout'
  ];
  
  static List<String> getTerms(String context) {
    final ctx = context.toLowerCase();
    if (['payment', 'transaction', 'wallet', 'balance'].any(ctx.contains)) return fintechTerms;
    if (['cart', 'shop', 'checkout', 'order', 'wishlist'].any(ctx.contains)) return ecommerceTerms;
    if (['login', 'auth', 'session', 'signup', 'otp', 'password'].any(ctx.contains)) return authTerms;
    return ['user', 'system', 'request', 'data', 'verify'];
  }
}

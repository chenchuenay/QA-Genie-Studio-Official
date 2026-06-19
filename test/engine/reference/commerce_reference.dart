import 'identity_reference.dart';

class CommerceReference {
  static final cases = [
    ReferenceCase(
      title: 'User can add an in-stock item to cart and verify cart badge updates',
      type: 'POSITIVE',
      priority: 'High',
      preconditions: [
        'User is browsing the product catalog on the shop page',
        'At least one product is marked as "In Stock" and has a visible price',
        'Cart is empty or contains no more than 5 items (within max limit)',
      ],
      testData:
          'product=Sku-7755 Wireless Headphones, price=\$49.99, quantity=1, platform=Mobile',
      steps: [
        'Open the product catalog and scroll to find Wireless Headphones (SKU-7755)',
        'Tap on the product card to open the product detail page',
        'Verify product details: name, price \$49.99, availability "In Stock"',
        'Tap the "Add to Cart" button below the product description',
        'Observe the cart badge icon in the top-right header — it should update from 0 to 1',
        'Tap the cart icon to open the cart drawer and verify the item appears with correct price',
      ],
      expectedResult:
          'The item is added to the cart successfully. The cart badge count increments by 1. The cart drawer lists the correct product name, quantity, and unit price. The subtotal calculates correctly (\$49.99 × 1 = \$49.99).',
    ),
    ReferenceCase(
      title: 'Applying an expired coupon code during checkout shows rejection message',
      type: 'NEGATIVE',
      priority: 'Medium',
      preconditions: [
        'User has at least one item in the cart and has proceeded to checkout',
        'User has an expired coupon code (e.g., SAVE20 — expired 2025-12-31)',
        'Cart total is greater than \$0.00 so coupon application is attempted',
      ],
      testData:
          'couponCode=SAVE20, cartTotal=\$49.99, platform=Web',
      steps: [
        'Navigate to the Cart page and ensure cart contains at least one item',
        'Locate the "Promo Code / Coupon" input field in the Order Summary section',
        'Enter coupon code: SAVE20 in the promo code field',
        'Click "Apply" button next to the promo code field',
        'Observe the response: an inline error message appears below the field',
      ],
      expectedResult:
          'The coupon code is rejected. An inline error message displays: "Promo code SAVE20 has expired or is no longer valid." The original cart total remains unchanged, and no discount is applied. The user can proceed to checkout without the coupon.',
    ),
    ReferenceCase(
      title: 'Complete checkout flow with valid payment details generates order confirmation',
      type: 'POSITIVE',
      priority: 'High',
      preconditions: [
        'User is authenticated with an active session',
        'Cart contains at least 1 in-stock item',
        'Valid shipping address is saved in the address book',
        'Payment method (VISA **** 4242) is on file and has sufficient funds',
      ],
      testData:
          'item=Wireless Headphones, qty=2, shipping="123 Main St, Springfield, IL 62701", card=VISA-4242, exp=12/28, cvv=345, platform=Mobile',
      steps: [
        'Open the Cart screen and verify items listed with correct quantities',
        'Tap "Proceed to Checkout" button',
        'Select saved shipping address: 123 Main St, Springfield, IL',
        'Choose shipping method: Standard (5-7 business days, free)',
        'Enter payment card details: VISA **** 4242, Exp 12/28, CVV 345',
        'Review order summary: item total (\$99.98), tax, shipping fee, grand total',
        'Tap "Place Order" button to confirm the purchase',
        'Wait for order confirmation screen — verify unique order ID is displayed',
      ],
      expectedResult:
          'The order is placed successfully. A confirmation screen displays with the order number (e.g., ORD-2026-0619-8842), item details, shipping address, and expected delivery date. A confirmation email is sent to the registered email. The cart is now empty.',
    ),
  ];
}

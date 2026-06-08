import '../ontology/states.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';
import '../models/domain_context.dart';
import '../ontology/relationships.dart';

class CommerceDomain {
  static const DomainContext context = DomainContext(
    id: 'commerce',
    displayName: 'Commerce',
    entities: {
      EntityType.cart,
      EntityType.item,
      EntityType.product,
      EntityType.order,
      EntityType.coupon,
      EntityType.giftCard,
      EntityType.payment,
      EntityType.address,
      EntityType.shipping,
      EntityType.inventory,
      EntityType.receipt,
      EntityType.refund,
      EntityType.shippingMethod,
      EntityType.tax,
      EntityType.discount,
    },
    actions: {
      ActionType.add,
      ActionType.remove,
      ActionType.updateQuantity,
      ActionType.apply,
      ActionType.redeem,
      ActionType.checkout,
      ActionType.pay,
      ActionType.confirm,
      ActionType.ship,
      ActionType.cancel,
      ActionType.generate,
      ActionType.initiate,
      ActionType.calculate,
    },
    states: {
      StateType.active,
      StateType.pending,
      StateType.confirmed,
      StateType.cancelled,
      StateType.paid,
      StateType.unpaid,
      StateType.shipped,
      StateType.delivered,
      StateType.refunded,
      StateType.valid,
      StateType.invalid,
      StateType.expired,
      StateType.outOfStock,
      StateType.discounted,
      StateType.rejected,
      StateType.processed,
    },
  );

  static List<Relationship> getRelationships() {
    return [
      // cart <-> item
      Relationship(
        source: EntityType.cart,
        target: EntityType.item,
        action: ActionType.add,
        fromState: StateType.active,
        toState: StateType.active,
      ),
      Relationship(
        source: EntityType.cart,
        target: EntityType.item,
        action: ActionType.remove,
        fromState: StateType.active,
        toState: StateType.active,
      ),
      Relationship(
        source: EntityType.cart,
        target: EntityType.item,
        action: ActionType.updateQuantity,
        fromState: StateType.active,
        toState: StateType.active,
      ),

      // inventory
      Relationship(
        source: EntityType.inventory,
        target: EntityType.item,
        action: ActionType.view,
        fromState: StateType.available,
        toState: StateType.active,
      ),
      Relationship(
        source: EntityType.inventory,
        target: EntityType.item,
        action: ActionType.view,
        fromState: StateType.outOfStock,
        toState: StateType.failed,
      ),

      // cart -> order
      Relationship(
        source: EntityType.cart,
        target: EntityType.order,
        action: ActionType.checkout,
        fromState: StateType.active,
        toState: StateType.pending,
      ),

      // order -> payment
      Relationship(
        source: EntityType.order,
        target: EntityType.payment,
        action: ActionType.pay,
        fromState: StateType.pending,
        toState: StateType.paid,
      ),
      Relationship(
        source: EntityType.payment,
        target: EntityType.order,
        action: ActionType.pay,
        fromState: StateType.valid,
        toState: StateType.paid,
      ),
      Relationship(
        source: EntityType.payment,
        target: EntityType.order,
        action: ActionType.pay,
        fromState: StateType.invalid,
        toState: StateType.failed,
      ),

      // coupon
      Relationship(
        source: EntityType.coupon,
        target: EntityType.cart,
        action: ActionType.apply,
        fromState: StateType.valid,
        toState: StateType.discounted,
      ),
      Relationship(
        source: EntityType.coupon,
        target: EntityType.cart,
        action: ActionType.apply,
        fromState: StateType.expired,
        toState: StateType.rejected,
      ),

      // gift card
      Relationship(
        source: EntityType.giftCard,
        target: EntityType.payment,
        action: ActionType.redeem,
        fromState: StateType.valid,
        toState: StateType.processed,
      ),
      Relationship(
        source: EntityType.giftCard,
        target: EntityType.payment,
        action: ActionType.redeem,
        fromState: StateType.expired,
        toState: StateType.failed,
      ),

      // address
      Relationship(
        source: EntityType.address,
        target: EntityType.shipping,
        action: ActionType.confirm,
        fromState: StateType.valid,
        toState: StateType.active,
      ),
      Relationship(
        source: EntityType.address,
        target: EntityType.shipping,
        action: ActionType.confirm,
        fromState: StateType.invalid,
        toState: StateType.failed,
      ),

      // shipping method
      Relationship(
        source: EntityType.shippingMethod,
        target: EntityType.order,
        action: ActionType.ship,
        fromState: StateType.active,
        toState: StateType.shipped,
      ),

      // receipt and refund
      Relationship(
        source: EntityType.order,
        target: EntityType.receipt,
        action: ActionType.generate,
        fromState: StateType.paid,
        toState: StateType.active,
      ),
      Relationship(
        source: EntityType.order,
        target: EntityType.refund,
        action: ActionType.initiate,
        fromState: StateType.cancelled,
        toState: StateType.refunded,
      ),

      // tax / discount
      Relationship(
        source: EntityType.tax,
        target: EntityType.order,
        action: ActionType.calculate,
        fromState: StateType.active,
        toState: StateType.processed,
      ),
      Relationship(
        source: EntityType.discount,
        target: EntityType.cart,
        action: ActionType.calculate,
        fromState: StateType.active,
        toState: StateType.discounted,
      ),
    ];
  }
}

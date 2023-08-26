def create_orders_and_charges(sub_id)
  ActiveRecord::Base.transaction do
    subscription = Subscription.find(sub_id)
    subscription.update(start_date: Date.new(2023,4,1))
    so_order = subscription.orders.find_by(type: SalesOrder.name)
    create_charges_for_so(so_order, Date.new(2023,4,1), Date.new(2023,5,1))
    recalculate_order(so_order)
    so_order.update_columns(expiration_date: Date.new(2023,5,1))
    po_order = create_po_order(subscription)
    create_charges_for_po(po_order, Date.new(2023,5,1), Date.new(2023,6,1))
    recalculate_order(po_order)
  end
end

def create_charges_for_so(order, date_from, date_to)
  items = order.upgrade_items
  items.each do |item|
    subscription_resource = order.subscription.subscription_resources.find(item.target_id)
    charge = ChargeBuilder.new(
      ::Charge::Recurring,
      reseller: subscription_resource.subscription.reseller,
      account: subscription_resource.subscription.account,
      provisioning_item: item,
      subscription: subscription_resource.subscription,
      subscription_resource: subscription_resource,
      price: subscription_resource.price,
      quantity: subscription_resource.additional,
      operate_from: date_from,
      operate_to: date_to
    ).call
    charge.duration = ::Calculators::DurationBetweenDates.new(charge, from: charge.operate_from, to: charge.operate_to).call
    charge.recalculate_amount!
    charge.save!
  end
end

def create_po_order(subscription)
  order = ProlongOrder.new(
    account: subscription.account,
    payment_model: subscription.payment_model,
    manager: Current.manager,
    custom_price: subscription.custom_price?,
    subscriptions: [subscription],
    operate_from: Date.new(2023,5,1),
    operate_to: Date.today,
    status: :completed,
  )
  order.save!
  prolong_item = ProvisioningItem::Prolong.new(
    target: subscription,
    description: subscription.name,
    status: :completed,
    custom_price: subscription.custom_price?,
    order: order,
    operation_value: Date.new(2023,6,1)
  )
  prolong_item.save!
  order.items << prolong_item
  order.update(operate_to: Date.new(2023,6,1))
  order.update_columns(expiration_date: Date.new(2023,6,1))
  return order
end

def recalculate_order(order)
  OrderDetailsGenerator.new(order).generate!
  order.recalculate_total!
  order.recalculate_net_cost!
end

def create_charges_for_po(order, date_from, date_to)
  subscription_resources = order.subscription.subscription_resources.where('additional > 0')
  item = order.prolong_item
  subscription_resources.each do |subscription_resource|
    charge = ChargeBuilder.new(
      ::Charge::Recurring,
      reseller: subscription_resource.subscription.reseller,
      account: subscription_resource.subscription.account,
      provisioning_item: item,
      subscription: subscription_resource.subscription,
      subscription_resource: subscription_resource,
      price: subscription_resource.price,
      quantity: subscription_resource.additional,
      operate_from: date_from,
      operate_to: date_to
    ).call
    charge.duration = ::Calculators::DurationBetweenDates.new(charge, from: charge.operate_from, to: charge.operate_to).call
    charge.recalculate_amount!
    charge.save!
  end
end

def close_charges(charges_ids)
  charges_ids.each do |charge_id|
    charge = Charge::Base.find(charge_id)
    charge.update(status: :blocked)
    ChargeCloser.new(charge, charge.operate_to).call
  end
end
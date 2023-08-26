#for PO
subscription_resource = Subscription.find(45759).subscription_resource
item = Order.find(263769).upgrade_items.first
date_form = Date.new(2023, 6, 13)
date_to = Date.new(2023, 7, 1)
charge = ChargeBuilder.new(
  ::Charge::Recurring,
  reseller: subscription_resource.subscription.reseller,
  account: subscription_resource.subscription.account,
  provisioning_item: item,
  subscription: subscription_resource.subscription,
  subscription_resource: subscription_resource,
  price: subscription_resource.price,
  quantity: subscription_resource.additional,
  operate_from: date_form,
  operate_to: date_to
).call
charge.duration = ::Calculators::DurationBetweenDates.new(charge, from: charge.operate_from, to: charge.operate_to).call
charge.save
currency_rate = CurrencyRate.where(from_id: 2, to_id: 4).where("updated_at < ?", Date.today).last


#for SO
subscription_resource = SubscriptionResource.find(299833)
item = Order.find(270276).upgrade_items.find_by(target_id: subscription_resource.id)
date_form = Date.new(2023, 8, 1)
date_to = Date.new(2023, 9, 1)
attributes = {
  account: subscription_resource.subscription.account,
  reseller: subscription_resource.subscription.reseller,
  price: subscription_resource.price,
  quantity: subscription_resource.additional,
  subscription: subscription_resource.subscription,
  subscription_resource: subscription_resource,
  operate_from: date_form,
  operate_to: date_to,
  close_date: date_to,
  provisioning_item: item
}
charge = ChargeBuilder.new(::Charge::Recurring, attributes).call
charge.duration = ::Calculators::DurationBetweenDates.new(charge, from: charge.operate_from, to: charge.operate_to).call

currency_rate = CurrencyRate.where(from_id: 2, to_id: 4).where("updated_at < ?", order.created_at).last
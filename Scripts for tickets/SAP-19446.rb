def create_charge(operate_from, operate_to, order_id)
  ActiveRecord::Base.transaction do
    subscription_resource = SubscriptionResource.find(296644)
    order = Order.find(order_id)
    item = order.prolong_items.last
    date_form = operate_from
    date_to = operate_to
    currency_rate = CurrencyRate.where(from_id: 2, to_id: 4).where("updated_at < ?", order.closed_at).last
    charge = ChargeBuilder.new(
    ::Charge::Recurring,
    reseller: subscription_resource.subscription.reseller,
    account: subscription_resource.subscription.account,
    provisioning_item: item,
    subscription: subscription_resource.subscription,
    subscription_resource: subscription_resource,
    price: subscription_resource.price,
    quantity: 12,
    duration: 1,
    operate_from: date_form,
    operate_to: date_to,
    currency_rate: currency_rate
    ).call
    charge.save
    order = charge.order
    OrderDetailsGenerator.new(order).generate!
    order.recalculate_total!
    order.recalculate_net_cost!
    charge.update(status: :blocked)
    ChargeCloser.new(charge, charge.operate_to).call
    charge.update(close_date: Date.today)
  end
end

order_id = 257561	
operate_from = Date.new(2023,5,1)
operate_to = Date.new(2023,6,1)
create_charge(operate_from, operate_to, order_id)
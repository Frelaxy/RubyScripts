#for PO and SO and RN
def create_charge(order_id, date_from, date_to, subs_res_ids, currency_rate = nil)
  @order = Order.find(order_id)
  @currency_rate = currency_rate
  subscription_resources = SubscriptionResource.where(id: subs_res_ids)
  
  def create_charge_from_subscription_resource(subscription_resource, date_from, date_to)
    if @order.type == ProlongOrder.name
      item = @order.prolong_items.empty? ? create_prolong_item(subscription_resource) : @order.prolong_items.first
    elsif @order.type == SalesOrder.name
      item = @order.upgrade_items.empty? ? create_upgrade_item(subscription_resource) : @order.upgrade_items.find_by(target_id: subscription_resource.id)
    elsif @order.type == RenewalOrder.name
      item = @order.renew_item
    end
    attributes = {
      reseller: subscription_resource.subscription.reseller,
      account: subscription_resource.subscription.account,
      provisioning_item: item,
      subscription: subscription_resource.subscription,
      subscription_resource: subscription_resource,
      price: subscription_resource.price,
      quantity: subscription_resource.additional,
      operate_from: date_from,
      operate_to: date_to
    }
    charge = ChargeBuilder.new(::Charge::Recurring, attributes).call
    charge.recalculate_duration!
    if @currency_rate
      charge.currency_rate = @currency_rate
      charge.recalculate_amount!
    end
    charge.save!
  end

  def create_prolong_item(subscription_resource)
    item = ProvisioningItem::Prolong.create!(
      order_id: @order.id,
      target_id: subscription_resource.subscription.id,
      target_type: "Subscription",
      type: "ProvisioningItem::Prolong",
      operation_value: @order.expiration_date,
      status: "completed",
      description: subscription_resource.subscription.name,
      custom_price: subscription_resource.subscription.custom_price?
    )
    item.save!
    return item
  end

  def create_upgrade_item(subscription_resource)
    item = ProvisioningItem::Upgrade.create!(
      order_id: @order.id,
      target_id: subscription_resource.id,
      target_type: "SubscriptionResource",
      type: "ProvisioningItem::Upgrade",
      operation_value: subscription_resource.additional.to_s,
      status: "completed",
      description: subscription_resource.name,
      custom_price: subscription_resource.subscription.custom_price?
    )
    item.save!
    return item
  end

  ActiveRecord::Base.transaction do
    subscription_resources.each do |subscription_resource|
      create_charge_from_subscription_resource(subscription_resource, date_from, date_to)
    end
  end
end

#_________________________________________________________________________________________

order_id = 266951
subs_res_ids = [391424]
date_from = Date.new(2023,10,10)
date_to = Date.new(2024,10,10)
create_charge(order_id, date_from, date_to, subs_res_ids)


#запуск с определенным курсом валют
currency_rate = CurrencyRate.where(from_id: 2, to_id: 4).where("updated_at < ?", Date.today).last
currency_rate = CurrencyRate.where(from_id: 2, to_id: 4).where("updated_at < ?", order.created_at).last
create_charge(order_id, date_from, date_to, subs_res_ids, currency_rate)
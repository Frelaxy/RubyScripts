#for PO and SO
def create_charge(order_id, date_from, date_to, subs_res_ids, currency_rate = nil)
  @order = Order.find(order_id)
  @currency_rate = currency_rate
  subscription_resources = SubscriptionResource.where(id: subs_res_ids)
  ActiveRecord::Base.transaction do
    subscription_resources.each do |subscription_resource|
      create_charge_from_subscription_resource(subscription_resource, date_from, date_to)
    end
  end

  def create_charge_from_subscription_resource(subscription_resource, date_from, date_to)
    if @order.type == ProlongOrder.name
      item = @order.prolong_items.first
    elsif @order.type == SalesOrder.name
      item = @order.upgrade_items.find_by(target_id: subscription_resource.id)
    end
    attributes = {
      reseller: subscription_resource.subscription.reseller,
      account: subscription_resource.subscription.account,
      provisioning_item: item,
      subscription: subscription_resource.subscription,
      subscription_resource: subscription_resource,
      price: subscription_resource.price,
      quantity: subscription_resource.additional,
      operate_from: date_form,
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
end

#_________________________________________________________________________________________

order_id = 213232
subs_res_ids = [233321, 233321]
date_form = Date.new(2023,8,8)
date_to = Date.new(2023,9,8)
create_charge(order_id, date_from, date_to, subs_res_ids)


currency_rate = CurrencyRate.where(from_id: 2, to_id: 4).where("updated_at < ?", Date.today).last
currency_rate = CurrencyRate.where(from_id: 2, to_id: 4).where("updated_at < ?", order.created_at).last
create_charge(order_id, date_from, date_to, subs_res_ids, currency_rate)
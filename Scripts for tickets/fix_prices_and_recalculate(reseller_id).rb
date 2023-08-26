def fix_prices(reseller_id)
  reseller = Reseller.find(reseller_id)
  dd1 =  Date.new(2023,9,9)
  dd2 =  Date.new(2023,9,10)
  dd3 =  Date.new(2022,9,8)
  subscriptions = reseller.subscriptions.where("expiration_date = ? or expiration_date = ?", dd1, dd2)
  subscriptions.each do |sub|
    p "Subscription #{sub.id} to process"
    charges = sub.charges.where("created_at > ?", dd3)
    new_price = charges.first.price
    sub.subscription_resource.update(price: new_price)
    charges.each do |charge|
      p "Charge #{charge.id} to process"
      charge.update(price: new_price)
      fix_order_dates(charge.id, charge.operate_from, charge.operate_to)
      if charge.status == 'closed'
        ResellerCharge.where(charge_id: charge.id).delete_all
        ResellerChargesBuilder.new(charge).call
      end
    end
    Note.create!(
      content: "Price was corrected for resource and charges. Charges were recalculated, reseller charge was regenerated | SAP-18154",
      noteable_id: sub.id,
      noteable_type: "Subscription",
      manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
      account_id: sub.account.id
    )
  end
end
def fix_order_dates(charge_id, date_from, date_to)
  charge = Charge::Base.find(charge_id)
  charge.operate_from = date_from
  charge.operate_to = date_to
  if charge.subscription.billing_type == "csp_annual"
    p "You have to ckeck a close date for this charge. It's #{charge.close_date} now"
  elsif
    charge.close_date = date_to
  end
  charge.duration = ::Calculators::DurationBetweenDates.new(charge, from: charge.operate_from, to: charge.operate_to).call
  charge.recalculate_amount!
  charge.save
  order = charge.order
  OrderDetailsGenerator.new(order).generate!
  order.recalculate_total!
  order.recalculate_net_cost!
  if order.payment && order.payment.orders.count == 1 && order.payment.status != 'comleted' && order.payment.status != 'completed'
    order.payment.update(total: order.total)
  end
end
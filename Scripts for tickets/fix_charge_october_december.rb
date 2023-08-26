def fix_charges_cotober_december(sub_id)
  subscription = Subscription.find(sub_id)
  charges = subscription.charges.where("operate_from > ? or operate_from = ? and operate_from < ?", Date.new(2022,11,1), Date.new(2022,11,1), Date.new(2022,12,1))
  charges.map do |charge|
    if !charge.balance_transaction.nil?
      transaction_total = charge.balance_transaction.total
      account = charge.account
      account.balance = account.balance - transaction_total
      account.save
      charge.balance_transaction.delete
    end
    if !ResellerCharge.where(charge_id: charge.id).empty?
      ResellerCharge.where(charge_id: charge.id).delete_all
    end
    new_price = charge.subscription.orders.where(type: "RenewalOrder").where(status: :completed).last.charges.last.price
    charge.update(price: new_price)
    charge.recalculate_amount!
    charge.save
    order = charge.order
    OrderDetailsGenerator.new(order).generate!
    order.recalculate_total!
    order.recalculate_net_cost!
    if charge.status == "closed"
      charge.update(status: :blocked)
      ChargeCloser.new(charge).call
    end
    SubscriptionResource.find(charge.subscription_resource_id).update(price: new_price)
	end
  Note.create!(
    content: "November and december charges were recalculated | SAP-18257",
    noteable_id: subscription.id,
    noteable_type: "Subscription",
    manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
    account_id: subscription.account.id
  )
end
def complete_faild_orders(reseller_id)
  ActiveRecord::Base.transaction do
    reseller = Reseller.find(reseller_id)
    subscriptions = reseller.subscriptions.in_stopping_failed
    subscriptions.map do |subscription|
      subscription.charges.last.update(status: :deleted)
      stop_subscription_in_AP(subscription_id= subscription.id, ticket_id = 'SAP-20790')
    end
  end
end
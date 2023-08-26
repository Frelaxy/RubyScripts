def create_so(sub_id)
  ActiveRecord::Base.transaction do
    subscription = Subscription.find(sub_id)

    so = ::SalesOrder.create!(
      account: subscription.account,
      payment_model: subscription.payment_model,
      status: :completed,
      subscriptions: [subscription],
      closed_at: Time.now
    )

    pr_item = ::ProvisioningItem::New.new(
      target: subscription,
      description: subscription.name,
      status: :completed,
      custom_price: subscription.custom_price?
    )

    so.save!
    pr_item.order_id = so.id
    pr_item.save!

    OrderDetailsGenerator.new(so).generate!
  end
end
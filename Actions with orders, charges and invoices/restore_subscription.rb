def restore_subscription(subscription_id, ticket_id = '')
  subscription = Subscription.find(subscription_id)
  application = Application.find_by(subscription.id)
  application.update(service_status: :running)
  origin = application.origin
  origin.external_id = origin.external_id.chomp("_brocken")
  origin.microsoft_order_id = origin.microsoft_order_id.chomp("_brocken")
  origin.service_status = :active if origin.respond_to? 'service_status'
  origin.save!
  subscription.update(status: :active)
  puts "стоит проверить списания"
end
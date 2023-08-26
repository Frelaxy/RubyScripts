def stop_subscription_in_AP(subscription_id, ticket_id = 'SAP-18879')
  subscription = Subscription.find(subscription_id)
  if subscription.applications.last.origin.respond_to?(:service_status)
    subscription.applications.last.origin.update(service_status: :stopped)
  end
  subscription.applications.last.update(service_status: :stopped)
  subscription.update(status: :stopped)
  Note.create!(
    content: "Subscription stopped manually | #{ticket_id}",
    noteable_id: subscription.id,
    noteable_type: "Subscription",
    manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
    account_id: subscription.account.id
  )
end
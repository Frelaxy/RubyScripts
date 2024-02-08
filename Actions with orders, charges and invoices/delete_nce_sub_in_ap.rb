def delete_nce_sub_in_ap(sub_id, ticket_id = '')
  ActiveRecord::Base.transaction do
    subscription = Subscription.find(sub_id)
    manual_operations = subscription.manual_operations.where(status: :approval_required)
    if manual_operations
      manual_operations.update(status: :declined)
    end
    application = subscription.applications.last
    origin = subscription.applications.last.origin
    origin.external_id.nil? ? origin.update(external_id: '_broken') : origin.update(external_id: origin.external_id + '_broken')
    origin.microsoft_order_id.nil? ? origin.update(microsoft_order_id: '_broken') : origin.update(microsoft_order_id: origin.microsoft_order_id + '_broken')
    application.update(service_status: :deleted)
    subscription.update(status: :deleted)
    subscription.charges.where(status: [:blocked, :new]).update(status: :deleted) if subscription.charges.exists?
    Note.create!(
      content: "Subscription was deleted only in AP | #{ticket_id}",
      noteable_id: subscription.id,
      noteable_type: "Subscription",
      manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
      account_id: subscription.account.id);
    puts " ---------------------------------------------"
    puts " #{subscription.id} | #{subscription.name} | #{subscription.status.upcase} | APP #{subscription.applications.exists?}"
    puts " ---------------------------------------------"
  end
end
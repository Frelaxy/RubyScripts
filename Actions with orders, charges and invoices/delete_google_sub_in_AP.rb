def delete_google_sub_in_AP(sub_id, ticket_id = '')
  ActiveRecord::Base.transaction do
    subscirption = Subscription.find(sub_id)
    application = subscirption.applications.last
    origin = application.origin
    origin.external_id.nil? ? origin.update(external_id: '_broken') : origin.update(external_id: origin.external_id + '_broken')
    origin.update(service_status: :deleted)
    application.update(service_status: :deleted)
    subscirption.update(status: :deleted)
    subscirption.charges.in_blocked.update(status: :deleted) if subscirption.charges.exists?
    Note.create!(
      content: "Subscription was deleted only in AP | #{ticket_id}",
      noteable_id: subscirption.id,
      noteable_type: "Subscription",
      manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
      account_id: subscirption.account.id);
    puts " ---------------------------------------------"
    puts " #{subscirption.id} | #{subscirption.name} | #{subscirption.status.upcase} | APP #{subscirption.applications.exists?}";
    puts " ---------------------------------------------"
  end
end
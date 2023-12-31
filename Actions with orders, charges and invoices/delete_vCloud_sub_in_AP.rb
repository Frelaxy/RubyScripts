def delete_vCloud_sub_in_ap(sub_id, ticket_id = '')
  ActiveRecord::Base.transaction do
    sub = Subscription.find(sub_id);
    app = sub.applications.last;
    origin = sub.applications.last.origin;
        if origin.external_id == nil
            origin.update(external_id: '_broken');
        else
            origin.update(external_id: origin.external_id + '_broken');
        end
    origin.update(service_status: :deleted)
    app.update(service_status: :deleted);
    sub.update(status: :deleted);
    sub.charges.in_blocked.update(status: :deleted) if sub.charges.exists?
    Note.create!(
        content: "Subscription was deleted only in AP | #{ticket_id}",
        noteable_id: sub.id,
        noteable_type: "Subscription",
        manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
        account_id: sub.account.id);
    puts " ---------------------------------------------"
    puts " #{sub.id} | #{sub.name} | #{sub.status.upcase} | APP #{sub.applications.exists?}";
    puts " ---------------------------------------------"
  end
end
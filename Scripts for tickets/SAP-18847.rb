subs.map do |sub|
  puts "Обрабатывается подписка #{sub.id}"
  app = sub.applications.last;
  origin = sub.applications.last.origin;
    if origin.external_id == nil
      origin.update(external_id: '_broken');
      origin.update(microsoft_order_id: '_broken');
    else
      origin.update(external_id: origin.external_id + '_broken');
      origin.update(microsoft_order_id: origin.microsoft_order_id + '_broken');
    end
  app.to_deleted
  sub.update(status: :stopped)
  sub.to_deleting
  charge = sub.charges.where(status: :closed).last
  charge.update(status: :deleted)
  ResellerCharge.where(charge_id: charge.id).delete_all
  puts "Подписка #{sub.id} и списание #{charge.id} успешно удалены"
  Note.create!(
    content: 'Subscription was deleted only in AP | SAP-18847',
    noteable_id: sub.id,
    noteable_type: "Subscription",
    manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
    account_id: sub.account.id);
  puts " ---------------------------------------------"
  puts " #{sub.id} | #{sub.name} | #{sub.status.upcase} | APP #{sub.applications.exists?}";
  puts " ---------------------------------------------"
end
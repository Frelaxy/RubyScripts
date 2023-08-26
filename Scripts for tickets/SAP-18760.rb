subs_ids = Reseller.where(id: [460, 536, 419, 349, 530, 1144]).map {|res| res.subscriptions.where(status: :stopping_failed).ids}.flatten
subs_statuses = []
subs_ids.map do |sub_id|
  subscription = Subscription.find(sub_id)
  status_from_ms = get_subscriptions_info_from_ms(sub_id).last[:status]
  subs_statuses << [subscription.reseller.id, subscription.id, subscription.status, status_from_ms]
end
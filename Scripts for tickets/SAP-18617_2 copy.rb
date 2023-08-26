@subs_id_where_not_actual_price = []
counter = 0
notes = Note.where(noteable_type: "Order").where(manager_id: [4810, 2325, 5164, 4744, 4566, 1862, 4384, 4336]).select { |note| note.content.include? 'completed manually' }
orders_ids = notes.pluck(:noteable_id)
orders = Order.where(id: orders_ids).where(type: "RenewalOrder")
subs_ids = orders.map { |order| order.subscription_id }
subs_ids.uniq!
subs_ids.map do |sub_id|
  counter = counter + 1
  puts "Обрабатывается #{counter} подписка из #{subs_ids.count} id:#{sub_id}"
  sub = Subscription.find(sub_id)
  order = sub.orders.where(type: "RenewalOrder", status: :completed).last
  if !order.nil?
    uniq_resource_charges = order.charges.uniq { |c| c.subscription_resource_id }
    uniq_resource_charges.map do |c|
      new_price = c.price
      subscription_resource = c.subscription_resource
      if !subscription_resource.nil? && subscription_resource.price.recurring_fee != new_price.recurring_fee
        @subs_id_where_not_actual_price << c.subscription.id
        @subs_id_where_not_actual_price.uniq!
      end
    end
  end
end

subs_ids_for_fix = Subscription.where(id: @subs_id_where_not_actual_price).where("updated_at > ?", Date.new(2021,1,4)).where.not(status: [:deleted, :deleting, :deletion_failed, :installation_failed, :installing]).ids

subs_ids_for_fix.map do |sub_id|
  sub = Subscription.find(sub_id)
  order = sub.orders.where(type: "RenewalOrder", status: :completed).last
  uniq_resource_charges = order.charges.uniq { |c| c.subscription_resource_id }
  charge = uniq_resource_charges.last
  price_from_rn_order = charge.price.recurring_fee
  actual_subscription_resource_pirce = charge.subscription_resource.price.recurring_fee
  puts "Подписка #{sub_id} реселлер #{sub.reseller.id}.Текущая цена ресурса #{actual_subscription_resource_pirce} должна быть #{price_from_rn_order}. #{sub.plan.billing_type}"
end

def actualize_price_by_order(order_id)
  order = Order.find order_id
  uniq_resource_charges = order.charges.uniq { |c| c.subscription_resource_id } # Что за скобка и для чего уникальные чарджи?
  uniq_resource_charges.map do |c|
    new_price = c.price
    c.subscription_resource.update(price: new_price)
  end
end

subs_ids_for_fix.map do |sub_id|
  sub = Subscription.find(sub_id)
  order_id = sub.orders.where(type: "RenewalOrder", status: :completed).last.id
  actualize_price_by_order(order_id)
end
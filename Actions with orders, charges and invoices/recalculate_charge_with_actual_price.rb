def recalculate_charge_with_actual_price(charge_id)
  charge = Charge::Base.find(charge_id)
  new_price = charge.subscription_resource.price
  charge.price = new_price
  charge.recalculate_amount!
  charge.save
  order = charge.order
  OrderDetailsGenerator.new(order).generate!
  order.recalculate_total!
  order.recalculate_net_cost!
end
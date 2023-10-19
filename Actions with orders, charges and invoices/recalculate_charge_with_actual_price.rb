def recalculate_charge_with_actual_price(charge_id)
  charge = Charge::Base.find(charge_id)
  ActiveRecord::Base.transaction do
    new_price = charge.subscription_resource.price
    charge.price = new_price
    charge.recalculate_amount!
    charge.save
    if charge.status == 'closed'
      ResellerCharge.where(charge_id: charge.id).delete_all
      ResellerChargesBuilder.new(charge).call
    end
    order = charge.order
    OrderDetailsGenerator.new(order).generate!
    order.recalculate_total!
    order.recalculate_net_cost!
  end
end
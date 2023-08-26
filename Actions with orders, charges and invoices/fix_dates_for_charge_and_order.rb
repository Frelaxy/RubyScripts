# Метод для исправления заказа и всех его сущностей на другие даты:
# Обратить внимание на даты закрытия списания при csp annual. Они закрываются датой закрытия, а не через год!
def fix_order_dates(charge_id, date_from, date_to)
  charge = Charge::Base.find(charge_id)
  ActiveRecord::Base.transaction do
    charge.operate_from = date_from
    charge.operate_to = date_to
    if charge.subscription.billing_type == "csp_annual"
      p "You have to ckeck a close date for this charge. It's #{charge.close_date} now"
    elsif
      charge.close_date = date_to
    end
    charge.duration = ::Calculators::DurationBetweenDates.new(charge, from: charge.operate_from, to: charge.operate_to, billing_day: charge.plan.billing_day).call
    charge.recalculate_amount!
    charge.save
    order = charge.order
    OrderDetailsGenerator.new(order).generate!
    order.recalculate_total!
    order.recalculate_net_cost!
    if !order.payment.nil? && order.payment.status != 'completed'
      order.payment.update(total: order.total)
    end
  end
end
# __________________________________________________________________________________________
charge_id = 1000609
date_from = Date.new(2023,7,23)
date_to = Date.new(2024,5,28)
fix_order_dates(charge_id, date_from, date_to)



charges_ids = [990911, 990910, 990909, 990908]
charges_ids.each {|charge_id| fix_order_dates(charge_id, date_from, date_to)}
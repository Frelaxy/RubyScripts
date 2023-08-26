def fix_charges_from_invoice(invoice_id)
  invoice = Invoice::Base.find(invoice_id)
  charges = invoice.charges.select {|charge| charge.subscription.plan_class.key == 'csp_p1m_monthly_nce' && charge.duration > 0.1e1}
  charges.map do |charge|
    ActiveRecord::Base.transaction do
      ResellerCharge.where(charge_id: charge.id).delete_all
      charge.operate_from = charge.operate_to - 1.month
      charge.duration = ::Calculators::DurationBetweenDates.new(charge, from: charge.operate_from, to: charge.operate_to).call
      charge.recalculate_amount!
      charge.save
      ResellerChargesBuilder.new(charge).call
      order = charge.order
      OrderDetailsGenerator.new(order).generate!
      order.recalculate_total!
      order.recalculate_net_cost!
      #invoice.recalculate_total!
      #invoice.save
      #invoice.payments.last.update(total: invoice.total)
    end
  end
end
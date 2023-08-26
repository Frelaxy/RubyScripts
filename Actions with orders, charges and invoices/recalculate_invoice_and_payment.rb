def recalculate_invoice_and_payment(invoice_id)
  invoice = Invoice::Base.find(invoice_id)
  invoice.recalculate_total!
  invoice.save!
  new_total = invoice.total
  if invoice.payments.last.status == "waiting_for_payment"
    invoice.payments.last.update(total: new_total)
  else
    p "Статус платежа отличен от 'waiting_for_payment' требуется посмотреть"
  end
end
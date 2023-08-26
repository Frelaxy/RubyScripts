def calculate_amout_from_charges(invoice_id)
  invoice = Invoice::Base.find(invoice_id)
  amount_from_charges = 0.0e1
  invoice.charges.map do |charge|
    amount_from_charges = amount_from_charges + charge.amount
  end
  return amount_from_charges
end
invoices_october = Invoice::Base.where("from_date > ? and from_date < ?", Date.new(2022,8,30), Date.new(2022,12,1))
invoices_for_fix_with_payment_not_completed = invoices_october.select do |invoice|
  invoice.total != calculate_amout_from_charges(invoice.id) && !invoice.payments.empty? && invoice.payments.last.status != "completed"
end
invoices_for_fix_with_payment_not_completed.map do |invoice|
  new_total = calculate_amout_from_charges(invoice.id)
  invoice.update(total: new_total)
  invoice.payments.last.update(total: new_total)
end